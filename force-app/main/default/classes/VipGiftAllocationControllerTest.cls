/**
* @author Jadd Ennaciri <jadd.ennaciri@cloudshiftgroup.com>
* @date 2021-07-14
* @group CloudShiftGroup
*
* Date          author             Change Description
* -----------------------------------------------------------------------------------
* 14/07/2021    Jadd Ennaciri      Created Class
*
*/

@IsTest
public with sharing class VipGiftAllocationControllerTest {

    private static final Id ORDER_ROOMS_RT_ID = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Rooms').getRecordTypeId();

    @TestSetup
    private static void setup() {
        List<Account> accounts = TestDataFactory.generatePersonAccounts(1, true);
        List<Property__c> properties = TestDataFactory.createProperties(1, true);
        Order order = TestDataFactory.generateOrder(accounts[0].Id, ORDER_ROOMS_RT_ID, false);
        order.Hotel__c = properties[0].Id;
        insert order;
        List<Gift__c> gifts = TestDataFactory.createGifts(4, true, properties[0]);
        Financial_Period__c financialPeriod = TestDataFactory.createFinancialPeriod(true);
        Budget__c budget = TestDataFactory.createBudget(properties[0], financialPeriod, true);
        Gift_Allocation__c giftAllocation = TestDataFactory.createGiftAllocation(order, budget, true);
        TestDataFactory.createGiftAllocationLineItems(giftAllocation, gifts, true);
        TestDataFactory.createAlwaysAllocateGiftItems(gifts, true, accounts[0]);
    }

    /**
    * Method tested: getBookingDetails()
    * Expected result: To successfully retrieve Booking details by passing a record Id
    */
    private static testMethod void testGetBookingDetails() {
        Order currentOrder = [
            SELECT Id
            FROM Order
            LIMIT 1
        ];
        Test.startTest();
        Order retrievedBooking = VipGiftAllocationController.getBookingDetails(currentOrder.Id);
        Test.stopTest();
        System.assertNotEquals(null, retrievedBooking, 'Booking does not exist');
    }

    /**
    * Method tested: getGiftsByGrade()
    * Expected result: To successfully retrieve a map of gifts by their respective grade
    */
    private static testMethod void testGetGiftsByGrade() {
        Property__c property = [
            SELECT Id, Hotel_ID__c
            FROM Property__c
            LIMIT 1
        ];
        Test.startTest();
        Map<String, List<Gift__c>> giftsByGrade = VipGiftAllocationController.getGiftsByGrade(property.Hotel_ID__c);
        Test.stopTest();
        System.assertNotEquals(null, giftsByGrade, 'No gifts retrieved');
    }

    /**
    * Method tested: getExistingGiftAllocations()
    * Expected result: To successfully return a List of exsiting Gift Allocation records and child line items
    */
    private static testMethod void testGetExistingGiftAllocations() {
        Order currentOrder = [
            SELECT Id
            FROM Order
            LIMIT 1
        ];
        Test.startTest();
        List<Gift_Allocation__c> existingGiftAllocations = VipGiftAllocationController.getExistingGiftAllocations(currentOrder.Id);
        Test.stopTest();
        System.assertEquals(1, existingGiftAllocations.size(), 'Incorrect number of Gift Allocations exist');
        System.assertEquals(4, existingGiftAllocations[0].Gift_Allocation_Line_Items__r.size(), 'Incorrect number of Gift Allocations Line Items exist');
    }

    /**
    * Method tested: getExistingAlwaysAllocateGifts()
    * Expected result: To successfully return existing Always Allocated Gift Items
    */
    private static testMethod void testGetExistingAlwaysAllocateGifts() {
        Order currentOrder = [
            SELECT Id, AccountId
            FROM Order
            LIMIT 1
        ];
        Test.startTest();
        List<Always_Allocate_Gift_Item__c> existingAlwaysAllocateGifts = VipGiftAllocationController.getExistingAlwaysAllocateGifts(currentOrder.AccountId);
        Test.stopTest();
        System.assertEquals(4, existingAlwaysAllocateGifts.size(), 'Incorrect number of Always Allocated Gift Items exist');
    }

    /**
    * Method tested: saveGiftAllocation()
    * Expected result: Successly create a new Gift Allocation with Gift Allocation Line Items and Always Allocate Gift Items, and delete selected Gift Allocation Line Items and Always Allocate Gift Items
    */
    private static testMethod void testSaveGiftAllocation() {
        Order currentOrder = [
            SELECT Id
            FROM Order
            LIMIT 1
        ];
        Gift__c selectedGift = [
            SELECT Id
            FROM Gift__c
            LIMIT 1
        ];
        String giftAllocationJson = '{"recordId":"'+currentOrder.Id+'","totalPrice":"10.00","deliveryDate":"2021-01-02","selectedGifts":[{"value":{"gift":{"Id":"'+selectedGift.Id+'"},"quantity":"1","status":"Pending"}}],"selectedAlwaysAllocatedGifts":[{"value":{"gift":{"Id":"'+selectedGift.Id+'"},"quantity":"1"}}]}';

        List<Id> selectedGiftsToDelete = new List<Id>();
        List<Gift_Allocation_Line_Item__c> giftAllocationLineItems = [
            SELECT Id
            FROM Gift_Allocation_Line_Item__c
        ];
        for(Gift_Allocation_Line_Item__c lineItem: giftAllocationLineItems) {
            selectedGiftsToDelete.add(lineItem.Id);
        }

        List<Id> alwaysAllocatedGiftsToDelete = new List<Id>();
        List<Always_Allocate_Gift_Item__c> alwaysAllocateGiftItems = [
            SELECT Id
            FROM Always_Allocate_Gift_Item__c
        ];
        for(Always_Allocate_Gift_Item__c lineItem: alwaysAllocateGiftItems) {
            alwaysAllocatedGiftsToDelete.add(lineItem.Id);
        }

        Test.startTest();
        Boolean budgetExceeded = VipGiftAllocationController.saveGiftAllocation(giftAllocationJson, alwaysAllocatedGiftsToDelete, selectedGiftsToDelete);
        Test.stopTest();
        List<Gift_Allocation__c> existingGiftAllocations = [
            SELECT Id
            FROM Gift_Allocation__c
        ];
        List<Gift_Allocation_Line_Item__c> remainingGiftAllocationLineItems = [
            SELECT Id
            FROM Gift_Allocation_Line_Item__c
        ];
        List<Always_Allocate_Gift_Item__c> remainingAlwaysAllocateGiftItems = [
            SELECT Id
            FROM Always_Allocate_Gift_Item__c
        ];
        System.assertEquals(false, budgetExceeded, 'Budget has been exceeded');
        System.assertEquals(2, existingGiftAllocations.size(), 'Failed to create Gift Allocation');
        System.assertEquals(1, remainingGiftAllocationLineItems.size(), 'Failed to create and delete Gift Allocation Line Items');
        System.assertEquals(1, remainingAlwaysAllocateGiftItems.size(), 'Failed to create and delete Always Allocate Gift Items');
    }

    /**
    * Method tested: deleteGiftAllocations()
    * Expected result: Successfully delete a Gift Allocation record
    */
    private static testMethod void testDeleteGiftAllocation() {
        List<Gift_Allocation__c> existingGiftAllocations = [
            SELECT Id
            FROM Gift_Allocation__c
        ];

        Gift_Allocation__c giftAllocationBeforeDelete = [
            SELECT Id
            FROM Gift_Allocation__c
            WHERE Id = :existingGiftAllocations[0].Id
        ];
        List<Id> recordIdsToDeleteBefore = new List<Id>{giftAllocationBeforeDelete.Id};

        Test.startTest();
        VipGiftAllocationController.deleteGiftAllocations(recordIdsToDeleteBefore);
        Test.stopTest();

        List<Gift_Allocation__c> giftAllocationsAfterDelete = [
            SELECT Id
            FROM Gift_Allocation__c
        ];
        System.assertEquals(false, giftAllocationsAfterDelete.contains(giftAllocationBeforeDelete), 'Gift Allocation Record not deleted');
    }
}