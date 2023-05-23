@isTest  
public class TestDocumentGenerationUsingConga {
    
    public static testMethod  void generateAccount() {
        String recId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Agency').getRecordTypeId();
        String opprecId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Group Series').getRecordTypeId();
        
        APXTConga4__Conga_Template__c apexCongatemp = new APXTConga4__Conga_Template__c();
        apexCongatemp.APXTConga4__Key__c = 'Test_Key';
        insert apexCongatemp;
        
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='shubham', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='bjorn@testorg.com');
        insert u;
        Account acc = new Account(Name = 'HSBC Test',Type = 'Company',Industry = 'Automotive',Phone = '080040050',Website = 'www.test.com',
                                  Account_Status__c = 'Active Customer',RecordTypeId = recId);
        insert acc;
        
        Opportunity O = New Opportunity();
        O.Name = 'Test - KalleAnka';
        O.RecordTypeId = opprecId;
        O.Type = 'New Buisness';
        O.AccountId = acc.Id;
        O.CloseDate = Date.today().addDays(4);
        O.StageName = 'Agreement';
        Insert O;
        
        Contact Con = New Contact();
        Con.AccountId = acc.Id;
        Con.LastName = 'Carlsson';
        Insert Con;
        
        Contract C = New Contract();
        C.AccountId = acc.Id;
        c.Contract_Type__c = 'Corporate LRA';
        c.Londoner_only__c = true;
        C.Status = 'Draft';
        C.Opportunity__c = O.Id;
        C.StartDate = Date.today();
        C.ContractTerm = 2;
        c.Is_Primary_Contact_Selected__c = false;
        c.is_primary_user_selected__c = false;
        c.is_secondary_contact_selected__c = false;
        c.is_secondary_user_selected__c = false;
        Insert C;
        
        List<CongaCompWrapper> CongaCompWrapperUserList = new List<CongaCompWrapper>();
        List<CongaCompWrapper> CongaCompWrapperConList = new List<CongaCompWrapper>();
        
        CongaCompWrapper ccw = new CongaCompWrapper();
        ccw.conId = Con.Id;
        ccw.conName = 'Carlsson';
        ccw.type = 'Signer';
        ccw.sequence = 1;
        CongaCompWrapperConList.add(ccw);
        
        CongaCompWrapper ccw2 = new CongaCompWrapper();
        ccw2.conId = u.Id;
        ccw2.conName = 'shubham';
        ccw2.type = 'Signer';
        ccw2.sequence = 1;
        CongaCompWrapperUserList.add(ccw2);
        
        List<CongaCompWrapper> CongaCompWrapperList = new List<CongaCompWrapper>();
        CongaCompWrapperList.add(ccw);        
        CongaCompWrapperList.add(ccw2);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CongaMockHttpResponseGenerator());
        test.stopTest();
        
        DocumentGenerationUsingConga.GenerateDocument(C.Id);
        DocumentGenerationUsingConga.fetchUserDataforConga('user','Name','shubham','',C.Id); 
        DocumentGenerationUsingConga.fetchUserDataforConga('user','Name','test','',C.Id);
        DocumentGenerationUsingConga.fetchAllContactsFromContract(C.Id);
        DocumentGenerationUsingConga.GenerateDocumentAndSendForSignature(C.Id,CongaCompWrapperUserList,CongaCompWrapperConList,CongaCompWrapperList);
        CongaHelperToolLightning.getSessionId(u.LastName , 'pass');
        CongaHelperToolLightning.getReportName('test','test','test');
        CreateNewBusinessCtrl.getBuisnessRecordTypeId(O.Id);
    }
    
    
}