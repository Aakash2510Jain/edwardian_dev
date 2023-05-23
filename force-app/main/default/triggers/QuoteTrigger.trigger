trigger QuoteTrigger on Quote (After insert, After update) {
    if((trigger.isAfter) && (Trigger.isInsert || Trigger.isUpdate )){
        if(trigger.new[0].RecordTypeId == Schema.SObjectType.Quote.getRecordTypeInfosByName().get('Group Series').getRecordTypeId())
        QuoteTriggerHelper.approvalProcessHandler(trigger.new);
    }
}