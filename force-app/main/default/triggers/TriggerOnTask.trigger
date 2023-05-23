trigger TriggerOnTask on Task (after insert) {
    system.debug('I am running'+label.Activate_Trigger_on_task);
    if(label.Activate_Trigger_on_task == 'Active'){
        system.debug('I am running');
        if(trigger.isInsert && trigger.isAfter){
            TriggerOnTaskHelper.updateBookingDate(Trigger.new);
        }    
    }
    
}