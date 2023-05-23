/**
 * @author Vasile Fana <vasile.fana@cloudshiftgroup.com>
 * @date 2020-12-09
 * @group CloudShiftGroup
 * @description  This class is responsible for creating the influenced room bookings
 *               and campaign members for each order and its matching campaigns.
 *
 * Date          author             Change Description
 * -------------------------------------------------------------------------------------------------
 * 2020-12-09    Vasile Fana       Created Class
 * 2020-04-21    Andrei Budescu    Removed logic for OrderToCampaignMatcher. New incoming
 *                                 parameter orderIdToCampaignIdsMap used to created the IRB records
 */
public with sharing class OrderToCampaignMatchingServices {
    
    /**
     * Function to call the InfluencedRoomBookingService class in order to create the Influenced 
     * Room Booking records as links between the Order and Campaign Objects
     *
     * @param Map<Id,Set<Id>> orderIdToCampaignIdsMap - Map of Order IDs and Set Campaign IDs
     * @param Map<Id,Order>   newOrdersMap            - Map of Order IDs and Order records
     *
     * @return void
     */
    public void createOrderToCampaignInfluencingRecords(Map<Id, Set<Id>> orderIdToCampaignIdsMap, Map<Id, Order> newOrdersMap) {

        List<Influenced_Room_Booking__c> createdInfluencedRoomBookings = new List<Influenced_Room_Booking__c>();

        // Call the function InfluencedRoomBookingServices.generateInfluencedRoomBookings using the orderIdToCampaignIdsMap and newOrdersMap
        InfluencedRoomBookingServices influenceRBServices = new InfluencedRoomBookingServices();

        // Populate the list of Influenced Room Booking records created
        createdInfluencedRoomBookings = influenceRBServices.generateInfluencedRoomBookings(
            orderIdToCampaignIdsMap,
            newOrdersMap
        );
        
        // Call the function CampaignMemberServices.generateCampaignMembers using the list of Influenced Room Booking
        if (!createdInfluencedRoomBookings.isEmpty()) {
            CampaignMemberServices cmpMemberServices = new CampaignMemberServices();
            cmpMemberServices.generateCampaignMembers(
                createdInfluencedRoomBookings
            );
        }
    }
}