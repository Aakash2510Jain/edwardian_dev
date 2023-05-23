/**
 * @author
 * @description This class is responisble for updating Sales Targets to have the
 *              correct Actual_Revenue__c and Pipeline_Revenue__c fields by looking
 *              at associated orders
 *
 * ? : ? - Original
 * 2021-01-22 : Khin Hou - updated class to use new accounts fields to check against (FIELDS_TO_CHECK_IF_ACCOUNTS_CONTAINED)
 *                         moved into a batch class so it can do more than 50k records
 *
 *
 * TODO:
 * - Rework logic to check for Orders that should roll up instead of which orders to skip
 * - Potentially look at a better filtering system than just the start of last year
 * - partial upsert and log any failed upserts in the Logs__c object
 **/
public with sharing class SalesTargetRevenueCalculationsBatch implements Database.Batchable<sObject> {

    private static final Date START_OF_LAST_YEAR = Date.newInstance(
        Date.today().addYears(-1).year(),
        01,
        01
    );

    private static final Set<String> FIELDS_TO_CHECK_IF_ACCOUNTS_CONTAINED = new Set<String>{
        'Master_Company_ID__c',
        'Parent_Company_ID__c',
        'Master_Agent_ID__c',
        'Parent_Agent_ID__c'
    };

    List<String> regions = new List<String>();
    List<String> marketSegments = new List<String>();
    List<String> actualRevenueStatus = new List<String>();
    List<String> pipelineRevenueStatus = new List<String>();

    public Database.QueryLocator start(Database.BatchableContext batchableContext) {
        return Database.getQueryLocator([
            SELECT
                Id, Target_Start_Date__c, Target_End_Date__c, Regional_Target__c, Regions__c, All_Hotels__c,
                Actual_Revenue_Status__c, Account_based_Target__c, Hotel__c, Sales_Person__c, Market_Segments__c,
                Actual_Revenue__c, Pipeline_Revenue__c, Pipeline_Revenue_Status__c, Account__c
            FROM Sales_Target__c
            WHERE Target_Start_Date__c >= :START_OF_LAST_YEAR
        ]);
    }

    public void execute(Database.BatchableContext batchableContext, List<Sales_Target__c> salesTargets) {
        Set<Id> accountIds = getAccountIds(salesTargets);
        List<Order> relatedOrders = getRelatedOrders(accountIds);

        if (!salesTargets.isEmpty() && !relatedOrders.isEmpty()) {
            calculateSalesTargets(salesTargets, relatedOrders);
        }
        //Add error handling for Sales Targets and log the errors in the Logs__c Object
        upsert salesTargets;
    }

    @SuppressWarnings('PMD.EmptyStatementBlock')
    public void finish(Database.BatchableContext batchableContext) {
        //add log inserts once that has been implemented
    }

    /**
     * Queries for relevant Orders to help calculate Sales Targets
     *
     * @param Set<Id> accountIds - Set of Account Ids to query for the related Orders
     *
     * @return List<Order> - List of Orders that are related to the Sales Targets and have a Arrival
     *                       Date greater than the start of the last year
     */
    private List<Order> getRelatedOrders(Set<Id> accountIds) {
        return [
            SELECT Id, Reservation_Status__c, Arrival_Date__c, Market_Description__c, Account.OwnerId,
                Region__c, Net_Revenue__c, Archived_Hotel_Id__c, AccountId, Master_Company__c, Master_Company_ID__c, Parent_Company_ID__c,
                Master_Agent_ID__c, Parent_Agent_ID__c
            FROM Order
            WHERE Arrival_Date__c >= :START_OF_LAST_YEAR
            OR Master_Company_ID__c IN :accountIds
            OR Parent_Company_ID__c IN :accountIds
            OR Master_Agent_ID__c IN :accountIds
            OR Parent_Agent_ID__c IN :accountIds
        ];
    }

    /**
     * Queries for relevant Orders to help calculate Sales Targets
     *
     * @param Set<Id> accountIds - Set of Account Ids to query for the related Orders
     *
     * @return List<Order> - List of Orders that are related to the Sales Targets and have a Arrival
     *                       Date greater than the start of the last year
     */
    private Set<Id> getAccountIds(List<Sales_Target__c> salesTargets) {
        Set<Id> accountIdsAssociatedWithSalesTarget = new Set<Id>();

        for (Sales_Target__c salesTarget : salesTargets) {
            accountIdsAssociatedWithSalesTarget.add(salesTarget.Account__c);
        }

        return accountIdsAssociatedWithSalesTarget;
    }

    /**
     * Queries for relevant Orders to help calculate Sales Targets
     *
     * @param List<Sales_Target__c> salesTargets - The List of Sales Targets that need updating
     * @param List<Order> orders - The List of associated Orders/Bookings to the Sales Targets
     *
     * @return List<Sales_Target__c> salesTargets - List of Udpated Sales Targets that have their new Revenue fields
     */
    private List<Sales_Target__c> calculateSalesTargets(List<Sales_Target__c> salesTargets, List<Order> orders) {
        for (Sales_Target__c salesTargetItem : salesTargets) {

            Decimal actualRevenue = 0;
            Decimal pipelineRevenue = 0;

            regions = salesTargetItem.Regions__c != null ? salesTargetItem.Regions__c.split(';') : new List<String>();
            marketSegments = salesTargetItem.Market_Segments__c != null ? salesTargetItem.Market_Segments__c.split(';') : new List<String>();
            actualRevenueStatus = salesTargetItem.Actual_Revenue_Status__c != null ? salesTargetItem.Actual_Revenue_Status__c.split(';') : new List<String>();
            pipelineRevenueStatus = salesTargetItem.Pipeline_Revenue_Status__c != null ? salesTargetItem.Pipeline_Revenue_Status__c.split(';')  : new List<String>();

            for (Order orderItem : orders) {

                if (shouldOrderBeSkipped(salesTargetItem, orderItem)) {
                    continue;
                }

                pipelineRevenue = getRevenue(
                    pipelineRevenueStatus,
                    orderItem,
                    pipelineRevenue
                );

                actualRevenue = getRevenue(
                    actualRevenueStatus,
                    orderItem,
                    actualRevenue
                );
            }
            setValues(salesTargetItem, actualRevenue, pipelineRevenue);
        }
        return salesTargets;
    }

    /**
     * Function to check whether the Order should be skipped based off some criteria
     *
     * @param Sales_Target__c salesTargetItem - the Sales Target to check against
     * @param Order orderItem - the Order to see if it should be skipped or rolled up
     *
     * @return Boolean - True if the Order should be skipped, False if the Order should be rolled up
     */
    @SuppressWarnings('PMD.CyclomaticComplexity')
    private Boolean shouldOrderBeSkipped(
        Sales_Target__c salesTargetItem,
        Order orderItem
    ) {
        if (
            !doesOrderContainRevenueStatus(actualRevenueStatus, orderItem) &&
            doesOrderContainRevenueStatus(pipelineRevenueStatus, orderItem)
        ) {
            return true;
        }

        if (isArrivalDateOutsideSalesTargetDates(salesTargetItem, orderItem)) {
            return true;
        }

        if (!marketSegments.contains(orderItem.Market_Description__c)) {
            return true;
        }

        if (
            salesTargetItem.Regional_Target__c &&
            !checkRegionalTarget(regions, orderItem)
        ) {
            return true;
        }

        if (
            !salesTargetItem.All_Hotels__c &&
            !checkAllHotels(salesTargetItem, orderItem)
        ) {
            return true;
        }

        if (
            salesTargetItem.Account_based_Target__c &&
            !checkBasedTarget(salesTargetItem, orderItem)
        ) {
            return true;
        }

        return false;
    }

    /**
     * Function to check whether the Orders Reservation Status is within the list of Sales Targets Revenue Status
     *
     * @param List<String> revenueStatusList - The list of Revenue Statuses taken from the related Sales Target
     * @param Order orderItem - the Order to see if the Reservation Status has a value in the list
     *
     * @return Boolean - True if the value is contained in the list, False if the value isn't contained in the list
     */
    private Boolean doesOrderContainRevenueStatus(List<String> revenueStatusList, Order orderItem) {
        return revenueStatusList.contains(orderItem.Reservation_Status__c);
    }

    /**
     * Function that checks whether the order Arrival date is outside of the Start and End dates of the Sales target
     *
     * @param Sales_Target__c salesTargetItem - the Sales Target to check against the Order Dates
     * @param Order orderItem - the Order to check against the Sales Target dates
     *
     * @return Boolean - True if the Order is outside of the Sales Targets dates, False if it is within the dates
     */
    private Boolean isArrivalDateOutsideSalesTargetDates(Sales_Target__c salesTargetItem, Order orderItem) {
        return (
            orderItem.Arrival_Date__c < salesTargetItem.Target_Start_Date__c ||
            orderItem.Arrival_Date__c > salesTargetItem.Target_End_Date__c
        );
    }

    /**
     * Function that checks whether the Order's Region is acceptable to add to the Sales Target
     *
     * @param List<String> regions - List of Regions on the Sales Taget
     * @param Order orderItem - the Order to check against the Sales Target dates
     *
     * @return Boolean - True if the Order has a value in the region list
     */
    private Boolean checkRegionalTarget(List<String> regions, Order orderItem) {
        return regions.contains(orderItem.Region__c);
    }

    /**
     * Function that checks whether the Order's Hotel is acceptable to add to the Sales Target
     *
     * @param Sales_Target__c salesTargetItem - the Sales Target to check against the Order Hotel
     * @param Order orderItem - the Order to check against the Sales Target Hotel
     *
     * @return Boolean - True if the Order has the same Hotel as the Sales Target
     */
    private Boolean checkAllHotels(Sales_Target__c salesTargetItem, Order orderItem) {
        return orderItem.Archived_Hotel_Id__c == salesTargetItem.Hotel__c;
    }

    /**
     * Function that checks whether the Order's Account is acceptable to add to the Sales Target
     *
     * @param Sales_Target__c salesTargetItem - the Sales Target to check against
     * @param Order orderItem - the Order to check against the Sales Target Account
     *
     * @return Boolean - True if the Order has an account assiocated to the Sales Target Account
     */
    private Boolean checkBasedTarget(Sales_Target__c salesTargetItem, Order orderItem) {
        Boolean doesContainAccount = false;

        for (String fieldName : FIELDS_TO_CHECK_IF_ACCOUNTS_CONTAINED) {
            if (salesTargetItem.Account__c == orderItem.get(fieldName)) {
                doesContainAccount = true;
                break;
            }
        }
        return doesContainAccount;
    }

    /**
     * Function that updates the revenue fields on the Sales Target
     *
     * @param Sales_Target__c salesTargetItem - the Sales Target to check against the Order Dates
     * @param Decimal actualRevenue - The actual revenue amount calcualted
     * @param Decimal pipelineRevenue - The pipeline revenue amount calcualted
     *
     * @return no return type - updates the salesTargetItem reference in memory
     */
    private void setValues(Sales_Target__c salesTargetItem, Decimal actualRevenue, Decimal pipelineRevenue) {
        if (actualRevenue != salesTargetItem.Actual_Revenue__c) {
            salesTargetItem.Actual_Revenue__c = actualRevenue;
        }
        if (pipelineRevenue != salesTargetItem.Pipeline_Revenue__c) {
            salesTargetItem.Pipeline_Revenue__c = pipelineRevenue;
        }
    }

    /**
     * Function that adds up the revenue if the order has a value within the Sales Targets revenue statuses list
     *
     * @param List<String> revenueStatusList - The list of Revenue Statuses taken from the related Sales Target
     * @param Order orderItem - the Order to see if the Reservation Status has a value in the list
     * @param Decimal revenue - Revenue amount to add up
     *
     * @return Decimal revenue - updates the revenue amount
     */
    private Decimal getRevenue(List<String> revenueStatusList, Order orderItem, Decimal revenue) {
        if (doesOrderContainRevenueStatus(revenueStatusList, orderItem)) {
            revenue += orderItem.Net_Revenue__c;
        }
        return revenue;
    }

}