@isTest
public class TriggerOnTaskHelperTest {
    
    @isTest
    Public  static void triggertest() {
        try{
                
            Task taskrec = new Task();
            taskrec.Subject = 'Chase deposit';
            insert taskrec;
            
        }
        catch(exception e){
            system.debug('the error has ocuured due to - ' + e.getMessage());
            system.debug('the error at line - ' + e.getLineNumber());
        }
    }
    
    @isTest
    Public  static void triggerOnTaskHelperMethod() {
        try{
            
           TriggerOnTaskHelper.updateBookingDate();
            
        }
        catch(exception e){
            system.debug('the error has ocuured due to - ' + e.getMessage());
            system.debug('the error at line - ' + e.getLineNumber());
        }
    } 
}