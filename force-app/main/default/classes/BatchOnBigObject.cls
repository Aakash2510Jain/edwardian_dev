global class BatchOnBigObject  implements Database.Batchable<sObject> ,Database.stateful {
    
    global set<id> contactIds;
    global BatchOnBigObject(set<id> contactIds) {
        this.contactIds = contactIds;
    }
    
    global Database.QueryLocator Start(Database.BatchableContext bc){
        System.debug('ContactId Size == >'+contactIds.size());
        return Database.getQueryLocator([Select Id ,Is_Related_Big_Object_Deleted__c,et4ae5__Contact__c from et4ae5__IndividualEmailResult__c where et4ae5__Contact__c In :contactIds ]);
    }
    global void Execute(Database.BatchableContext bc,List<et4ae5__IndividualEmailResult__c> IndvEmailResultList){
        system.debug('size of IndvEmailResultList == >'+IndvEmailResultList.size());
        List<Archive_Individual_Email_Result__b> bigObjecRecToInsertList = new List<Archive_Individual_Email_Result__b>();
        if(!IndvEmailResultList.isEmpty()){
            for(et4ae5__IndividualEmailResult__c IndEmailRec : IndvEmailResultList){
                Archive_Individual_Email_Result__b ArIndEmReBig = new Archive_Individual_Email_Result__b();
                ArIndEmReBig.Contact_Id__c = IndEmailRec.et4ae5__Contact__c;
                ArIndEmReBig.Created_Date_Time__c =system.now();
                ArIndEmReBig.Name__c = IndEmailRec.Name;
                ArIndEmReBig.Unique_Identifier__c = Decimal.valueOf(IndEmailRec.Id);    
                bigObjecRecToInsertList.add(ArIndEmReBig);
            }
            if(bigObjecRecToInsertList.size()>0){
                Database.SaveResult[] succesResults =  database.insertImmediate(bigObjecRecToInsertList);
                System.debug('SUCCESS Big Object Size ==> '+succesResults.size());
            }
            
        } 
    }
    global void finish(Database.BatchableContext bc){
        
    }
}