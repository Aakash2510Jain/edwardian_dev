/**
* @author Jadd Ennaciri <jadd.ennaciri@cloudshiftgroup.com>
* @date 2021-07-05
* @group CloudShiftGroup
* @description - Controller for vipGiftAllocation Lightning Web Component performing DML operations
*
* Date          author             Change Description
* -----------------------------------------------------------------------------------
* 05/07/2021    Jadd Ennaciri      Created Class
*
*/

public with sharing class VipGiftAllocationController {

    /**
    * To query and return an Order (Booking) based on recordId
    *
    * @param (Id) recordId - record Id of the current Order
    *
    * @return (Order) booking - Order record containing booking details
    */
    @AuraEnabled(cacheable=true)
    public static Order getBookingDetails(Id recordId) {
        Order booking = [
            SELECT Id, Room_Number__c, Arrival_Date__c, Guest_First_Name__c, Guest_Last_Name__c, Hotel__c, Hotel__r.Hotel_ID__c, AccountId, Reservation_Stage__c, Reservation_Status__c, Departure_Date__c
            FROM Order
            WHERE Id = :recordId
        ];
        return booking;
    }

    /**
    * To query for gifts related to the hotel Id and return a map containing lists of gifts by their respective grade
    *
    * @param (String) hotelId - Hotel Id of the current Order
    *
    * @return (Map<String, List<Gift__c>>) giftsByGrade - Map containing lists of gifts by their respective grade
    */
    @AuraEnabled(cacheable=true)
    public static Map<String, List<Gift__c>> getGiftsByGrade(String hotelId) {
        Map<String, List<Gift__c>> giftsByGrade = new Map<String, List<Gift__c>>();
        List<Gift__c> gifts = [
            SELECT Id, Name, Category__c, Price__c
            FROM Gift__c
            WHERE Hotels__c INCLUDES(:hotelId)
            ORDER BY Category__c ASC
        ];
        if(!gifts.isEmpty()) {
            for(Gift__c gift: gifts) {
                if(giftsByGrade.containsKey(gift.Category__c)) {
                    giftsByGrade.get(gift.Category__c).add(gift);
                } else {
                    giftsByGrade.put(gift.Category__c, new List<Gift__c>{gift});
                }
            }
        }
        return giftsByGrade;
    }

    /**
    * To query and return Gift Allocation records related to the booking
    *
    * @param (Id) recordId - record Id of the current Order
    *
    * @return (List<Gift_Allocation__c>) existingGiftAllocations - List of existing Gift Allocation records
    */
    @AuraEnabled
    public static List<Gift_Allocation__c> getExistingGiftAllocations(Id recordId) {
        List<Gift_Allocation__c> existingGiftAllocations = [
            SELECT Id, Name, Gift_Delivery_Status__c, Delivery_Date__c, Items_Count__c, Total_Price__c, (
                SELECT Id, Gift_Name__c, Gift_Name__r.Name, Gift_Name__r.Price__c, Quantity__c, Status__c
                FROM Gift_Allocation_Line_Items__r
            )
            FROM Gift_Allocation__c
            WHERE Booking__c = :recordId
            ORDER BY Name ASC
        ];
        return existingGiftAllocations;
    }

    /**
    * To query and return Always Allocate Gift Items related to the guest
    *
    * @param (Id) guestId - guest Id of the current Order
    *
    * @return (List<Always_Allocate_Gift_Item__c>) existingAlwaysAllocateGifts - List of existing Always Allocate Gift Item records
    */
    @AuraEnabled
    public static List<Always_Allocate_Gift_Item__c> getExistingAlwaysAllocateGifts(Id guestId) {
        List<Always_Allocate_Gift_Item__c> existingAlwaysAllocateGifts = [
            SELECT Id, Gift_Name__c, Gift_Name__r.Name, Gift_Name__r.Price__c, Quantity__c
            FROM Always_Allocate_Gift_Item__c
            WHERE Guest_Name__c = :guestId
        ];
        return existingAlwaysAllocateGifts;
    }

    /**
    * To upsert or delete Gift Allocation, Gift Allocation Line Items, and Always Allocate Gift Items from the data passed by the component, returning a Boolean value if the budget has been exceeded
    *
    * @param (String) giftAllocationJson - JSON string containing Gift Allocation details
    * @param (List<Id>) alwaysAllocatedGiftsToDelete - List of Always Allocate Gift Item Ids to be deleted
    * @param (List<Id>) selectedGiftsToDelete - List of Gift Allocation Line Item Ids to be deleted
    *
    * @return (Boolean) budgetExceeded - Boolean stating if the budget has been exceeded
    */
    @AuraEnabled
    public static Boolean saveGiftAllocation(String giftAllocationJson, List<Id> alwaysAllocatedGiftsToDelete, List<Id> selectedGiftsToDelete) {
        Boolean budgetExceeded = false;
        GiftAllocationWrapper giftAllocationWrapper = (GiftAllocationWrapper) JSON.deserialize(giftAllocationJson, GiftAllocationWrapper.class);
        Order booking = getBookingDetails(giftAllocationWrapper.recordId);
        Budget__c budget = getBudget(giftAllocationWrapper.deliveryDate, booking);
        budgetExceeded = checkBudget(giftAllocationWrapper.totalPrice, budget);
        // Check gift allocation wrapper details before saving the record
        Gift_Allocation__c giftAllocation = createGiftAllocation(booking, budget, giftAllocationWrapper);
        List<Gift_Allocation_Line_Item__c> giftAllocationLineItems = createGiftAllocationLineItems(giftAllocation, giftAllocationWrapper.selectedGifts);
        List<Always_Allocate_Gift_Item__c> alwaysAllocateGiftItems = createAlwaysAllocateGiftItems(booking.AccountId, giftAllocationWrapper.selectedAlwaysAllocatedGifts);
        if(!alwaysAllocatedGiftsToDelete.isEmpty()) {
            deleteAlwaysAllocateGiftItems(alwaysAllocatedGiftsToDelete);
        }
        if(!selectedGiftsToDelete.isEmpty()) {
            deleteGiftLineItems(selectedGiftsToDelete);
        }
        return budgetExceeded;
    }

    /**
    * To query and return a budget record relevant to the Gift Allocation
    *
    * @param (Date) deliveryDate - Date for when items should be delivered
    * @param (Order) booking - Order record containing booking details
    *
    * @return (Budget__c) budget - Budget record relevant to the Gift Allocation
    */
    private static Budget__c getBudget(Date deliveryDate, Order booking) {
        Budget__c budget = [
            SELECT Id, Balance__c
            FROM Budget__c
            WHERE Hotel__c = :booking.Hotel__c AND Financial_Period_End_Date__c >= :deliveryDate AND Financial_Period_Start_Date__c <= :deliveryDate
            LIMIT 1
        ];
        return budget;
    }

    /**
    * To query and return a Boolean value stating if the budget has been exceeded
    *
    * @param (Decimal) totalPrice - Total price of all Gift Allocation Line Items
    * @param (Budget__c) budget - Budget record relevant to the Gift Allocation
    *
    * @return (Boolean) - Boolean stating if the budget has been exceeded
    */
    private static Boolean checkBudget(Decimal totalPrice, Budget__c budget) {
        if((budget.Balance__c - totalPrice) < 0) {
            return true;
        } else {
            return false;
        }
    }

    /**
    * To create and upsert a Gift Allocation record
    *
    * @param (Order) booking - Order record containing booking details
    * @param (Budget__c) budget - Budget record related to the Gift Allocation to be upserted
    * @param (GiftAllocationWrapper) giftAllocationWrapper - Wrapped object containing Gift Allocation data
    *
    * @return (Gift_Allocation__c) giftAllocation - Upserted Gift Allocation record
    */
    private static Gift_Allocation__c createGiftAllocation(Order booking, Budget__c budget, GiftAllocationWrapper giftAllocationWrapper) {
        Gift_Allocation__c giftAllocation = new Gift_Allocation__c(
            Id = giftAllocationWrapper.selectedGiftAllocationId,
            Booking__c = booking.Id,
            Total_Price__c = giftAllocationWrapper.totalPrice,
            Budget__c = budget.Id,
            Delivery_Date__c = giftAllocationWrapper.deliveryDate,
            Guest_Name__c = booking.AccountId,
            Reservation_Stage__c = booking.Reservation_Stage__c
        );
        upsert giftAllocation;
        return giftAllocation;
    }

    /**
    * To create and upsert a List of Gift Allocation Line Items
    *
    * @param (Gift_Allocation__c) giftAllocation - Parent Gift Allocation record
    * @param (List<SelectedGiftWrapper>) selectedGifts - List of wrapped selected gifts to be upserted
    *
    * @return (List<Gift_Allocation_Line_Item__c>) giftAllocationLineItems - List of upserted Gift Allocation Line Items
    */
    private static List<Gift_Allocation_Line_Item__c> createGiftAllocationLineItems(Gift_Allocation__c giftAllocation, List<SelectedGiftWrapper> selectedGifts) {
        List<Gift_Allocation_Line_Item__c> giftAllocationLineItems = new List<Gift_Allocation_Line_Item__c>();
        for(SelectedGiftWrapper selectedGift: selectedGifts) {
            giftAllocationLineItems.add(new Gift_Allocation_Line_Item__c(
                Id = selectedGift.value.existingId,
                Gift_Allocation__c = giftAllocation.Id,
                Gift_Name__c = selectedGift.value.gift.Id,
                Quantity__c = selectedGift.value.quantity,
                Status__c = selectedGift.value.status
            ));
        }
        upsert giftAllocationLineItems;
        return giftAllocationLineItems;
    }

    /**
    * To create and upsert a List of Always Allocate Gift Items
    *
    * @param (Id) guestId - guest Id of the current Order
    * @param (List<SelectedGiftWrapper>) selectedAlwaysAllocatedGifts - List of wrapped always allocated gifts to be upserted
    *
    * @return (List<Always_Allocate_Gift_Item__c>) alwaysAllocateGiftItems - List of upserted Always Allocate Gift Items
    */
    private static List<Always_Allocate_Gift_Item__c> createAlwaysAllocateGiftItems(Id guestId, List<SelectedGiftWrapper> selectedAlwaysAllocatedGifts) {
        List<Always_Allocate_Gift_Item__c> alwaysAllocateGiftItems = new List<Always_Allocate_Gift_Item__c>();
        for(SelectedGiftWrapper selectedGift: selectedAlwaysAllocatedGifts) {
            alwaysAllocateGiftItems.add(new Always_Allocate_Gift_Item__c(
                Id = selectedGift.value.existingId,
                Guest_Name__c = guestId,
                Gift_Name__c = selectedGift.value.gift.Id,
                Quantity__c = selectedGift.value.quantity
            ));
        }
        upsert alwaysAllocateGiftItems;
        return alwaysAllocateGiftItems;
    }

    /**
    * To delete a list of Always Allocated Gift Items
    *
    * @param (List<Id>) alwaysAllocatedGiftsToDelete - List of Always Allocate Gift Item Ids to be deleted
    */
    private static void deleteAlwaysAllocateGiftItems(List<Id> alwaysAllocatedGiftsToDelete) {
        List<Always_Allocate_Gift_Item__c> alwaysAllocateGiftItemsToDelete = new List<Always_Allocate_Gift_Item__c>();
        for(Id alwaysAllocateGiftId: alwaysAllocatedGiftsToDelete) {
            alwaysAllocateGiftItemsToDelete.add(new Always_Allocate_Gift_Item__c(Id = alwaysAllocateGiftId));
        }
        delete alwaysAllocateGiftItemsToDelete;
    }

    /**
    * To delete a list of Gift Allocation Line Items
    *
    * @param (List<Id>) selectedGiftsToDelete - List of Gift Allocation Line Item Ids to be deleted
    */
    private static void deleteGiftLineItems(List<Id> selectedGiftsToDelete) {
        List<Gift_Allocation_Line_Item__c> giftLineItemsToDelete = new List<Gift_Allocation_Line_Item__c>();
        for(Id lineItemId: selectedGiftsToDelete) {
            giftLineItemsToDelete.add(new Gift_Allocation_Line_Item__c(Id = lineItemId));
        }
        delete giftLineItemsToDelete;
    }

    /**
    * To delete a list of Gift Allocation Records
    *
    * @param (List<Id>) selectedGiftAllocationsToDelete - List of Gift Allocation Ids to be deleted
    */
    @AuraEnabled
    public static void deleteGiftAllocations(List<Id> selectedGiftAllocationsToDelete) {
        List<Gift_Allocation__c> giftAllocationsToDelete = new List<Gift_Allocation__c>();
        for(Id giftAllocationId: selectedGiftAllocationsToDelete) {
            giftAllocationsToDelete.add(new Gift_Allocation__c(Id = giftAllocationId));
        }
        delete giftAllocationsToDelete;
    }

    public class SelectedGiftWrapper {
        @AuraEnabled public GiftLineItem value;
    }

    public class GiftLineItem {
        @AuraEnabled public Gift__c gift;
        @AuraEnabled public Boolean alwaysAllocate;
        @AuraEnabled public Integer quantity;
        @AuraEnabled public String status;
        @AuraEnabled public String existingId;
    }

    public class GiftAllocationWrapper {
        @AuraEnabled public Decimal totalPrice;
        @AuraEnabled public Date deliveryDate;
        @AuraEnabled public Id recordId;
        @AuraEnabled public Id selectedGiftAllocationId;
        @AuraEnabled public List<SelectedGiftWrapper> selectedGifts;
        @AuraEnabled public List<SelectedGiftWrapper> selectedAlwaysAllocatedGifts;
    }
}