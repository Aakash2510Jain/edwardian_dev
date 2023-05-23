@isTest
public class ExampleBatchTest {

    /*
    public Static testMethod void Testdata(){
       Account acc =new Account(Name='Test',Type='Account',Industry=' Financial',Region__c='GBR',Phone='1234567890',Website='http://www.abcfinancial.co.uk/',Account_Status__c=' Prospect');
        insert acc;
        Contact con = new Contact(lastName = 'test',AccountId = acc.id,Position_valueset__c='Area Director',Contact_Type__c= 'Events Company',Decision_Maker__c='No',Phone='1234567890',Email ='test@gmail.com',Customer_Status__c= 'Warm Prospect',Gender__c= 'Male',Description = 'Test',LeadSource =' Airline');
        insert con;
        List<Archived_Individual_Email_Result__b> objList = new List<Archived_Individual_Email_Result__b>();
         Archived_Individual_Email_Result__b evt = new Archived_Individual_Email_Result__b();
        evt.Contact__c =con.id;
        evt.Contact_CurrentTimeInstance__c = String.valueOf(system.now());
        objList.add(evt);
        if( !Test.isRunningTest() ){
             database.insertImmediate(objList);
        }
        
       // database.insertImmediate(objList);
        
        test.startTest();
         ExampleBatch obj = new ExampleBatch();
        DataBase.executeBatch(obj); 
        ExampleBatch.mytest();
        test.stopTest();
        
    }
 */
}