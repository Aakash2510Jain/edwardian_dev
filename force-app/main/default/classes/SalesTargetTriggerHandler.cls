public without sharing class SalesTargetTriggerHandler {
    public static void handle(List<Sales_Target__c> newList, Map<Id, Sales_Target__c> oldMap, System.TriggerOperation triggerEvent) {
        if (triggerEvent == System.TriggerOperation.BEFORE_INSERT) {
            handleBeforeInsert(newList);
        } else if (triggerEvent == System.TriggerOperation.BEFORE_UPDATE) {
            handleBeforeUpdate(newList, oldMap);
        } else {
            System.debug('default block');
        }
    }

    public static void handleBeforeInsert(List<Sales_Target__c> newList) {
        SalesTargetTriggerService.autocompleteStartAndEndDate(newList);
    }

    public static void handleBeforeUpdate(List<Sales_Target__c> newList, Map<Id, Sales_Target__c> oldMap) {
        SalesTargetTriggerService.autocompleteStartAndEndDate(newList);
    }
}