global class generateSignatureDocsBatch implements Database.batchable<sObject>,Database.Stateful, Database.AllowsCallouts{ 
    
    global id contractId;
    global String query;
    
    global generateSignatureDocsBatch(String congaQuery){
        query = congaQuery;
    }
    
    global Database.QueryLocator start(Database.BatchableContext info){ 
        
        String dbquery = 'select Conga_Template_ID__c , Conga_Sign_URL__c ,Id , Conga_Url__c from contract LIMIT 1';
        
        return Database.getQueryLocator(dbquery);

        
    }     
    global void execute(Database.BatchableContext BC,List<contract> scope){
        system.debug('query'+query);
        String AttId = CongaHelperToolLightning.generateReport(query,'Signature Template','','','');
        system.debug('AttId'+AttId);
        
    }     
    global void finish(Database.BatchableContext info){     
        
    } 
}