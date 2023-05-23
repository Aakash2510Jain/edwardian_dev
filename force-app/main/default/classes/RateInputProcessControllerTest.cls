@isTest
public with sharing class RateInputProcessControllerTest {

    @IsTest
    static void testgetFilteredPricebooks() {
        // GIVEN we have pricebook(s)
        Integer pricebooks = [SELECT count() FROM Pricebook2];

        Test.startTest();
        List<Pricebook2> prbs = RateInputProcessController.getFilteredPricebooks('');
        Test.stopTest();

        System.assertEquals(pricebooks, prbs.size(), 'Retrieved pricebooks did not match expected count');
    }

    @IsTest
    static void testgetProductFamily() {

        Schema.DescribeFieldResult f = Product2.Family.getDescribe();
        List<Schema.PicklistEntry> ple = f.getPicklistValues();
        
        List<RateInputProcessController.PicklistWrapper> families = RateInputProcessController.getProductFamily();
        System.assertEquals(ple.size(), families.size(), 'Retrieved families did not match expected count');
    }

    @IsTest
    static void testgetInitData() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        RateInputProcessController.OpportunityWrapper oppWrap = RateInputProcessController.getInitData(opp.Id);

        System.assertEquals(10, oppWrap.existingProducts.size());
        System.assertEquals(4, oppWrap.datePeriods.size());
    }

    @IsTest
    static void testgetAllProducts() {
        List<Pricebook2> pricebooks = [SELECT Id, Name, IsStandard FROM Pricebook2 ORDER BY Name ];
        List<PricebookEntry> allProds = RateInputProcessController.getAllProducts(true, Test.getStandardPricebookId(), new List<String>());
        System.assertEquals(10, allProds.size());
    }

    @IsTest
    static void testsaveLineItems() {
        List<Pricebook2> pricebooks = [SELECT Id, Name, IsStandard FROM Pricebook2 ORDER BY Name ];
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
        oppItem.Quantity = 145;
        oppItem.TotalPrice = 400;

        List<OpportunityLineItem> toInsert = new List<OpportunityLineItem>();
        toInsert.add(oppItem);

        RateInputProcessController.saveLineItems(toInsert);

        List<OpportunityLineItem> afterInsert = [SELECT Id, OpportunityId, Product2Id, Day_of_Week__c, Quantity FROM OpportunityLineItem WHERE Quantity = 145];
        System.assertEquals(1, afterInsert.size());
    }

    @IsTest
    static void testupdateExistingProds() {
        List<OpportunityLineItem> itemEx = [SELECT Id, OpportunityId, Product2Id, Day_of_Week__c FROM OpportunityLineItem LIMIT 2];

        List<RateInputProcessController.ExistingProductWrapper> wrapList = new List<RateInputProcessController.ExistingProductWrapper>();

        RateInputProcessController.ExistingProductWrapper wrap1 = new RateInputProcessController.ExistingProductWrapper();
        wrap1.productName = 'Test1';
        wrap1.daysOfWeek = 'Mon - Thu';
        wrap1.productId = itemEx[0].Product2Id;
        wrap1.toRemove = false;
        wrap1.prodList = new List<OpportunityLineItem>();
        wrap1.prodList.add(itemEx[0]);

        wrapList.add(wrap1);

        RateInputProcessController.ExistingProductWrapper wrap2 = new RateInputProcessController.ExistingProductWrapper();
        wrap2.productName = 'Test1';
        wrap2.daysOfWeek = 'Mon - Thu';
        wrap2.productId = itemEx[1].Product2Id;
        wrap2.toRemove = true;
        wrap2.prodList = new List<OpportunityLineItem>();
        wrap2.prodList.add(itemEx[1]);

        wrapList.add(wrap2);

        RateInputProcessController.updateExistingProducts(wrapList);

        List<OpportunityLineItem> afterUpdate = [SELECT Id, OpportunityId, Product2Id, Day_of_Week__c, Quantity FROM OpportunityLineItem];
        System.assertEquals(19, afterUpdate.size());

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