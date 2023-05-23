@isTest
public class TestCSVFileUploaderController {
    
    public static String fileData = 'Hotel Name,Tour Code,Date From,Date To,Rooms,Overwrite Standard Price,Double/Twin Single Occupancy,Double/Twin Double Occupancy,Triple Room 2 Adults + 1 Child(0-12 yrs),Triple Room 3 Adults\r\nGrafton,tr123,2022-11-11,2022-12-11,10,TRUE,2450,2200,1200,1350\r\nBerkshire,tr124,2022-11-11,2022-12-11,11,FALSE,,,,\r\n';
    
    static testmethod void processDataTest(){
        
        List<Group_Series_Rates__c> grpserieslist = new List<Group_Series_Rates__c> ();
        List<String> deletegrpserieslist = new List<String> ();
        //Property_Standard_Price__c propertyStdPrice = new Property_Standard_Price__c();
        
        Account objAccount = new Account(Name = 'Test Acc1', 
                                          Phone = '123456');
        
        insert objAccount;
        
        Opportunity objOpp = new Opportunity(Name = 'Test Opp', AccountId = objAccount.Id, StageName = 'Proposed', Properties__c = 'Berkshire;Grafton', CloseDate = Date.today()+1);
        insert objOpp;
        
        Property_Standard_Price__c psp = new Property_Standard_Price__c
            (Opportunity__c = objOpp.Id, Property__c = 'Berkshire', Standard_Price_For_Double_Twin_Double__c = 300,
             Standard_Price_For_Double_Twin_Single__c = 200, Standard_Price_For_Triple_Room_2_Adult__c = 400, 
             Standard_Price_For_Triple_Room_3_Adults__c = 500);
        
        insert psp;
        update objOpp;
        
        Group_Series_Rates__c gsr = new Group_Series_Rates__c(Opportunity__c = objOpp.Id, Hotel__c = 'Berkshire',Tour_Code__c = 'T21', Date_From__c = System.today() + 5, 
                                                              Date_To__c = System.today() + 10, Rooms__c = '2', Overwrite_Standard_Price__c = false, Double_Twin_Single_Occupancy__c = null,
                                                             Double_Twin_Double_Occupancy__c = null, Triple_Room_2_Adults_1_Child__c = null, Triple_Room_3_Adults__c = null);
        insert gsr;
        grpserieslist.add(gsr);
        deletegrpserieslist.add(gsr.Id);
        
        List<String> StringList = new List<String>();
        StringList.add('Hotel Name');
        StringList.add('Tour Code');
        StringList.add('Date From');
        StringList.add('Date To');
        StringList.add('Rooms');
        StringList.add('Overwrite Standard Price');
        StringList.add('Double/Twin Single Occupancy');
        StringList.add('Double/Twin Double Occupancy');
        StringList.add('Triple Room 2 Adults + 1 Child(0-12 yrs)');
        StringList.add('Triple Room 3 Adults');
        
        CSVFileUploaderController.processData(fileData, 'Group_Series_Rates__c' , StringList, objOpp.Id);
        
    }
    
    
}