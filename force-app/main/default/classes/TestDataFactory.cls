@SuppressWarnings('PMD')
@isTest
public with sharing class TestDataFactory {

    public static List<Account> generateAccounts(String recordTypeId, Integer countAccs, Boolean isInsert) {
        List<Account> accounts = new List<Account>();

        for (Integer i = 0; i < countAccs; i++) {
            Account acc = new Account(
                Name = 'HSBC Test ' + i,
                Type = 'Company',
                Industry = 'Automotive',
                Phone = '080040050' + i,
                Website = 'www.test' + i + '.com',
                Account_Status__c = 'Active Customer',
                RecordTypeId = recordTypeId
            );
            accounts.add(acc);
        }
        if (isInsert) {
            insert accounts;
        }
        return accounts;
    }

    public static List<Account> generatePersonAccounts(Integer countAccs, Boolean isInsert) {

        Id personAccountRecordId = new SObjectRecordTypes('Account').getRecordTypeId('PersonAccount');
        List<Account> accounts = new List<Account>();

        for (Integer i = 0; i < countAccs; i++) {
            Account acc = new Account(
                FirstName = 'First Name ' + i,
                LastName = 'Last Name ' + i,
                Type = 'Company',
                Industry = 'Automotive',
                Phone = '080040050' + i,
                Website = 'www.test' + i + '.com',
                Account_Status__c = 'Active Customer',
                RecordTypeId = personAccountRecordId
            );
            accounts.add(acc);
        }
        if (isInsert) {
            insert accounts;
        }
        return accounts;
    }

    public static List<Contact> generateContacts(List<Account> accs, Boolean isInsert) {
        List<Contact> contacts = new List<Contact>();

        Integer i = 0;
        for (Account acc : accs) {
            Contact ct = new Contact(
                FirstName = 'John ',
                LastName = 'Jonson ' + i,
                Email = 'John.Jonson' + i + '@test.com',
                Phone = '080040050' +i,
                AccountId = acc.Id,
                Position_valueset__c = 'Consultant',
                Contact_Type__c = 'Private Customer',
                Customer_Status__c = 'Active Customer',
                Gender__c = 'Male',
                pi__url__c = 'www.salesforce.com'
            );
            contacts.add(ct);
            i++;
        }
        if (isInsert) {
            insert contacts;
        }
        return contacts;
    }

    public static List<Campaign> generateCampaigns(Id recordTypeId, Integer countCampaigns, Boolean isInsert) {
        List<Campaign> campaigns = new List<Campaign>();

        for (Integer i = 0; i<countCampaigns; i++) {
            Campaign cmp = new Campaign(
                Name = 'Test Campaign '+i,
                Type = 'Email',
                Status = 'Planned',
                IsActive = true,
                RecordTypeId = recordTypeId,
                StartDate = System.today(),
                EndDate = System.today().addDays(30)
            );
            campaigns.add(cmp);
        }
        if (isInsert) {
            insert campaigns;
        }
        return campaigns;
    }

    public static Campaign_External_Link__c generateCampaignExternalLink(Id campaignId, String rateCode, Boolean isInsert) {

        Campaign_External_Link__c cel = new Campaign_External_Link__c(
            Campaign__c = campaignId,
            Rate_Code__c = rateCode
        );

        if (isInsert) {
            insert cel;
        }
        return cel;
    }

    public static Order generateOrder(Id accountId, Id recordTypeId, Boolean isInsert) {

        Order order = new Order(
            AccountId = accountId,
            Status = 'Draft',
            EffectiveDate = System.today(),
            RecordTypeId = recordTypeId
        );

        if (isInsert) {
            insert order;
        }
        return order;
    }

    public static List<Product2> createProducts(String recTypeId, Integer countProds, Boolean isInsert) {
        List<Product2> prods = new List<Product2>();

        for (Integer i = 0;i<countProds;i++) {
            Product2 room = new Product2(
                Name = 'Room number ' + i,
                IsActive = true,
                ProductCode = 'Room number ' + i,
                RecordTypeId = recTypeId
            );
            prods.add(room);
        }
        if (isInsert) {
            insert prods;
        }
        return prods;
    }

    public static List<PricebookEntry> createPricebookEntries (String pricebookId, List<Product2> prods, Boolean isInsert) {
        List<PricebookEntry> entries = new List<PricebookEntry>();
        for (Product2 prod:prods) {
            entries.add(new PricebookEntry(Product2Id = prod.Id,Pricebook2Id = pricebookId, UnitPrice = 100, X2_Adult_List_Price__c = 200, IsActive = true));
        }
        if (isInsert) {
            insert entries;
        }
        return entries;
    }

    public static Opportunity createAccWithOpp () {
        Account acc = new Account(Name = 'Test acc');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'TestOpportunity',
            Rate_Plan__c = 'Static',
            Pricing_Structure__c = 'Seasonal',
            AccountId = acc.Id,
            StageName = 'Proposed',
            CloseDate = Date.today().addYears(1),
            Proposed_Contract_Start_Date__c = Date.today(),
            Proposed_Contract_End_Date__c = Date.today().addMonths(3),
            Pricebook2Id = Test.getStandardPricebookId());
        insert opp;

        return opp;
    }

    public static Opportunity createAccWithOppRecType (Id recTypeId) {
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Agency').getRecordTypeId();
        Account acc = new Account(Name = 'Test acc', RecordTypeId = recordTypeId);
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'TestOpportunity',
            AccountId = acc.Id,
            Rate_Plan__c = 'Static',
            Pricing_Structure__c = 'Seasonal',
            StageName = 'Proposed',
            CloseDate = Date.today().addYears(1),
            Proposed_Contract_Start_Date__c = Date.today(),
            Proposed_Contract_End_Date__c = Date.today().addMonths(3),
            Pricebook2Id = Test.getStandardPricebookId(),
            RecordTypeId = recTypeId);
        insert opp;
        return opp;
    }

    public static List<OpportunityLineItem> createOppProducts(Opportunity opp, List<Product2> prods) {
        List<OpportunityLineItem> oppLines = new List<OpportunityLineItem>();
        for (Product2 prod: prods) {
            OpportunityLineItem oppItem = new OpportunityLineItem();
            oppItem.OpportunityId = opp.Id;
            oppItem.Product2Id = prod.Id;
            oppItem.Day_of_Week__c = 'Fri - Sun';
            oppItem.X2_Adult_List_Price__c = 300;
            oppItem.X1_Adult_Price__c = 400;
            oppItem.X2_Adult_Price__c = 500;
            oppItem.From_Date__c = Date.today();
            oppItem.To_Date__c = date.today().addDays(30);
            oppItem.Quantity = 1;
            oppItem.TotalPrice = 400;

            OpportunityLineItem oppItem2 = new OpportunityLineItem();
            oppItem2.Day_of_Week__c = 'Fri - Sun';
            oppItem2.OpportunityId = opp.Id;
            oppItem2.Product2Id = prod.Id;
            oppItem2.X2_Adult_List_Price__c = 300;
            oppItem2.X1_Adult_Price__c = 400;
            oppItem2.X2_Adult_Price__c = 500;
            oppItem2.From_Date__c = Date.today().addDays(30);
            oppItem2.To_Date__c = date.today().addDays(45);
            oppItem2.Quantity = 1;
            oppItem2.TotalPrice = 400;

            oppLines.add(oppItem);
            oppLines.add(oppItem2);
        }

        insert oppLines;

        return oppLines;
    }

    public static List<Sales_Target__c> createSalesTargets(List<Account> accounts, Property__c hotel, Boolean isInsert) {
        List<Sales_Target__c> salesTargetsToInsert = new List<Sales_Target__c>();

        final List<String> revenueValue = TestDataFactory.getPickListValues('Actual_Revenue_Status__c');
        final String regionsValue = TestDataFactory.getPickListAPIValues('Regions__c')[0];
        final String marketingValue = TestDataFactory.getPickListValues('Market_Segments__c')[0];
        final String periodsValue = TestDataFactory.getPickListValues('Period__c')[0];
        final String targetPeriodValue = TestDataFactory.getPickListValues('Target_Period__c')[0];

        for (Integer i = 0; i < accounts.size(); i++) {
            salesTargetsToInsert.add(
                new Sales_Target__c(
                    Name = 'Test Sales Target ' + i,
                    Sales_Person__c = UserInfo.getUserId(),
                    Actual_Revenue_Status__c = revenueValue[0],
                    Pipeline_Revenue_Status__c = revenueValue[1],
                    Account_based_Target__c = true,
                    All_Hotels__c = false,
                    Regional_Target__c = true,
                    Regions__c = regionsValue,
                    Market_Segments__c = marketingValue,
                    Hotel__c = hotel.Id,
                    Target_Period__c = targetPeriodValue,
                    Year__c = String.valueOf(Date.Today().year() + 1),
                    Pipeline_Revenue_Target__c = 11,
                    Actual_Revenue_Target__c = 11,
                    Period__c = periodsValue,
                    Account__c = accounts[i].Id
                )
            );
        }

        if(isInsert) {
            insert salesTargetsToInsert;
        }

        return salesTargetsToInsert;

    }

    public static List<String> getPickListValues(String fieldName){
        List<String> pickListValues = new List<String>();
        Schema.DescribeFieldResult fieldResult = Schema.SObjectType.Sales_Target__c.fields.getMap().get(fieldName).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry pickListVal : ple) {
            pickListValues.add(pickListVal.getLabel());
        }
        return pickListValues;
    }

    public static List<String> getPickListAPIValues(String fieldName) {

        List<String> pickListValues = new List<String>();
        Schema.DescribeFieldResult fieldResult = Schema.SObjectType.Sales_Target__c.fields.getMap().get(fieldName).getDescribe();

        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry pickListVal : ple) {
            pickListValues.add(pickListVal.getValue());
        }

        return pickListValues;
    }

    public static List<Property__c> createProperties(Integer count, Boolean isInsert) {
        List<Property__c> propertiesToInsert = new List<Property__c>();
        for(Integer i = 0; i < count; i++) {
            propertiesToInsert.add(new Property__c(
                Name = 'Test Property ' + i,
                Is_Active__c = true,
                Hotel_ID__c = '001'
            ));
        }
        if(isInsert) {
            insert propertiesToInsert;
        }
        return propertiesToInsert;
    }

    public static List<Gift__c> createGifts(Integer count, Boolean isInsert, Property__c property) {
        List<Gift__c> giftsToInsert = new List<Gift__c>();
        for(Integer i = 0; i < count; i++) {
            giftsToInsert.add(new Gift__c(
                Name = 'Test Gift ' + i,
                Price__c = 1,
                Category__c = 'Grade 1',
                Hotels__c = property.Hotel_ID__c
            ));
        }
        if(isInsert) {
            insert giftsToInsert;
        }
        return giftsToInsert;
    }

    public static Financial_Period__c createFinancialPeriod(Boolean isInsert) {
        Financial_Period__c financialPeriodToInsert = new Financial_Period__c(
            Name = 'Test Period',
            Financial_Period_Start_Date__c = Date.newInstance(2021, 01, 1),
            Financial_Period_End_Date__c = Date.newInstance(2021, 01, 31)
        );
        if(isInsert) {
            insert financialPeriodToInsert;
        }
        return financialPeriodToInsert;
    }

    public static Budget__c createBudget(Property__c property, Financial_Period__c financialPeriod, Boolean isInsert) {
        Budget__c budgetToInsert = new Budget__c(
            Name = 'Test Budget',
            Financial_Period__c = financialPeriod.Id,
            Hotel__c = property.Id,
            Budget__c = 100
        );
        if(isInsert) {
            insert budgetToInsert;
        }
        return budgetToInsert;
    }

    public static Gift_Allocation__c createGiftAllocation(Order order, Budget__c budget, Boolean isInsert) {
        Gift_Allocation__c giftAllocationToInsert = new Gift_Allocation__c(
            Booking__c = order.Id,
            Budget__c = budget.Id,
            Total_Price__c = 10
        );
        if(isInsert) {
            insert giftAllocationToInsert;
        }
        return giftAllocationToInsert;
    }

    public static List<Gift_Allocation_Line_Item__c> createGiftAllocationLineItems(Gift_Allocation__c giftAllocation, List<Gift__c> gifts, Boolean isInsert) {
        List<Gift_Allocation_Line_Item__c> giftAllocationLineItemsToInsert = new List<Gift_Allocation_Line_Item__c>();
        for(Gift__c gift: gifts) {
            giftAllocationLineItemsToInsert.add(new Gift_Allocation_Line_Item__c(
                Gift_Allocation__c = giftAllocation.Id,
                Gift_Name__c = gift.Id,
                Status__c = 'Pending',
                Quantity__c = 1
            ));
        }
        if(isInsert) {
            insert giftAllocationLineItemsToInsert;
        }
        return giftAllocationLineItemsToInsert;
    }

    public static List<Always_Allocate_Gift_Item__c> createAlwaysAllocateGiftItems(List<Gift__c> gifts, Boolean isInsert, Account account) {
        List<Always_Allocate_Gift_Item__c> alwaysAllocateGiftItemsToInsert = new List<Always_Allocate_Gift_Item__c>();
        for(Gift__c gift: gifts) {
            alwaysAllocateGiftItemsToInsert.add(new Always_Allocate_Gift_Item__c(
                Gift_Name__c = gift.Id,
                Guest_Name__c = account.Id,
                Quantity__c = 1
            ));
        }
        if(isInsert) {
            insert alwaysAllocateGiftItemsToInsert;
        }
        return alwaysAllocateGiftItemsToInsert;
    }
}