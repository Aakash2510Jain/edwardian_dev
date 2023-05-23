trigger SalesTargetTrigger on Sales_Target__c (before insert, before update) {
    SalesTargetTriggerHandler.handle(Trigger.new, Trigger.oldMap, Trigger.operationType);
}