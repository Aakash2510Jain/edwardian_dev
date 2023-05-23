trigger OpportunityTrigger on Opportunity (before update, before insert, after update) {

    new OpportunityTriggerHandler().run();
    
    if(Trigger.isAfter && Trigger.isUpdate){
        if(!test.isRunningTest()){
            OpportunityTriggerHandler.removePropertyRecord(trigger.newMap, trigger.oldMap);
        }
        
    }

}