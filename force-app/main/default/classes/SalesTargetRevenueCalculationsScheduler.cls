public without sharing class SalesTargetRevenueCalculationsScheduler implements Schedulable {
    public void execute(SchedulableContext ctx) {
        SalesTargetRevenueCalculationsBatch salesTargetBatch = new SalesTargetRevenueCalculationsBatch();
        Database.executebatch(salesTargetBatch);
    }
}