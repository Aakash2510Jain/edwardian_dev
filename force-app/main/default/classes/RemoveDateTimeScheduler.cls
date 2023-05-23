public with sharing class RemoveDateTimeScheduler implements Schedulable{
    List<Case> newCases;

    public RemoveDateTimeScheduler(List<Case> cases) {
        newCases = cases;
    }

    public void execute(SchedulableContext sc) {
        list<Case> casesToUpdate = new List<Case>();
        for (Case newCase : newCases) {
            Case cs = new Case(Id = newCase.Id);
            if (newCase.Booking_Confirmation_Flag__c != null) {
                cs.Booking_Confirmation_Flag__c = null;
            }
            if (newCase.Block_Code_Flag__c != null) {
                cs.Block_Code_Flag__c = null;
            }
            casesToUpdate.add(cs);
        }
        update casesToUpdate;
        if (!Test.isRunningTest()) {
            String jobId = sc.getTriggerId();
            System.abortJob(jobId);
        }
    }
}