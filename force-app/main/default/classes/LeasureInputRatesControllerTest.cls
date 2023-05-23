@isTest
public with sharing class LeasureInputRatesControllerTest {

    @IsTest
    static void testgetLeisurePricebooks() {
        // GIVEN we have pricebook(s)
        Integer pricebooks = [SELECT COUNT() FROM Pricebook2 WHERE Pricebook_Category__c = 'Leisure'];

        Test.startTest();
        List<Pricebook2> prbs = LeasureInputRatesController.getLeisurePricebooks();
        Test.stopTest();

        System.assertEquals(pricebooks, prbs.size(), 'Retrieved pricebooks did not match expected count');
    }

    @IsTest
    static void testgetInitData() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Schema.DescribeFieldResult f = Product2.Family.getDescribe();
        List<Schema.PicklistEntry> ple = f.getPicklistValues();

        LeasureInputRatesController.OpportunityWrapper oppWrap = LeasureInputRatesController.getInitData(opp.Id);

        System.assertEquals(0, oppWrap.existingProducts.size());
        System.assert(oppWrap.datePeriods.size() > 0);
        System.assertEquals(ple.size(), oppWrap.productFamilies.size());
    }

    @IsTest
    static void testgetInitDataExcep() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        try {
            LeasureInputRatesController.OpportunityWrapper oppWrap = LeasureInputRatesController.getInitData(acc.Id);
        } catch (Exception e) {
            System.assertEquals('Script-thrown exception', e.getMessage());
        }

    }

    @IsTest
    static void testupdateExistingProds() {
        List<OpportunityLineItem> itemEx = [SELECT Id, OpportunityId, Product2Id, Day_of_Week__c, X1_Adult_Price__c FROM OpportunityLineItem LIMIT 2];

        List<OpportunityLineItem> toRemove = new List<OpportunityLineItem>();
        toRemove.add(itemEx[0]);

        List<OpportunityLineItem> toUpdate = new List<OpportunityLineItem>();
        itemEx[1].X1_Adult_Price__c = 9999;
        toUpdate.add(itemEx[1]);

        Test.startTest();
        LeasureInputRatesController.updateExistingProducts(toUpdate, toRemove);
        Test.stopTest();
        List<OpportunityLineItem> afterUpdate = [SELECT Id, OpportunityId, Product2Id, Day_of_Week__c, Quantity FROM OpportunityLineItem];

        System.assertEquals(19, afterUpdate.size());

    }

    @IsTest
    static void testgetLeisureProducts() {
        LeasureInputRatesController.ProductWrapper prodWrap = LeasureInputRatesController.getLeasureProducts(true, Test.getStandardPricebookId(), new List<String>());
        System.assertEquals(10, prodWrap.products.size(), 'Retrieved products did not match expected count');
        System.assertEquals(1, prodWrap.supplements.size(), 'Retrieved supplements did not match expected count');
    }

    @IsTest
    static void testsaveLineItems() {
        OpportunityLineItem itemEx = [SELECT Id, OpportunityId, Product2Id, Day_of_Week__c FROM OpportunityLineItem LIMIT 1];

        OpportunityLineItem oppItem = new OpportunityLineItem(); 
        oppItem.OpportunityId = itemEx.OpportunityId;
        oppItem.Product2Id = itemEx.Product2Id;
        oppItem.Day_of_Week__c = 'Mon - Thu';
        oppItem.X2_Adult_List_Price__c = 300;
        oppItem.X1_Adult_Price__c = 400;
        oppItem.X2_Adult_Price__c = 500;
        oppItem.From_Date__c = Date.today();
        oppItem.To_Date__c = date.today().addDays(30);
        oppItem.Quantity = 500;
        oppItem.TotalPrice = 400;

        List<OpportunityLineItem> toInsert = new List<OpportunityLineItem>();
        toInsert.add(oppItem);

        LeasureInputRatesController.saveLineItems(toInsert);

        List<OpportunityLineItem> afterInsert = [SELECT Id, OpportunityId, Product2Id, Day_of_Week__c, Quantity FROM OpportunityLineItem WHERE Quantity = 500];
        System.assertEquals(1, afterInsert.size());
    }
    
    @IsTest
    static void testUpdateOppPricebook() {
        Opportunity opp = [SELECT Id, Name FROM Opportunity LIMIT 1];
        opp.Name = 'TestChangedName';

        LeasureInputRatesController.updateOpportunityPricebook(opp);

        Opportunity oppAfterUpdate = [SELECT Id, Name FROM Opportunity LIMIT 1];
        System.assertEquals('TestChangedName', oppAfterUpdate.Name);
    }

    @IsTest
    static void testUpdateOppPricebookExcep() {
        Opportunity opp = [SELECT Id, Name, AccountId FROM Opportunity LIMIT 1];
        opp.AccountId = opp.Id;

        try {
            LeasureInputRatesController.updateOpportunityPricebook(opp);
        } catch (Exception e) {
            System.assertEquals('Script-thrown exception', e.getMessage());
        }
    }

    @TestSetup
    static void makeData(){
        Id roomRecTypeId = new SObjectRecordTypes('Product2').getRecordTypeId('Leisure');
        Id supplementsRecTypeId = new SObjectRecordTypes('Product2').getRecordTypeId('Supplement');
        Id oppLeisureRecTypeId = new SObjectRecordTypes('Opportunity').getRecordTypeId('Leisure');

        List<Product2> prods = TestDataFactory.createProducts(roomRecTypeId, 10, true);

        List<Product2> prodsSuppl = TestDataFactory.createProducts(supplementsRecTypeId, 10, true);

        Opportunity opp = TestDataFactory.createAccWithOppRecType(oppLeisureRecTypeId);
        
        List<PricebookEntry> prbEntries = TestDataFactory.createPricebookEntries(Test.getStandardPricebookId(), prods, true);
        List<PricebookEntry> prbEntriesSuppl = TestDataFactory.createPricebookEntries(Test.getStandardPricebookId(), prodsSuppl, true);
        
        List<OpportunityLineItem> oppProds = TestDataFactory.createOppProducts(opp, prods);

    }
}