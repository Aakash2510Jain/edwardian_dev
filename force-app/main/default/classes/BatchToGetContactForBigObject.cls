public class BatchToGetContactForBigObject implements Database.Batchable<sObject>{
    Public static set<Id> contactIds = new set<id>();
    Public Database.QueryLocator Start( Database.BatchableContext bc){
        return Database.getQueryLocator([Select Id From Contact where Is_Related_Big_Object_Deleted__c = false]);
    }
    public void Execute(Database.BatchableContext bc,List<Contact> ContactList){
        if(!ContactList.isEmpty()){
            for(Contact conRec : ContactList){
                contactIds.add(conRec.Id);
                conRec.Is_Related_Big_Object_Deleted__c = true;
            }
            update ContactList;
        }
    }
    public void Finish(Database.BatchableContext bc){
        system.debug('contactIds--->'+contactIds);
        system.debug('contactIds---->'+contactIds.size());
    }
}