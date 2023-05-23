@isTest
public class SchedulableBatchObjectTest {
    
    public Static testMethod void testScheduleClass(){
        Test.StartTest();
        SchedulableBatchObject sh1 = new SchedulableBatchObject();
        
        String sch = '0 0 23 * * ?'; 
        system.schedule('Test Territory Check', sch, sh1); 
        Test.stopTest(); 
    }
    
}