/**
 * @author Vasile Fana <vasile.fana@cloudshiftgroup.com>
 * @date 2020-12-01
 * @group CloudShiftGroup
 * @description  This class is responsible for finding a order's related campaigns
 *               via a junction object (Campaign External Link).
 *
 * Date          author             Change Description
 * -----------------------------------------------------------------------------------------
 * 2020-12-01    Vasile Fana       Created Class
 * 2021-04-20    Andrei Budescu    Filter updated for Campaign External Link records matched
 *                                 Changed filter for valid Orders - CreatedDate.
 */
public without sharing class OrderToCampaignMatcher {

    // Global Lists that will store String Codes from Order Record
    private List<String> pmsAgentList = new List<String>();
    private List<String> pmsCompanyList = new List<String>();
    private List<String> pmsSourceList = new List<String>();
    private List<String> rateCodeList = new List<String>();
    private List<String> propSalesInitList = new List<String>();
    private List<String> corpSalesInitList = new List<String>();
    private List<String> sCodeList = new List<String>();

    /**
     * Function to build up a Map of incoming Order IDs and a set of linked Campaign IDs
     *
     * @param List<Order> orders                        - The list of newly inserted Orders
     *
     * @return Map<Id, Set<Id>> orderIdToCampaignIdsMap - The Map of Order IDs and a set of linked Campaign IDs
     */
    public Map<Id, Set<Id>> findMatchingCampaigns(List<Order> orders) {

        Map<Id, Set<Id>> orderIdToCampaignIdsMap = new Map<Id, Set<Id>>(); 
        List<Campaign_External_Link__c> campaignExternalLinks = new List<Campaign_External_Link__c>();

        // Populate Codes String Lists
        getOrderCodeLists(orders);

        // Query the Campaign External Link Records that match the codes from the global lists
        campaignExternalLinks = [
                                SELECT 
                                    Campaign__c,
                                    PMS_Agent__c,  
                                    PMS_Company__c, PMS_Source__c, 
                                    Rate_Code__c, 
                                    nisc_Property_Sales_Initiative__c, 
                                    nisc_Corporate_Sales_Initiative__c, 
                                    S_Code__c,
                                    Campaign__r.StartDate, Campaign__r.EndDate
                                FROM Campaign_External_Link__c
                                WHERE (
                                    PMS_Agent__c IN :pmsAgentList OR 
                                    PMS_Company__c IN :pmsCompanyList OR 
                                    PMS_Source__c IN :pmsSourceList OR 
                                    Rate_Code__c IN :rateCodeList OR 
                                    nisc_Property_Sales_Initiative__c IN :propSalesInitList OR 
                                    nisc_Corporate_Sales_Initiative__c IN :corpSalesInitList OR 
                                    S_Code__c IN :sCodeList)
                                AND Active_Campaign__c = True
                                ORDER BY Name
        ];

        // Populate the Map orderIdToCampaignIdsMap
        for (Order order : orders) {
            
            Set<Id> campaignIds = new Set<Id>();

            for (Campaign_External_Link__c cel : campaignExternalLinks) {

                // Validate Order and Campaign External Link match
                if (validateOrderCampaignExternalLink(order, cel) && cel.Campaign__c != null) {

                        campaignIds.add(cel.Campaign__c);
                        orderIdToCampaignIdsMap.put(order.Id, campaignIds);

                }
            }
        }

        return orderIdToCampaignIdsMap;
    }

    /**
     * Function to populate the global Lists with the codes from the newly created Orders
     *
     * @param List<Order> ordersInserted - The list of newly inserted Orders
     *
     * @return void
     */
    private void getOrderCodeLists(List<Order> ordersInserted){

        for (Order order : ordersInserted) {
            if (!String.isBlank(order.PMS_Agent__c)) {
                pmsAgentList.add(order.PMS_Agent__c);
            }
            if (!String.isBlank(order.PMS_Company__c)) {
                pmsCompanyList.add(order.PMS_Company__c);
            }
            if (!String.isBlank(order.PMS_Source__c)) {
                pmsSourceList.add(order.PMS_Source__c);
            }
            if (!String.isBlank(order.Rate_Code__c)) {
                rateCodeList.add(order.Rate_Code__c);
            }
            if (!String.isBlank(order.nisc_Property_Sales_Initiative__c)) {
                propSalesInitList.add(order.nisc_Property_Sales_Initiative__c);
            }
            if (!String.isBlank(order.nisc_Corporate_Sales_Initiative__c)) {
                corpSalesInitList.add(order.nisc_Corporate_Sales_Initiative__c);
            }
            if (!String.isBlank(order.S_Code__c)) {
                sCodeList.add(order.S_Code__c);
            }
        }
    }

    /**
     * Function to validate the Created Date of the Order and check if there is a match between the Order
     * record and the Campaign External Link record
     *
     * @param Order  order                  - The newly created Order to be validated
     * @param Campaign_External_Link__c cel - Campaign External Link record queried from the campaignExternalLinks List
     *
     * @return Boolean - True if the newly created Order is valid and there is a match with the Campaign External Link
     */
    private Boolean validateOrderCampaignExternalLink(Order order, Campaign_External_Link__c cel) {

        Boolean isMatchFound = false;

        Set<String> fieldsToCheck = new Set<String>{'PMS_Agent__c', 'PMS_Company__c', 'PMS_Source__c', 'Rate_Code__c', 'nisc_Corporate_Sales_Initiative__c', 'nisc_Corporate_Sales_Initiative__c', 'S_Code__c'};
        // if dates 
        if (order.CreatedDate < cel.Campaign__r.StartDate && order.CreatedDate > cel.Campaign__r.EndDate) {
            return false;
        } 

        //continue with the for loop for the fields
        for (String field : fieldsToCheck) {
            if (isMatch(order, cel, field)) {
                return true;
            }
        }

        return isMatchFound;

    }

    // individual method to check the field values
    @TestVisible
    private static Boolean isMatch(Order o, Campaign_External_Link__c c, String field) {
        String orderFieldValue = String.valueOf(o.get(field));
        String campaignExtFieldValue = String.valueOf(c.get(field));
        
        return !String.isBlank(orderFieldValue) && !String.isBlank(campaignExtFieldValue) && orderFieldValue == campaignExtFieldValue;
    }
}