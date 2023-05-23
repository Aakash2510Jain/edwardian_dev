@isTest
public class BatchOnIndividualEmailResultTest {
    
    public Static testMethod void testBatchOnIndividualEmailResultTest(){
        Account acc =new Account(Name='Test',Type='Account',Industry=' Financial',Region__c='GBR',Phone='1234567890',Website='http://www.abcfinancial.co.uk/',Account_Status__c=' Prospect');
        insert acc;
        Contact con = new Contact(lastName = 'test',AccountId = acc.id,Position_valueset__c='Area Director',Contact_Type__c= 'Events Company',Decision_Maker__c='No',Phone='1234567890',Email ='test@gmail.com',Customer_Status__c= 'Warm Prospect',Gender__c= 'Male',Description = 'Test',LeadSource =' Airline');
        insert con;
        
        et4ae5__IndividualEmailResult__c evt = new et4ae5__IndividualEmailResult__c();
        evt.Name = 'test';
        evt.et4ae5__Contact__c = con.id;
        insert evt;
        et4ae5__IndividualEmailResult__c testAccount = [SELECT Id FROM et4ae5__IndividualEmailResult__c LIMIT 1];
        Test.setCreatedDate(testAccount .Id, System.now().addDays(-100));
        test.startTest();
        BatchOnIndividualEmailResult obj = new BatchOnIndividualEmailResult();
        DataBase.executeBatch(obj); 
        test.stopTest();
    }
}