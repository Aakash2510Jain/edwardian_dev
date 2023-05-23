global class BatchToUpdateContact implements Database.Batchable<sObject> ,Database.stateful {
    
    global Database.QueryLocator Start(Database.BatchableContext bc){
        return Database.getQueryLocator([select id,Is_Related_Big_Object_Deleted__c from contact where Is_Related_Big_Object_Deleted__c = true]);
    }
    global void Execute(Database.BatchableContext bc,List<contact> contactList){
        for(Contact con : contactList){
            con.Is_Related_Big_Object_Deleted__c = false;
        }
        update contactList;
    }
    global void finish(Database.BatchableContext bc){
        
    }
}