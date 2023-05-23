/**
 * @Name:        BookingGiftAllocationBatchHelper
 * @Description: Apex Class used to store the logic for the BookingGiftAllocationBatch Class
 *
 * @author:      Andrei Budescu
 * @version:     1.0
 * Change Log
 *
 * Date         author              Change Description
 * -----------------------------------------------------------------------------------
 * 13/07/2021   Andrei Budescu      Created Class
 */
public without sharing class BookingGiftAllocationBatchHelper {

    
    /**
     * Function to populate ordersQueriedMap with Order records
     *
     * @param Date todaysDate       - Date to calculate the today's orders. Needs to match the Arrival Date
     *
     * @return Map of Orders Queried for Today's Date
    */
    public Map<Id, Order> getOrdersToday(Date todaysDate) {

        // Query Booking records (Reservation Stage != Cancelled - Don't create gift allocations when cancelled)
        return  new Map<Id, Order>
                    ([
                        SELECT 
                            Id, 
                            OrderNumber, 
                            Hotel__c, 
                            AccountId, 
                            Account.Number_of_Always_Allocated_Gifts__c, 
                            Account.VIP_Code__c,
                            Account.Name, 
                            Arrival_Date__c, 
                            Reservation_Status__c, 
                            CurrencyIsoCode
                        FROM Order 
                        WHERE 
                            Arrival_Date__c = :todaysDate 
                            AND Account.Number_of_Always_Allocated_Gifts__c > 0 
                            AND Reservation_Status__c != 'CXL'
                            AND Hotel__c != null 
                            AND AccountId != null
                    ]);
    }


    /**
     * Function to populate budgetsList with Budget records
     *
     * @param Date todaysDate       - Date to calculate the available budget. Date needs to be between the Financial Period Dates
     * @param Set<Id> hotelIds      - Set of Hotel Ids linked to the Today's Orders
     * 
     * @return Map of Budget records Queried for Today's Date
    */
    public Map<Id, Budget__c> getBudgetsTodaysOrders(Date todaysDate, Set<Id> hotelIds) {

        // Query Budgets based on the Hotel Ids and Arrival Date of the Booking record
        return  new Map<Id, Budget__c>
                    ([
                        SELECT 
                            Id, 
                            Hotel__c, 
                            Hotel__r.VIP_Email_Address__c, 
                            Hotel__r.Name, 
                            Financial_Period_Start_Date__c, 
                            Financial_Period_End_Date__c, 
                            Balance__c, 
                            Total_Gifts_Cost__c
                        FROM 
                            Budget__c
                        WHERE
                            Hotel__c IN :hotelIds 
                            AND Financial_Period_Start_Date__c <= :todaysDate 
                            AND Financial_Period_End_Date__c >= :todaysDate
                    ]);
    }


    /**
     * Function to get the Guests linked to the Today's Orders
     *
     * @param Set<Id> guestIds       - Set of Ids of the Today's Guests
     *
     * @return Map of Account Id and Account record
    */
    public Map<Id, Account> getTodaysGuests(Set<Id> guestIds) {

        // Query Map of GuestId and Guest(contains the related list of Always Allocated Items)
        return new Map<Id, Account> 
                        ([
                            SELECT
                                Id, 
                                Name,
                                VIP_Code__c,
                                (
                                    SELECT 
                                        Id, 
                                        Gift_Name__r.Name,
                                        Quantity__c, 
                                        Price__c, 
                                        CurrencyIsoCode
                                    FROM Always_Allocated_Gift_Items__r
                                )
                            FROM
                                Account
                            WHERE 
                                Id IN :guestIds
                        ]);
    }


    /**
     * Function to get the Gift Allocation linked to the Today's Orders
     *
     * @param Set<Id> orderIds       - Set of Ids of the Today's Orders
     *
     * @return List of Gift Allocation newly created
    */
    public List<Gift_Allocation__c> getGiftAllocationCreated(Set<Id> orderIds) {
        List<Gift_Allocation__c> giftAllocationQueried = 
                        [
                            SELECT 
                                Id,
                                Booking__c,
                                Booking__r.CurrencyIsoCode
                            FROM 
                                Gift_Allocation__c
                            WHERE 
                                Booking__c IN :orderIds
                        ];
        return giftAllocationQueried;

    }


}