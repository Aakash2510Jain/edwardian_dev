/**
 * @author Vasile Fana <vasile.fana@cloudshiftgroup.com>
 * @date 2020-12-02
 * @group CloudShiftGroup
 * @description  This class is responsible for generating and deleting the
 *               CampaignMember records for each order and it's related 
 *               influencing campaigns.
 *
 * Date          author             Change Description
 * ------------------------------------------------------------------------------------------------------------------------
 * 2020-12-02    Vasile Fana       Created Class
 * 2021-04-21    Andrei Budescu    Removed functions not used findAndRemoveCampaignMembers, filerCampaignMembersToBeRemoved,
 *                                 findCampaignMembersToRemove, removeCampaignMembers.
 */
public without sharing class CampaignMemberServices {
    private static final String CAMPAIGN_MEMBER_INSERT_ERROR = System.Label.Campaign_Member_Insert_Error_Message;
    private static final String CAMPAIGN_MEMBER_DELETE_ERROR = System.Label.Campaign_Member_Delete_Error_Message;
    
    /**
     * Function to generate Campaign Members based on the newly created Influenced Room Booking Records
     *
     * @param List<Influenced_Room_Booking__c> influencedRoomBookings - List of IRB records newly created
     *
     * @return void
     */
    public void generateCampaignMembers(List<Influenced_Room_Booking__c> influencedRoomBookings) {

        // Create Map of ID and Influenced Room Booking records based on the List influencedRoomBookings
        Map<Id, Influenced_Room_Booking__c> influencedRoomBookingsMap = new Map<Id, Influenced_Room_Booking__c>(influencedRoomBookings);

        Map<Id, CampaignMember> campaignMemeberToInfluencedRBIdMap = new Map<Id, CampaignMember>();
        List<Influenced_Room_Booking__c> filterdInfluencedRoomBookings = new List<Influenced_Room_Booking__c>();

        for (Influenced_Room_Booking__c influencedRoomBooking : influencedRoomBookings) {

            // Check if the Contact Name on the Order record is not null
            if (influencedRoomBooking.Room_Booking__r.Contact_Name__c != null) {
                filterdInfluencedRoomBookings.add(influencedRoomBooking);
            }

        }

        // IRB records containing Order - Contact Name populated
        if (!filterdInfluencedRoomBookings.isEmpty()) {
            campaignMemeberToInfluencedRBIdMap = generateCampaignMemberForEachInfluencedRoomBooking(
                filterdInfluencedRoomBookings
            );
        }

        if (!campaignMemeberToInfluencedRBIdMap.isEmpty()) {
            createCampaignMembers(
                campaignMemeberToInfluencedRBIdMap,
                influencedRoomBookingsMap
            );
        }
    }

    /**
     * Function to generate a Map of IRB ID and Campaign Members based on the newly created Influenced Room Booking Records
     * that contain a Contact Name on the Order Parent Record
     *
     * @param List<Influenced_Room_Booking__c> iRBsToGenerateCMs - List of IRB records newly created
     *
     * @return Map<Id, CampaignMember> campaignMemeberToInfluencedRBIdMap - Map of IRB ID and the new Campaign Member to be created
     */
    private static  Map<Id, CampaignMember> generateCampaignMemberForEachInfluencedRoomBooking(List<Influenced_Room_Booking__c> iRBsToGenerateCMs) {

        Map<Id, CampaignMember> campaignMemeberToInfluencedRBIdMap = new Map<Id, CampaignMember>();

        for (Influenced_Room_Booking__c influencedRB : iRBsToGenerateCMs) {

            Id contactId = influencedRB.Room_Booking__r.Contact_Name__c;

            if (contactId != null) {
                CampaignMember campaignMember = new CampaignMember(
                    CampaignId = influencedRB.Campaign__c,
                    ContactId = contactId,
                    Status = 'Sent'
                );

                campaignMemeberToInfluencedRBIdMap.put(influencedRB.Id, campaignMember);
            }
        }
        
        return campaignMemeberToInfluencedRBIdMap;
    }

    /**
     * Function to insert the new Campaign Members
     *
     * @param Map<Id,CampaignMember> campaignMemeberToInfluencedRBIdMap - Map of IRB ID and the Campaign Member to be inserted
     * @param Map<Id,Influenced_Room_Booking__c> iRBsMap                - Map of ID and IRB record newly created
     *
     * @return void
     */
    private void createCampaignMembers(
                                        Map<Id, CampaignMember> campaignMemeberToInfluencedRBIdMap, 
                                        Map<Id, Influenced_Room_Booking__c> iRBsMap
                                      ) {

        List<Database.SaveResult> results = Database.insert(
            campaignMemeberToInfluencedRBIdMap.values(), 
            false
        );
        List<Id> influencedRBs = new List<Id>(
            campaignMemeberToInfluencedRBIdMap.keySet()
        );

        for (Integer i = 0; i < results.size(); i++) {

            if (!results[i].isSuccess()) {

                String errorMessage = CAMPAIGN_MEMBER_INSERT_ERROR +
                    ': ' +
                    DatabaseUtils.getErrorString(
                        results[i].getErrors()
                    );

                Order roomBooking = new Order(
                    Id = iRBsMap.get(influencedRBs[i]).Room_Booking__c
                );
                roomBooking.addError(
                    errorMessage
                );
            }
        }
    }
}