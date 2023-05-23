public without sharing class EdwardianBookingForm {
    @AuraEnabled
    Public Static nihrm__Booking__c getCurrentBookingDetails(String recordId){
        try{
             
             nihrm__Booking__c bookingRec = [SELECT Id,Name__c,nihrm__BookingContact__r.Name,nihrm__BookingContact__r.Phone,Number_Of_Guests__c,Coffee_Tea__c,Soft_Drinks__c,Laptop_Hire__c,Access_For_Setup__c,Arrival__c,Breaks__c,Lunch__c,Finish__c,Other__c,Location__c,Equipment__c,Set_up_Comments__c,Purpose__c,Deliveries_Comments__c,Special_Requirement_Comments__c FROM nihrm__Booking__c WHERE Id=:recordId LIMIT 1];
            
            System.debug('Arrivaltime==='+bookingRec.Arrival__c);
            system.debug('bookingRec::'+bookingRec);
            return bookingRec;   
            
            
        }catch(Exception e){
            System.debug('Error  '+e.getMessage() + ' && Line '+e.getLineNumber());
        }
        return null;
    }
    
       @AuraEnabled
    Public Static nihrm__Booking__c UpdateBookingDetails(String recordId,nihrm__Booking__c bookingRec, String Coffeevalue,String Drinksvalue,string Laptopvalue){  
       // system.debug('recordId==>>'+recordId);
      //  system.debug('Coffeevalue::'+Coffeevalue);
        try{
        /*  list<nihrm__Booking__c> bookinglist = new list<nihrm__Booking__c>();
            bookingRec =  [SELECT Id,Name__c,nihrm__BookingContact__r.Name,nihrm__BookingContact__r.Phone FROM nihrm__Booking__c WHERE Id=:recordId limit 1 ];
            nihrm__Booking__c bkk = new nihrm__Booking__c();
            bkk.id = bookingRec.id;
            bookinglist.add(bkk);
            update bookinglist;*/
            
           
            system.debug('After update Arrival__c ==>>'+bookingRec.Arrival__c);
            system.debug('After update Breaks__c ==>>'+bookingRec.Breaks__c);
            system.debug('After update Coffee_Tea__c ==>>'+bookingRec.Coffee_Tea__c);
            system.debug('After update Finish__c ==>>'+bookingRec.Finish__c);            
            system.debug('after bookingRec==>>'+bookingRec);
            update bookingRec;  
            
            
            return bookingRec;
        }catch(Exception e){
            System.debug('Error  '+e.getMessage() + ' && Line '+e.getLineNumber());
        }
        return null;
        
    }
}