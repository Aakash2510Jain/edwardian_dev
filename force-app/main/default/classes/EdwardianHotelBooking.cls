public without sharing class EdwardianHotelBooking {
    @AuraEnabled
    public static nihrm__Booking__c getBooking(string recordId){
        try{
            nihrm__Booking__c bookrec = [SELECT Id,Name__c,nihrm__BookingContact__r.Name,nihrm__BookingContact__r.Phone,Number_Of_Guests__c,Access_For_Setup__c from nihrm__Booking__c where id=:recordId ];
            System.debug('bookRec==>>'+bookRec);
            return bookrec;
        }catch(Exception e){
            System.debug('Error  '+e.getMessage() + ' && Line '+e.getLineNumber());
        }
        return null;
        
    }
    @AuraEnabled
    public static nihrm__Booking__c getUpdateBookingRec(string recordId,nihrm__Booking__c bookingRec){//,Time accessTime
        try{
            
            bookingRec.id = recordId;
           // Time accessTime = Time.newInstance(hour, minutes, seconds, milliseconds);
          //  bookingRec.Access_For_Setup__c = accessTime;
            update bookingRec;
            System.debug('bookingRec==>>'+bookingRec);
            return bookingRec;
        }Catch(Exception e){
            System.debug('Error  '+e.getMessage() + ' && Line '+e.getLineNumber());
        }
        return null;
    }
    
}