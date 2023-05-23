@isTest
public class TestAddorRemoveRowController {

     static testmethod void upsertAndDeleteGroupSeriesRatesRecordTest(){
         
         List<Group_Series_Rates__c> grpserieslist = new List<Group_Series_Rates__c> ();
         List<String> deletegrpserieslist = new List<String> ();
         Property_Standard_Price__c propertyStdPrice = new Property_Standard_Price__c();
         
         Account objAccount = new Account(Name = 'Test Acc1', 
                                          Phone = '123456');
         
         insert objAccount;
         
         Opportunity objOpp = new Opportunity(Name = 'Test Opp', AccountId = objAccount.Id, StageName = 'Proposed', CloseDate = Date.today()+1);
         insert objOpp;
         
         Group_Series_Rates__c gsr = new Group_Series_Rates__c(Opportunity__c = objOpp.Id, Tour_Code__c = 'T21', Date_From__c = System.today() + 5, 
                                                               Date_To__c = System.today() + 10, Rooms__c = '2');
         insert gsr;
         grpserieslist.add(gsr);
         deletegrpserieslist.add(gsr.Id);
         Property_Standard_Price__c psp = new Property_Standard_Price__c
             (Opportunity__c = objOpp.Id, Property__c = 'Berkshire', Standard_Price_For_Double_Twin_Double__c = 300,
              Standard_Price_For_Double_Twin_Single__c = 200, Standard_Price_For_Triple_Room_2_Adult__c = 400, 
              Standard_Price_For_Triple_Room_3_Adults__c = 500);
         
         insert psp;
         
         AddorRemoveRowController.upsertAndDeleteGroupSeriesRatesRecord(grpserieslist, deletegrpserieslist, psp);
        
    }
}