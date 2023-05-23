/**
* @author [Dinesh Baddawar]
* @email dinesh.b@utilitarianLab.com
* @create date 2023-04-17 13:29:09
* @modify date 2023-04-17 13:29:09
* @desc [description]
*/

@isTest
public with sharing class BigObjectAuraHelperTest {
    
    // public Static testMethod void testBigObjectAuraHelperMethod(){
    //     Account acc =new Account(Name='Test',Type='Account',Industry=' Financial',Region__c='GBR',Phone='1234567890',Website='http://www.abcfinancial.co.uk/',Account_Status__c=' Prospect');
    //     insert acc;
    //     Contact con = new Contact(lastName = 'test',AccountId = acc.id,Position_valueset__c='Area Director',Contact_Type__c= 'Events Company',Decision_Maker__c='No',Phone='1234567890',Email ='test@gmail.com',Customer_Status__c= 'Warm Prospect',Gender__c= 'Male',Description = 'Test',LeadSource =' Airline');
    //     insert con;
    //     Archived_Individual_Email_Result__b big = new Archived_Individual_Email_Result__b();
    //     big.Contact__c = con.id;
    //     big.Contact_CurrentTimeInstance__c = con.Id +'_'+System.now();
    //     if( !Test.isRunningTest() )
    //     {
    //         database.insertImmediate(big);
    //     }
        
        
    //     et4ae5__IndividualEmailResult__c evt = new et4ae5__IndividualEmailResult__c();
    //     evt.Name = 'test';
    //     evt.et4ae5__Contact__c = con.id;
    //     insert evt;
        
    //     //Assuming your Test has already inserted an Account
    //     et4ae5__IndividualEmailResult__c testAccount = [SELECT Id FROM et4ae5__IndividualEmailResult__c LIMIT 1];
        
    //     //We can set the CreatedDate of testAccount to the current time negative 10 days.
    //     Test.setCreatedDate(testAccount .Id, System.now().addDays(-100));
        
    //     test.startTest();
    //     BigObjectAuraHelper.getContacRelatedBigObjectsForAura(con.AccountId);
    //     BigObjectAuraHelper.getContacRelatedBigObjectsForAura(con.Id);
    //     BigObjectAuraHelper.getObjecForRelatedContact(con.AccountId);
    //     BigObjectAuraHelper.getObjecForRelatedContact(con.Id);
    //     BatchOnIndividualEmailResult obj = new BatchOnIndividualEmailResult();
    //     DataBase.executeBatch(obj); 
    //     test.stopTest();
    // }
    
}