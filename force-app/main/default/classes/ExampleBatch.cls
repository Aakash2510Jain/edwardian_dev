public class ExampleBatch implements Database.Batchable<Archived_Individual_Email_Result__b>, Database.Stateful{
    Public static Integer count = 0;
    public static integer totalContactCount = 0;//41326
    
    public Iterable<Archived_Individual_Email_Result__b> start(Database.BatchableContext BC) {
        List<Archived_Individual_Email_Result__b> objList = new List<Archived_Individual_Email_Result__b>();
        Map<Id, Contact> contactIdByContactRec = new Map<Id, Contact>([Select Id,Is_Related_Big_Object_Deleted__c From Contact where Is_Related_Big_Object_Deleted__c = false limit 10000]);
        objList = [SELECT Contact__c,Id,Created_Date__c FROM Archived_Individual_Email_Result__b where  Created_Date__c < TODAY LIMIT 50000];
        return objList; 
    }
    
    public void execute(Database.BatchableContext BC, List<Archived_Individual_Email_Result__b> scope){
        if(scope != null && scope.size() > 0){
            List<Contact> contactListToUpdate = new List<Contact>();
            set<Id> contactIds = new Set<Id>();
            
            for(Archived_Individual_Email_Result__b bigObjectRec : scope){
                contactIds.add(bigObjectRec.Contact__c);             
                
            }
            if(!contactIds.isEmpty()){
                for(Id conId :  contactIds){
                    Contact contactRecToUpdate = new Contact();
                    contactRecToUpdate.Id = conId;
                    contactRecToUpdate.Is_Related_Big_Object_Deleted__c = true;
                    contactListToUpdate.add(contactRecToUpdate);
                }
                update contactListToUpdate;
            }
        }
        totalContactCount = [select count() from contact];//41000
        count = count + 10000;
    }
    
    public void finish(Database.BatchableContext BC) {
       
        system.debug('totalContactCount--->'+totalContactCount);
        system.debug('count-->'+count);
        if(count < totalContactCount){
            ExampleBatch bacthinstance = new ExampleBatch();
            database.executeBatch(bacthinstance);
        }        
    }
}