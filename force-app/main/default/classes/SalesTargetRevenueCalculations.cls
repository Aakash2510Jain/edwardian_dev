@SuppressWarnings('PMD.CyclomaticComplexity')
public without sharing class SalesTargetRevenueCalculations implements Schedulable {

    private static final String CRON_EXPR = '0 0 2 * * ?';
    private static final Set<String> FIELDS_TO_CHECK_IF_ACCOUNTS_CONTAINED = new Set<String>{
        'Master_Company_ID__c',
        'Parent_Company_ID__c',
        'Master_Agent_ID__c',
        'Parent_Agent_ID__c'
    };

    public static String scheduleIt() {
        SalesTargetRevenueCalculations job = new SalesTargetRevenueCalculations();
        return System.schedule('Sales Target Revenue Calculations', CRON_EXPR, job);
    }

    public void execute(SchedulableContext ctx) {
        Set<Id> accountIds = new Set<Id>();
        List<Order> orders = [
            SELECT Id, Reservation_Status__c, Arrival_Date__c, Market_Description__c, Account.OwnerId,
                Region__c, Net_Revenue__c, Hotel__c, AccountId, Master_Company__c, Master_Company_ID__c, Parent_Company_ID__c,
                Master_Agent_ID__c, Parent_Agent_ID__c
            FROM Order
        ];
        for (Order orderItem : orders) {
            accountIds.add(orderItem.AccountId);
        }
        List<Sales_Target__c> salesTargets = [
            SELECT Id, Target_Start_Date__c, Target_End_Date__c, Regional_Target__c, Regions__c, All_Hotels__c,
                Actual_Revenue_Status__c, Account_based_Target__c, Hotel__c, Sales_Person__c, Market_Segments__c,
                Actual_Revenue__c, Pipeline_Revenue__c, Pipeline_Revenue_Status__c, Account__c
            FROM Sales_Target__c
        ];

        if (!salesTargets.isEmpty() && !orders.isEmpty()) {
            calcByOrders(salesTargets, orders);
        }
        upsert salesTargets;
    }

    private static List<Sales_Target__c> calcByOrders(List<Sales_Target__c> salesTargets, List<Order> orders) {
        for (Sales_Target__c salesTargetItem : salesTargets) {
            Decimal actualRevenue = 0;
            Decimal pipelineRevenue = 0;
            List<String> regions = (salesTargetItem.Regions__c == null) ? new List<String>() : salesTargetItem.Regions__c.split(';');
            List<String> marketSegments = (salesTargetItem.Market_Segments__c == null) ? new List<String>() : salesTargetItem.Market_Segments__c.split(';');
            List<String> actualRevenueStatus = (salesTargetItem.Actual_Revenue_Status__c == null) ? new List<String>() : salesTargetItem.Actual_Revenue_Status__c.split(';');
            List<String> pipelineRevenueStatus = (salesTargetItem.Pipeline_Revenue_Status__c == null) ? new List<String>() : salesTargetItem.Pipeline_Revenue_Status__c.split(';');

            for (Order orderItem : orders) {
                // if it doesn't match the criteria then ignore this record
                if (((!actualRevenueStatus.contains(orderItem.Reservation_Status__c) && pipelineRevenueStatus.contains(orderItem.Reservation_Status__c))
                        || (orderItem.Arrival_Date__c < salesTargetItem.Target_Start_Date__c)
                        || (orderItem.Arrival_Date__c > salesTargetItem.Target_End_Date__c)
                        || !marketSegments.contains(orderItem.Market_Description__c))
                    || ((salesTargetItem.Regional_Target__c && !checkRegionalTarget(regions, orderItem))
                        || (!salesTargetItem.All_Hotels__c && !checkAllHotels(salesTargetItem, orderItem))
                        || (salesTargetItem.Account_based_Target__c && !checkBasedTarget(salesTargetItem, orderItem))))
                {
                    continue;
                }

                pipelineRevenue = getPipelineRevenue(
                    pipelineRevenueStatus,
                    orderItem,
                    pipelineRevenue
                );

                actualRevenue = getActualRevenue(
                    actualRevenueStatus,
                    orderItem,
                    actualRevenue
                );
            }

            setValues(salesTargetItem, actualRevenue, pipelineRevenue);
        }
        return salesTargets;
    }

    private static void setValues(Sales_Target__c salesTargetItem, Decimal actualRevenue, Decimal pipelineRevenue) {
        if (actualRevenue != salesTargetItem.Actual_Revenue__c) {
            salesTargetItem.Actual_Revenue__c = actualRevenue;
        }
        if (pipelineRevenue != salesTargetItem.Pipeline_Revenue__c) {
            salesTargetItem.Pipeline_Revenue__c = pipelineRevenue;
        }
    }

    private static Boolean checkRegionalTarget(List<String> regions, Order orderItem) {
        return regions.contains(orderItem.Region__c);
    }

    private static Boolean checkAllHotels(Sales_Target__c salesTargetItem, Order orderItem) {
        return orderItem.Hotel__c == salesTargetItem.Hotel__c;
    }

    private static Boolean checkBasedTarget(Sales_Target__c salesTargetItem, Order orderItem) {
        Boolean doesContainAccount = false;

        for (String fieldName : FIELDS_TO_CHECK_IF_ACCOUNTS_CONTAINED) {
            if (salesTargetItem.Account__c == orderItem.get(fieldName)) {
                doesContainAccount = true;
                break;
            }
        }
        return doesContainAccount;
    }

    private static Decimal getPipelineRevenue(List<String> pipelineRevenueStatus, Order orderItem, Decimal pipelineRevenue) {
        if (pipelineRevenueStatus.contains(orderItem.Reservation_Status__c)) {
            pipelineRevenue += orderItem.Net_Revenue__c;
        }
        return pipelineRevenue;
    }

    private static Decimal getActualRevenue(List<String> actualRevenueStatus, Order orderItem, Decimal actualRevenue) {
        if (actualRevenueStatus.contains(orderItem.Reservation_Status__c)) {
            actualRevenue += orderItem.Net_Revenue__c;
        }
        return actualRevenue;
    }
}