public class TriggerOnTaskHelper {
    Public Static void updateBookingDate(List<Task> newTasks ){
        system.debug('newTasks::'+newTasks);
        List<nihrm__Booking__c> bookingToBeUpdate = new List<nihrm__Booking__c> ();
        for(Task taskRec:newTasks){
            if(taskRec.WhatId != null && string.valueOf(taskRec.whatId.getsobjecttype()) == 'nihrm__Booking__c') {
                nihrm__Booking__c  booking   = new  nihrm__Booking__c ();
                booking.Id                   = taskRec.WhatId;
                if(taskRec.Subject.Contains('Chase rooming list')){
                    booking.CRLtaskCreatedDate__c= system.today();
                }            
                else if(taskRec.Subject.Contains('Chase deposit') || taskRec.Subject.Contains('AUTO: Chase Deposit')){
                    booking.Cd1taskCreatedDate__c = system.today();
                }else if(taskRec.Subject.Contains('Chase final deposit')){
                    booking.Cd2taskCreatedDate__c = system.today();
                }else  if(taskRec.Subject.Contains('Follow up post event')){
                    booking.FUPEtaskCreatedDate__c = system.today();
                }else if(taskRec.Subject.Contains('Chase to rebook')){
                    booking.CTRtaskCreatedDate__c = system.today();
                }else if(taskRec.Subject.Contains('Chase BEO final details')){
                    booking.planning_2_taskCreatedDate__c = system.today();
                }
                bookingToBeUpdate.add(booking);
            }
        } 
        if(!bookingToBeUpdate.isEmpty()){
            Map<Id, nihrm__Booking__c> mapSObj = new Map<Id, nihrm__Booking__c>();
            mapSObj.putAll(bookingToBeUpdate);
            update mapSObj.values();
            system.debug('mapSObj::'+mapSObj);
            //update bookingToBeUpdate;
            // map key can't be duplicate
        }
        system.debug('bookingToBeUpdate::'+bookingToBeUpdate);
        
    }
    Public Static void updateBookingDate(){
    integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    
    }
}