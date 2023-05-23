@isTest
private class RemoveAllProductsControllerTest {
    @isTest 
    static void testgetItems() {
        Opportunity opp = [
            SELECT Id, Pricebook2Id, Pricebook2.Name, Proposed_Contract_Start_Date__c, Proposed_Contract_End_Date__c,
                (SELECT Id FROM OpportunityLineItems)
            FROM Opportunity LIMIT 1];

        List<OpportunityLineItem> oppItems = RemoveAllProductsController.getItems(opp.Id);

        System.assertEquals(opp.OpportunityLineItems.size(), oppItems.size());
    }

    @isTest 
    static void testRemoveAllProds() {

        Opportunity opp = [
            SELECT Id, Pricebook2Id, Pricebook2.Name, Proposed_Contract_Start_Date__c, Proposed_Contract_End_Date__c,
                (SELECT Id FROM OpportunityLineItems)
            FROM Opportunity LIMIT 1];

        List<OpportunityLineItem> oppItems = opp.OpportunityLineItems;

        RemoveAllProductsController.removeAllItems(oppItems);

        Opportunity opp2 = [SELECT Id, Pricebook2Id, Pricebook2.Name, Proposed_Contract_Start_Date__c, Proposed_Contract_End_Date__c,
                                (SELECT Id FROM OpportunityLineItems)
                            FROM Opportunity LIMIT 1];


        System.assertEquals(0, opp2.OpportunityLineItems.size());
    }

    @TestSetup
    static void makeData(){
        Id roomRecTypeId = [SELECT Id, DeveloperName FROM RecordType WHERE DeveloperName = 'Hotel_Rooms'].Id;

        List<Product2> prods = TestDataFactory.createProducts(roomRecTypeId, 10, true);
        Opportunity opp = TestDataFactory.createAccWithOpp();

        List<PricebookEntry> prbEntries = TestDataFactory.createPricebookEntries(Test.getStandardPricebookId(), prods, true);
        
        List<OpportunityLineItem> oppProds = TestDataFactory.createOppProducts(opp, prods);
    }
}