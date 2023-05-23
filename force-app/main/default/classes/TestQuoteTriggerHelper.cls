@isTest
public class TestQuoteTriggerHelper {
    
    
    static testMethod void approvalProcessHandlerTest() {
        
        
        Profile profileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User usr = new User(LastName = 'LIVESTON',
                            FirstName='JASON',
                            Alias = 'jliv',
                            Email = 'jason.liveston@asdf.com',
                            Username = 'jason.liveston@asdf.com',
                            ProfileId = profileId.id,
                            TimeZoneSidKey = 'GMT',
                            LanguageLocaleKey = 'en_US',
                            EmailEncodingKey = 'UTF-8',
                            LocaleSidKey = 'en_US'
                           );
        
        
        List<Id> userIds = new List<Id>();
        userIds.add(usr.Id);        
        
        //Account Object Creation
        Account objAccount = new Account(Name = 'Test Acc1', BillingStreet = 'Test Street', Phone = '123456');
        
        insert objAccount;
        
        //Opp object Creation
        Opportunity objOpp = new Opportunity(Name = 'Test Opp', AccountId = objAccount.Id, StageName = 'Proposed', CloseDate = Date.today()+1);
        insert objOpp;
        
        //Quote Object Creation
        Quote quoteobj = new Quote( Name = 'Test', Company_Commitment__c = 'Mirror the Company Commitment Volume opportunity field at the time of sync', Company_Commitment_Review_Picklist__c = 'Monthly', 
                                   RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByName().get('Group Series').getRecordTypeId(),
                                   Cancellation_Policy__c  = '48 hrs', OpportunityId = objOpp.Id);
        insert quoteobj; 
        Quote quoteobj1 = new Quote( Name = 'Test1', Company_Commitment__c = 'Mirror the Company Commitment Volume opportunity field at the time of sync', Company_Commitment_Review_Picklist__c = 'Monthly', 
                                    Cancellation_Policy__c  = '48 hrs', OpportunityId = objOpp.Id);
        insert quoteobj1; 
        
        List<Quote> quoteList = new List<Quote>();
        quoteList.add(quoteobj);
        quoteList.add(quoteobj1);
        
        Approval.ProcessSubmitRequest req =     new Approval.ProcessSubmitRequest();
        req.setComments('Submitting request for approval via form');
        req.setObjectId(quoteobj.Id);
        req.setSubmitterId(usr.Id);
        
        Approval.ProcessResult result = Approval.process(req);
        Approval.ProcessWorkitemRequest request = new Approval.ProcessWorkitemRequest();
        request.setComments('Approving request.');
        request.setAction('Approve');
        
        QuoteTriggerHelper.approvalProcessHandler(quoteList);
        
    }
}