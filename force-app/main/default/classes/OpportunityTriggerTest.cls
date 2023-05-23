@isTest
private class OpportunityTriggerTest {
    @isTest static void testUpdateContractDatesStart() {

        Opportunity opp = [
            SELECT Id, Pricebook2Id, Pricebook2.Name,  Proposed_Contract_Start_Date__c, Proposed_Contract_End_Date__c,
                (SELECT Id FROM OpportunityLineItems)
            FROM Opportunity LIMIT 1];

        opp.Proposed_Contract_Start_Date__c =  opp.Proposed_Contract_Start_Date__c.addDays(5);

        Test.startTest();
        Database.SaveResult result = Database.update(opp, false);
        Test.stopTest();

        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals('Cannot change contract dates for opportunity with related products. Please, remove products before changing contract dates.',result.getErrors()[0].getMessage());
    }

    @isTest static void testUpdateContractDatesEnd() {

        Opportunity opp = [
            SELECT Id, Pricebook2Id, Pricebook2.Name, Proposed_Contract_Start_Date__c, Proposed_Contract_End_Date__c,
                (SELECT Id FROM OpportunityLineItems)
            FROM Opportunity LIMIT 1];

        opp.Proposed_Contract_End_Date__c =  opp.Proposed_Contract_Start_Date__c.addDays(5);

        Test.startTest();
        Database.SaveResult result = Database.update(opp, false);
        Test.stopTest();

        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals('Cannot change contract dates for opportunity with related products. Please, remove products before changing contract dates.',result.getErrors()[0].getMessage());
    }

    @isTest static void testUpdateOtherFields() {

        Opportunity opp = [
            SELECT Id, Pricebook2Id, Pricebook2.Name, CloseDate, Proposed_Contract_Start_Date__c, Proposed_Contract_End_Date__c,
                (SELECT Id FROM OpportunityLineItems)
            FROM Opportunity LIMIT 1];

        opp.CloseDate =  Date.today().addDays(6);

        Test.startTest();
        Database.SaveResult result = Database.update(opp, false);
        Test.stopTest();

        System.assert(result.isSuccess());
    }



    @TestSetup
    static void makeData(){
        Id roomRecTypeId = [SELECT Id, DeveloperName FROM RecordType WHERE DeveloperName = 'Hotel_Rooms'].Id;

        List<Product2> prods = TestDataFactory.createProducts(roomRecTypeId, 10, true);

        system.debug('Test.getStandardPricebookId()'+Test.getStandardPricebookId());
        List<PricebookEntry> prbEntries = TestDataFactory.createPricebookEntries(Test.getStandardPricebookId(), prods, true);
        Opportunity opp = TestDataFactory.createAccWithOpp();
        
        List<OpportunityLineItem> oppProds = TestDataFactory.createOppProducts(opp, prods);

    }
}