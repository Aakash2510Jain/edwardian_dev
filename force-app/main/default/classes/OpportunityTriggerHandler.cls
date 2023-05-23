public with sharing class OpportunityTriggerHandler extends TriggerHandlerFramework{

    public override void beforeInsert() {
        checkContractEndDate();
    }

    public override void beforeUpdate() {
        List<Opportunity> opps = [
            SELECT Id, Proposed_Contract_Start_Date__c, Proposed_Contract_End_Date__c, 
                (SELECT Id FROM OpportunityLineItems)
            FROM Opportunity
            WHERE Id IN :Trigger.old
        ];
        for (Opportunity opp : opps) {
            Opportunity newOpp = (Opportunity)Trigger.newMap.get(opp.Id);

            if (opp.OpportunityLineItems.size() > 0
                && (newOpp.Proposed_Contract_Start_Date__c != opp.Proposed_Contract_Start_Date__c || newOpp.Proposed_Contract_End_Date__c != opp.Proposed_Contract_End_Date__c)){
                    newOpp.addError('Cannot change contract dates for opportunity with related products. Please, remove products before changing contract dates.');
            }
        }

        checkContractEndDate();
    }

    public static void checkContractEndDate() {
        List<Leisure_Seasonal_Dates__mdt> allPeriods =  [
            SELECT Id, DeveloperName, MasterLabel, Label, QualifiedApiName, Start_Date__c, End_Date__c, Day_of_Week__c 
            FROM Leisure_Seasonal_Dates__mdt 
            ORDER BY Start_Date__c ASC];
        Date lastPeriodEndDate = allPeriods[allPeriods.size() - 1].End_Date__c;

        Id rt = new SObjectRecordTypes('Opportunity').getRecordTypeId('Leisure');

        for (Opportunity opp : (List<Opportunity>)Trigger.new) {
            if (opp.Proposed_Contract_End_Date__c != null && opp.Proposed_Contract_End_Date__c > lastPeriodEndDate && opp.RecordTypeId == rt && opp.Pricing_Structure__c == 'Seasonal'){
                opp.addError('Proposed contract end date cannot be greater than existing periods.');
            }
        }
    }
    
    public static void removePropertyRecord(Map<Id, Opportunity> newMap, Map<Id,Opportunity> oldMap){
        List<String> propertiesRemaining = new List<String>();
        for(Opportunity opp : newMap.Values()){
            if(opp.Properties__c != oldMap.get(opp.Id).Properties__c){
                system.debug(oldMap.get(opp.Id).Properties__c);
                system.debug(opp.Properties__c );
                system.debug((oldMap.get(opp.Id).Properties__c).remove(opp.Properties__c));
                propertiesRemaining = opp.Properties__c.split(';');
            } 
        }
        system.debug(propertiesRemaining);
        
        List<Group_Series_Rates__c> gsrToBeRemoved = [Select Id, Name, Hotel__c, Opportunity__c from Group_Series_Rates__c where Opportunity__c IN : newMap.keyset() AND Hotel__c NOT IN :propertiesRemaining];
        database.delete(gsrToBeRemoved);
    }
}