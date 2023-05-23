Global class BatchOnBigObjectToDelete implements Database.Batchable<Archive_Individual_Email_Result_V1__b> {
    
    global set<id> contactIds;
    global BatchOnBigObjectToDelete(set<id> contactIds) {
        this.contactIds = contactIds;
    }
    Global Iterable<Archive_Individual_Email_Result_V1__b> Start(Database.BatchableContext bc){
        integer daysToDeduct = integer.valueOf(system.label.BIG_Object_Batch_limit);
        DateTime addDayTime = DateTime.Now().AddDays(-daysToDeduct);
        List<Archive_Individual_Email_Result_V1__b> bigobjectList = [SELECT Contact_Id__c,Created_Date_Time__c,Unique_Identifier__c FrOM Archive_Individual_Email_Result_V1__b WHERE Contact_Id__c IN : contactIds AND Created_Date_Time__c <: addDayTime limit 50000];
        return bigobjectList; 
    }
    Global void Execute(Database.BatchableContext bc, List<Archive_Individual_Email_Result_V1__b> bigObjectListToDelete){
        if(!bigObjectListToDelete.isEmpty()){
            database.deleteImmediate(bigObjectListToDelete);
        }
    }
    Global void finish(Database.BatchableContext bc){
    }
}