/**
 * @author Vasile Fana <vasile.fana@cloudshiftgroup.com>
 * @date 2020-12-01
 * @group CloudShiftGroup
 * @description  This class is responsible for generating/regenerating the
 *               Influenced_Room_Booking__c records for each order and it's
 *               related influencing campaigns
 *
 * Date          author             Change Description
 * ------------------------------------------------------------------------------------------------------------------------------------------
 * 2020-12-01    Vasile Fana       Created Class
 * 2021-04-21    Andrei Budescu    Removed functions not used recalculateRevenueSharing, 
 *                                 groupInfluencedRoomBookingsPerRoomBooking, removeInfluencedRoomBookings, findInfluencedRoomBookingsToRemove
 *                                 Added method calculateGrossRevenueShare to calculate the Gross Revenue on child records on Update
 */
public without sharing class InfluencedRoomBookingServices {
    private static final String INFLUENCED_ROOM_BOOKING_INSERT_ERROR = System.Label.Influenced_Room_Booking_Insert_Error_Message;
    private static final String INFLUENCED_ROOM_BOOKING_UPDATE_ERROR = System.Label.Influenced_Room_Booking_Update_Error_Message;
   
    /**
     * Function to generate Influenced Room Booking records
     *
     * @param Map<Id,Set<Id>> orderIdToCampaignIdsMap - Map of Order IDs and Set Campaign IDs
     * @param Map<Id,Order>   newOrdersMap            - Map of Order IDs and Order records
     *
     * @return List<Influenced_Room_Booking__c> influencedRoomBookingsToCreate - List of IRB record inserted
     */
    public List<Influenced_Room_Booking__c> generateInfluencedRoomBookings(Map<Id, Set<Id>> orderIdToCampaignIdsMap, Map<Id, Order> newOrdersMap) {

        // List of Influenced Room Booking used to 
        List<Influenced_Room_Booking__c> influencedRoomBookingsToCreate = new List<Influenced_Room_Booking__c>();

        // Loop through the Map of Orders orderIdToCampaignIdsMap
        for (Id orderId : orderIdToCampaignIdsMap.keySet()) {

            // Use the Order ID to get the Order record from the Map newOrdersMap
            Order order = newOrdersMap.get(orderId);

            // Generate Influenced Room Booking for each ID linked to the Order
            influencedRoomBookingsToCreate.addAll(
                generateInfluencedRoomBookingForEachCampaign(
                    order, 
                    orderIdToCampaignIdsMap.get(orderId)
                )
            );
        }

        // 
        if (!influencedRoomBookingsToCreate.isEmpty()) {
            createInfluencedRoomBookings(influencedRoomBookingsToCreate);
        }

        return influencedRoomBookingsToCreate;
    }

    /**
     * Function to generate Influenced Room Booking records using the Order record and the Set of Campaign IDs linked
     *
     * @param Order order         - Order Parent record for the Influenced Room Booking Records to be created
     * @param Set<Id> campaignIDs - Set of Campaign IDs linked to the Order record
     *
     * @return List<Influenced_Room_Booking__c> influencedRoomBookingsToCreate - List of IRB records to be created
     */
    private List<Influenced_Room_Booking__c> generateInfluencedRoomBookingForEachCampaign(Order order, Set<Id> campaignIDs) {

        List<Influenced_Room_Booking__c> influencedRoomBookingsToCreate = new List<Influenced_Room_Booking__c>();

        // Check if set of Campaign Ids to make sure there is a campaign to be linked to the order 
        // WARNING: - NOT ALL ORDERS HAVE EVEN 1 MATCHING PARAMETER
        if (campaignIDs == null || campaignIds.isEmpty()) {
            return influencedRoomBookingsToCreate;
        } 
        // Number of IRB records to be created - We know this cannot be 0. 
        Integer sharingsNumber = campaignIDs.size();
        
        // Fields to be calculated depending on the number of IBR records and the Order record fields
        Decimal influencePercentage = calculateEqualShareAmount(100.00, sharingsNumber);
        Decimal netRevenueShare = calculateEqualShareAmount(order.Net_Revenue__c, sharingsNumber);
        Decimal roomRevenueShare = calculateEqualShareAmount(order.Room_Revenue__c, sharingsNumber);

        for (Id campaignId : campaignIDs) {
            
            // Define Influenced Room Booking Record record
            Influenced_Room_Booking__c influencedRoomBooking = new Influenced_Room_Booking__c(
                Campaign__c = campaignId,
                Room_Booking__c = order.Id,
                Room_Booking__r = order,
                Influence__c = influencePercentage,
                Net_Revenue_Share__c = netRevenueShare,
                Room_Revenue_Share__c = roomRevenueShare
            );

            influencedRoomBookingsToCreate.add(influencedRoomBooking);

        }

        return influencedRoomBookingsToCreate;
    }

    /**
     * Function to calculate the Equal Share Amount based on the Order record field and the number of IRB records
     *
     * @param Decimal amountToShare    - Order Record field value for calculation
     * @param Integer numberOfSharings - Number of IRB records linked to the Order record
     *
     * @return Decimal - The Equal Share amount value
     */
    private Decimal calculateEqualShareAmount(Decimal amountToShare, Integer numberOfSharings) {

        return (amountToShare == null ? 0 : amountToShare) / numberOfSharings;

    }

    /**
     * Function to calculate the Equal Share Amount of Gross Revenue on the IRB records
     *
     * @param List<Order> ordersChangedGrossRevenue - Orders Updated where Gross Revenue Field is updated
     *
     * @return void
     */
    public void calculateGrossRevenueShare(List<Order> ordersChangedGrossRevenue){

        Map<Id, Order> ordersUpdatedMap = new Map<Id, Order>();
        Set<Id> orderUpdatedIds = new Set<Id>();
        List<Influenced_Room_Booking__c> influencedRoomBookingLinked = new List<Influenced_Room_Booking__c>();
        List<Influenced_Room_Booking__c> influencedRoomBookingToUpdate = new List<Influenced_Room_Booking__c>();

        for (Order order : ordersChangedGrossRevenue) {
            orderUpdatedIds.add(order.Id);
        }
        
        // Populate ordersUpdatedMap with Order ID and Order record after quering the Related List of IRB records
        for (Order orderResult : [SELECT Id, Gross_Revenue__c, (Select Id FROM Influenced_Room_Bookings__r) FROM Order WHERE Id = :orderUpdatedIds]) {
            ordersUpdatedMap.put(orderResult.Id, orderResult);
        }

        // Query the Influenced Room Booking Records linked to the updated Order
        if (!ordersUpdatedMap.isEmpty()) {
            influencedRoomBookingLinked = [SELECT Id, Room_Booking__c, Gross_Revenue_Share__c FROM Influenced_Room_Booking__c WHERE Room_Booking__c IN :ordersUpdatedMap.keySet()];
        }

        if (!influencedRoomBookingLinked.isEmpty()) {

            for (Influenced_Room_Booking__c irb : influencedRoomBookingLinked) {
                Order ordUpdated = ordersUpdatedMap.get(irb.Room_Booking__c);
                irb.Gross_Revenue_Share__c = calculateEqualShareAmount(ordUpdated.Gross_Revenue__c, ordUpdated.Influenced_Room_Bookings__r.size());
                influencedRoomBookingToUpdate.add(irb); 
            }

        }

        if(!influencedRoomBookingToUpdate.isEmpty()){
            updateInfluencedRoomBookings(influencedRoomBookingToUpdate);
        }
    }

    /**
     * Function to update the Influenced Room Booking records after the Gross Revenue is calculated for each record
     * linked to the Order updated
     *
     * @param List<Influenced_Room_Booking__c> influencedRoomBookingsToUpdate - List of IRB records to be updated
     *
     * @return void
     */
    private void updateInfluencedRoomBookings(List<Influenced_Room_Booking__c> influencedRoomBookingsToUpdate) {
        Database.UpsertResult[] results = Database.upsert(
            influencedRoomBookingsToUpdate, 
            false
        );

        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                String errorMessage = INFLUENCED_ROOM_BOOKING_UPDATE_ERROR +
                    ': ' +
                    DatabaseUtils.getErrorString(
                        results[i].getErrors()
                    );
                
                displayAndRegisterErrorMessage(
                    errorMessage, 
                    influencedRoomBookingsToUpdate[i].Room_Booking__c
                );
            }
        }

    }

    /**
     * Function to insert the new Influenced Room Booking records
     *
     * @param List<Influenced_Room_Booking__c> influencedRoomBookingsToCreate - List of IRB records defined on generateInfluencedRoomBookingForEachCampaign
     *
     * @return void
     */
    private void createInfluencedRoomBookings(List<Influenced_Room_Booking__c> influencedRoomBookingsToCreate) {
        List<Database.SaveResult> results = Database.insert(
            influencedRoomBookingsToCreate, 
            false
        );

        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                String errorMessage = INFLUENCED_ROOM_BOOKING_INSERT_ERROR +
                    ': ' +
                    DatabaseUtils.getErrorString(
                        results[i].getErrors()
                    );

                displayAndRegisterErrorMessage(
                    errorMessage, 
                    influencedRoomBookingsToCreate[i].Room_Booking__c
                );
            }
        }
    }

    /**
     * Function to display an error message if the creation of the IRB related to the Order record fails
     *
     * @param String errorMessage - Error message returned by Database.insert results
     * @param Id parentOrderId    - Order ID that fired the issue
     *
     * @return void
     */
    private void displayAndRegisterErrorMessage(String errorMessage, Id parentOrderId) {
        Order roomBooking = new Order(
            Id = parentOrderId
        );
        
        roomBooking.addError(
            errorMessage
        );
    }
}