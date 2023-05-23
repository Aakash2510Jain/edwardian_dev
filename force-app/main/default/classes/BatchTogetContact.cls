global without sharing class BatchTogetContact implements Database.Batchable<sObject> ,Database.stateful {
    global Set<Id> conIdSet;
    public BatchTogetContact(){
        conIdSet = new Set<Id>();
    }
    global Database.QueryLocator Start( Database.BatchableContext bc){
        set<id> conId = new Set<Id>();
           
        return Database.getQueryLocator([SELECT Id,Name,Is_Related_Big_Object_Deleted__c FROM Contact WHERE Is_Related_Big_Object_Deleted__c = false]);
    }
    global void Execute(Database.BatchableContext bc,List<Contact> conList){
        system.debug('conList--->'+conList);
        List<Contact> conListToUpdate = new List<Contact>();
        if(conList.size()>0){
            for(Contact con : conList){
                Contact conToUpdate = new Contact();
                conToUpdate.id= con.Id;
                conToUpdate.Is_Related_Big_Object_Deleted__c = true;
                conListToUpdate.add(conToUpdate);
                conIdSet.add(con.Id);
            }
            update conListToUpdate;
        }
    }
    global void Finish(Database.BatchableContext bc){
        if(!conIdSet.isEmpty()){
            System.debug('Id Size Batch 1 === >'+conIdSet.size());
            BatchOnBigObjectToDelete batchInstance = new BatchOnBigObjectToDelete(conIdSet);
            database.executeBatch(batchInstance);
            System.debug('Second Batch Called');
        }
    }
}