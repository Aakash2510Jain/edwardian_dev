/**
 * @Name:        BookingGiftAllocationBatchTest
 * @Description: Batch Test Class used to test the functionality of the BookingGiftAllocationBatch Class
 *
 * @author:      Andrei Budescu
 * @version:     1.0
 * Change Log
 *
 * Date         author              Change Description
 * -----------------------------------------------------------------------------------
 * 13/07/2021   Andrei Budescu     Created Class
 */
@isTest
public class BookingGiftAllocationBatchTest {

    private static final Integer BULK_AMOUNT = 5;
    private static final Id ORDER_ROOMS_RT_ID = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Rooms').getRecordTypeId();

    /**
     * @method setup
     *
     * @result will insert data needed for tests
     *
    */
    @testSetup static void setup() {

        // Create Guest records
        List<Account> accounts = TestDataFactory.generatePersonAccounts(
            BULK_AMOUNT,
            false
        );
        insert accounts;

        // Create Property Record
        Property__c hotel = new Property__c(
            Name = 'The May Fair',
            Is_Active__c = true,
            VIP_Email_Address__c = 'test.hotel@gmail.com',
            Email_Address__c = 'test.hotel@gmail.com'
        );
        insert hotel;

        // Get Todays Day, Month and Year
        DateTime todaysDate = System.now();
        Integer todaysDay = todaysDate.Day();
        String todaysMonth = todaysDate.format('MMMM');
        Integer todaysYear = todaysDate.Year();

        // Create Financial Period recod for this month
        Financial_Period__c financialP = new Financial_Period__c(
            Financial_Period_Start_Date__c = System.Today().addDays(-1),
            Financial_Period_End_Date__c = System.Today().addDays(30),
            Month__c = todaysMonth,
            Year__c = String.valueOf(todaysYear)
        );
        insert financialP;

        // Create Budget Record for this month
        Budget__c budget = new Budget__c(
            Name = hotel.Name + ' - ' + todaysMonth + ' - ' + String.valueOf(todaysYear),
            Year__c = String.valueOf(todaysYear),
            Month__c = todaysMonth,
            Financial_Period__c = financialP.Id,
            Budget__c = 1500,
            CurrencyIsoCode = 'GBP',
            Hotel__c = hotel.Id
        );
        insert budget;

        // Create Gift Records
        List<Gift__c> giftsList = new List<Gift__c>();
        for (Integer i=0; i<5; i++) {
            Gift__c gift = new Gift__c(
                Name = 'Test 750ml Moet & Chandon ' + i,
                Category__c = 'Grade 1',
                Hotels__c = '011',
                CurrencyIsoCode = 'GBP',
                Price__c = 400
            );
            giftsList.add(gift);
        }
        insert giftsList;
        
        // Create Gift Always Allocated Items
        List<Always_Allocate_Gift_Item__c> alwaysAllocatedGiftsList = new List<Always_Allocate_Gift_Item__c>();
        for (Account acc : accounts) {
            Always_Allocate_Gift_Item__c giftItem =  new Always_Allocate_Gift_Item__c(
                Gift_Name__c = giftsList[0].Id,
                CurrencyIsoCode = 'GBP',
                Guest_Name__c = acc.Id,
                Quantity__c = 1
            );
            alwaysAllocatedGiftsList.add(giftItem);
        }
        insert alwaysAllocatedGiftsList;
    }


    /**
     * @method BookingGiftAllocationBatch.execute
     * @case   Create 1 new order for today for a Guest that has an always allocated gift
     *
     * @result 1 Gift Allocation record will be created and linked to the Order and 
     *         a Gift Allocation Line Item record will be created and linked to the Gift Allocation
     *
    */
    @isTest static void testBatchExecutionOneOrder() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Property__c hotel = [SELECT Id FROM Property__c LIMIT 1];
        // Create one order record
        Order order = TestDataFactory.generateOrder(
            acc.Id, 
            ORDER_ROOMS_RT_ID, 
            false
        );
        order.Hotel__c = hotel.Id;
        order.Arrival_Date__c = System.Today().addDays(1);
        order.Room_Number__c = 5;
        order.EffectiveDate = System.Today();
        insert order;
        
        Test.startTest();

        BookingGiftAllocationBatch ba = new BookingGiftAllocationBatch();
        Id jobid = Database.executeBatch(ba);

        Test.stopTest();

        Map<Id, Gift_Allocation__c> giftAllocationCreatedMap = new Map<Id, Gift_Allocation__c>([SELECT Id, Booking__c FROM Gift_Allocation__c WHERE Booking__c = :order.Id]);
        List<Gift_Allocation_Line_Item__c> giftAllocationLineItemsList = [SELECT Id, Gift_Allocation__c FROM Gift_Allocation_Line_Item__c WHERE Gift_Allocation__c IN :giftAllocationCreatedMap.keySet()];
        
        // Assert records created of Gift Allocation and Gift Allocation Line Items for the Today's Booking
        System.assertEquals(1, giftAllocationCreatedMap.size(), 'No Gift Allocation created and linked to the booking.');
        System.assertEquals(1, giftAllocationLineItemsList.size(), 'No Gift Allocation Line Item created linked to the gift allocation record.');
        System.assertEquals(order.Id, giftAllocationCreatedMap.values()[0].Booking__c, 'Gift Allocation not linked to the Order for today.');
        System.assertEquals(giftAllocationCreatedMap.values()[0].Id, giftAllocationLineItemsList[0].Gift_Allocation__c, 'Gift Allocation Line Item not linked to the Gift Allocation created.');

    }

    /**
     * @method BookingGiftAllocationBatch.execute
     * @case   Create 1 new order for today for each Guest that have an always allocated gift
     *         The budget of the hotel in this case will be exceeded
     *
     * @result 1 Gift Allocation record will be created and linked to the Order and 
     *         a Gift Allocation Line Item record will be created and linked to the Gift Allocation
     *         An email will be sent out with the budget exceeded
     *
    */
    @isTest static void testBatchExecutionBudgetExceeded() {
        List<Account> accList = [SELECT Id FROM Account];
        Property__c hotel = [SELECT Id FROM Property__c LIMIT 1];

        // Create order records
        List<Order> ordersList = new List<Order>();
        for (Account acc : accList) {
            Order order = TestDataFactory.generateOrder(
                acc.Id, 
                ORDER_ROOMS_RT_ID, 
                false
            );
            order.Hotel__c = hotel.Id;
            order.Arrival_Date__c = System.Today().addDays(1);
            order.Room_Number__c = 5;
            order.EffectiveDate = System.Today();
            ordersList.add(order);
        }
        insert ordersList;
        Set<Id> orderIds = new Set<Id>();
        for (Order order : ordersList) {
            orderIds.add(order.Id);
        }

        Test.startTest();

        BookingGiftAllocationBatch ba = new BookingGiftAllocationBatch();
        Id jobid = Database.executeBatch(ba);

        Test.stopTest();

        Map<Id, Gift_Allocation__c> giftAllocationCreatedMap = new Map<Id, Gift_Allocation__c>([SELECT Id, Booking__c FROM Gift_Allocation__c WHERE Booking__c IN :orderIds]);
        List<Gift_Allocation_Line_Item__c> giftAllocationLineItemsList = [SELECT Id, Gift_Allocation__c FROM Gift_Allocation_Line_Item__c WHERE Gift_Allocation__c IN :giftAllocationCreatedMap.keySet()];

        // Assert records created of Gift Allocation and Gift Allocation Line Items for the Today's Booking
        System.assertEquals(5, giftAllocationCreatedMap.size(), 'No Gift Allocation records created for all the Bookings Today');
        System.assertEquals(5, giftAllocationLineItemsList.size(), 'No Gift Allocation Line Items records created for all the Gift Allocation records created.');

        // Assert that budget of the May Fair hotel has been exceeded
        Budget__c budgetExceeded = [SELECT Id, Balance__c, Hotel__c FROM Budget__c WHERE Hotel__c = :hotel.Id];
        System.assertEquals(true, budgetExceeded.Balance__c < 0, 'Budget Not Exceeded - Balance is positive.');

    }

    /**
     * @method BookingGiftAllocationSchedule.execute
     * @case   Run the Batch Class at a specific time everyday
     *
     * @result Batch Class is fired from the Schedulable Context
     *
    */
    @isTest static void testSchedule() {

        Account acc = [SELECT Id FROM Account LIMIT 1];
        Property__c hotel = [SELECT Id FROM Property__c LIMIT 1];
        // Create one order record
        Order order = TestDataFactory.generateOrder(
            acc.Id, 
            ORDER_ROOMS_RT_ID, 
            false
        );
        order.Hotel__c = hotel.Id;
        order.Arrival_Date__c = System.Today().addDays(1);
        order.Room_Number__c = 5;
        order.EffectiveDate = System.Today();
        insert order;

        Test.startTest();

        //parse to cron expression
        String hour = String.valueOf(Datetime.now().hour());
        String min = String.valueOf(Datetime.now().minute()); 
        String ss = String.valueOf(Datetime.now().second());
        String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';

        BookingGiftAllocationSchedule sc = new BookingGiftAllocationSchedule();
        String jobId = System.schedule('BookingGiftAllocationBatch Schedulable Job Started At:', nextFireTime, sc);

        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(nextFireTime, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);

        Test.stopTest();
    }




}