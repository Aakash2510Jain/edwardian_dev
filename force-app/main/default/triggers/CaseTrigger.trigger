trigger CaseTrigger on Case (before insert, before update, after insert, after update) {
    CaseTriggerHandler handler = new CaseTriggerHandler();
    handler.dispatch();
}