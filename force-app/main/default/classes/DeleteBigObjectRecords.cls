global class DeleteBigObjectRecords implements Database.Batchable<Archive_Individual_Email_Result__b> {
    global set<id> contactIds;
    global DeleteBigObjectRecords(set<id> contactIds) {
        this.contactIds = contactIds;
    }
    
    public Iterable<Archive_Individual_Email_Result__b> start(Database.BatchableContext BC) {
        List<Archive_Individual_Email_Result__b> bigObjectList =  [SELECT id From Archive_Individual_Email_Result__b where Contact_Id__c like '123%' and Created_Date_Time__c < Today];
        return bigObjectList;
    }
    public void execute(Database.BatchableContext BC, List<Archive_Individual_Email_Result__b> bigObjectListToDelete){
        system.debug('bigObjectListToDelete-->'+bigObjectListToDelete.size());
        database.deleteImmediate(bigObjectListToDelete);
    }
    
    public void finish(Database.BatchableContext BC) {
    }  
    
}