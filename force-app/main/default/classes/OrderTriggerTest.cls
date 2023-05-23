/**
 * @author Vasile Fana <vasile.fana@cloudshiftgroup.com>
 * @date 2020-12-04
 * @group CloudShiftGroup
 * @description  This is a system test class for order trigger. 
 *
 * Date          author             Change Description
 * -----------------------------------------------------------------------------------
 * 2020-12-04    Vasile Fana       Created Class
 * 2021-04-07    Andrei Budescu    Test Methods for Notifications M&E and VIP 
 * 2021-04-21    Andrei Budescu    Add lines to test the new implementations for after Update and Insert
 */
@SuppressWarnings('PMD.ApexUnitTestMethodShouldHaveIsTestAnnotation,PMD.ApexUnitTestClassShouldHaveAsserts')
@IsTest
private class OrderTriggerTest {
    private static final Id ACCOUNT_COMPANY_RT_ID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Company').getRecordTypeId();
    private static final Id CAMPAIGN_B2B_RT_ID = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('B2B Marketing').getRecordTypeId();
    private static final Id ORDER_ROOMS_RT_ID = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Rooms').getRecordTypeId();
    private static final Id ORDER_M_E_RT_ID = Schema.SObjectType.Order.getRecordTypeInfosByName().get('M&E').getRecordTypeId();
    private static final String RATE_CODE = 'AABB';
    private static final String S_CODE = 'SCAA';

    private static final Integer BULK_AMOUNT = 10;

    @TestSetup
    static void makeTestData(){

        List<Account> accs = TestDataFactory.generateAccounts(
            ACCOUNT_COMPANY_RT_ID, 
            BULK_AMOUNT, 
            true
        );

        TestDataFactory.generateContacts(
            accs, 
            true
        );

        List<Campaign> campaigns = TestDataFactory.generateCampaigns(
            CAMPAIGN_B2B_RT_ID, 
            BULK_AMOUNT, 
            true
        );

        List<Campaign_External_Link__c> externalLinks = new List<Campaign_External_Link__c>();

        for (Campaign cmp : campaigns) {
            Campaign_External_Link__c cel = TestDataFactory.generateCampaignExternalLink(
                cmp.Id, 
                RATE_CODE,
                false
            );
            cel.S_Code__c = 'SCAA';
            externalLinks.add(cel);
        }
        System.debug(externalLinks);
        insert externalLinks;
    }

    @IsTest
    private static void verifyCampaignMatchingIdOnOrderInsert() {
        List<Campaign> campaigns = [
            SELECT Id 
            FROM Campaign
        ];
        Contact contact = [
            SELECT Id, AccountId 
            FROM Contact 
            Limit 1
        ];
        List<Account> accs = [
            SELECT Id
            FROM Account
            Limit 3
        ];

        assertNullCampaignMembersAndInfluencedRoomBookings(
            campaigns
        );

        Order order = TestDataFactory.generateOrder(
            contact.AccountId, 
            ORDER_ROOMS_RT_ID, 
            false
        );
        order.Contact_Name__c = contact.Id;
        order.Rate_Code__c = RATE_CODE;
        order.S_Code__c = S_CODE;
        order.PMS_Company__c = accs[0].Id;
        order.PMS_Source__c = accs[1].Id;
        order.PMS_Agent__c = accs[2].Id;
        order.Update_Date__c = System.now();

        Test.startTest();
        insert order;
        Test.stopTest();

        assertCreatedCampaignMembersAndInfluencedRoomBookings(
            campaigns, 
            new List<Order>{order},
            new List<Contact>{contact}
        );
    }

    @IsTest
    private static void verifyCampaignMatchingIdOnOrderInsertBulk() {
        List<Campaign> campaigns = [
            SELECT Id 
            FROM Campaign
        ];
        List<Contact> contacts = [
            SELECT Id, AccountId 
            FROM Contact 
        ];

        List<Order> orders = new List<Order>();
        for (Contact ct : contacts) {
            Order order = TestDataFactory.generateOrder(
                ct.AccountId, 
                ORDER_ROOMS_RT_ID, 
                false
            );
            order.Contact_Name__c = ct.Id;
            order.Rate_Code__c = RATE_CODE;
            order.S_Code__c = S_CODE;
            order.Update_Date__c = System.now();

            orders.add(order);
        }

        assertNullCampaignMembersAndInfluencedRoomBookings(
            campaigns
        );

        Test.startTest();
        insert orders;
        Test.stopTest();

        assertCreatedCampaignMembersAndInfluencedRoomBookings(
            campaigns, 
            orders,
            contacts
        );
    }

    @IsTest
    private static void verifyCampaignMatchingIdOnOrderUpdate() {
        List<Campaign> campaigns = [
            SELECT Id 
            FROM Campaign
        ];
        List<Contact> contacts = [
            SELECT Id, AccountId 
            FROM Contact 
        ];

        List<Order> orders = new List<Order>();
        for (Contact ct : contacts) {
            Order order = TestDataFactory.generateOrder(
                ct.AccountId, 
                ORDER_ROOMS_RT_ID, 
                false
            );
            order.Contact_Name__c = ct.Id;
            orders.add(order);
        }
        insert orders;

        assertNullCampaignMembersAndInfluencedRoomBookings(
            campaigns
        );

        for (Order order : orders) {
            order.Rate_Code__c = RATE_CODE;
            order.Update_Date__c = System.now();
            order.Gross_Revenue__c = 1000;
        }
        Test.startTest();
        update orders;
        Test.stopTest();
    }

    @IsTest
    private static void verifyCampaignRematchingIdOnOrderUpdate() {
        List<Campaign> campaigns = [
            SELECT Id 
            FROM Campaign
        ];
        List<Contact> contacts = [
            SELECT Id, AccountId 
            FROM Contact 
        ];

        List<Order> orders = new List<Order>();
        for (Contact ct : contacts) {
            Order order = TestDataFactory.generateOrder(
                ct.AccountId, 
                ORDER_ROOMS_RT_ID, 
                false
            );
            order.Contact_Name__c = ct.Id;
            order.Rate_Code__c = RATE_CODE;
            order.Update_Date__c = System.now();
            orders.add(order);
        }
        insert orders;

        for (Order order : orders) {
            order.Rate_Code__c = 'AAAAA';
            order.Update_Date__c = System.now().addDays(10);
            order.Gross_Revenue__c = 1000;
        }
        Test.startTest();
        update orders;
        Test.stopTest();
    }

    static void assertNullCampaignMembersAndInfluencedRoomBookings(List<Campaign> campaigns) {
        List<CampaignMember> cmpMemebersBefore = [
            SELECT Id 
            FROM CampaignMember 
            WHERE CampaignId 
            IN :campaigns
        ];
        System.assert(
            cmpMemebersBefore.isEmpty(), 
            'No campaign member should have been found but found '+cmpMemebersBefore.size()+'memebrs'
        );

        List<Influenced_Room_Booking__c> influenceRBBefore = [
            SELECT Id 
            FROM Influenced_Room_Booking__c 
            WHERE Campaign__c 
            IN :campaigns
        ];
        System.assert(
            influenceRBBefore.isEmpty(), 
            'No influence records should have been created without an order'
        );
    }

    static void assertCreatedCampaignMembersAndInfluencedRoomBookings(List<Campaign> campaigns, List<Order> orders, List<Contact> contacts) {
        List<CampaignMember> cmpMemebersAfter = [
            SELECT Id 
            FROM CampaignMember 
            WHERE CampaignId 
            IN :campaigns
            AND ContactId 
            IN :contacts
        ];
        System.assert(
            !cmpMemebersAfter.isEmpty(), 
            'Campaign members should have been created after order insert'
        );
        System.assertEquals(
            campaigns.size() * contacts.size(), 
            cmpMemebersAfter.size(), 
            'Incorrect number of campaign members created'
        );

        List<Influenced_Room_Booking__c> influenceRBAfter = [
            SELECT Id, Influence__c
            FROM Influenced_Room_Booking__c 
            WHERE Campaign__c 
            IN :campaigns
            AND Room_Booking__c 
            IN :orders
        ];
        System.assert(
            !influenceRBAfter.isEmpty(), 
            'Influence records should have been created after order insert'
        );
        System.assertEquals(
            campaigns.size() * orders.size(), 
            influenceRBAfter.size(), 
            'Incorrect number of influenced campaign members created'
        );
    }
    
    @IsTest
    private static void testNotificationMEParentCompany(){
        //Create Parent Account Company
        Account accParent = new Account(
            Name = 'Company Parent Test',
            Type = 'Company',
            Industry = 'Automotive',
            Phone = '0800400501',
            Website = 'www.test1.com',
            Account_Status__c = 'Active Customer'
        );
        insert accParent;
        //Create Account Company
        Account acc = new Account(
            Name = 'Company Test',
            Type = 'Company',
            Industry = 'Automotive',
            Phone = '0800400502',
            Website = 'www.test2.com',
            Account_Status__c = 'Active Customer',
            ParentId = accParent.Id
        );
        insert acc;
        System.debug(acc);
        
        //Create Contact
        Contact ct = new Contact(
                FirstName = 'John ',
                LastName = 'Jonson ',
                Email = 'John.Jonson@test.com',
                Phone = '080040050',
                AccountId = acc.Id,
                Position_valueset__c = 'Consultant',
                Contact_Type__c = 'Private Customer',
                Customer_Status__c = 'Active Customer',
                Gender__c = 'Male',
                pi__url__c = 'www.salesforce.com'
            );
        insert ct;
        
        //Create Property
        Property__c p = new Property__c(
            Name = 'Londoner Test Hotel',
            Is_Active__c = true
        );
        insert p;
        
        //Create Order
        Order order = new Order(
            AccountId = acc.Id,
            Contact_Name__c = ct.Id,
            Hotel__c = p.Id,
            Arrival_Date__c = System.today(),
            Length_of_Stay__c = 4,
            Type = 'SPA',
            Room_Revenue__c = 3000,
            Event_Revenue__c = 3000,
            Gross_Revenue__c = 50000,
            Status = 'Draft',
            EffectiveDate = System.today(),
            RecordTypeId = ORDER_M_E_RT_ID
        );
        Test.startTest();
        try{
            insert order;
        }catch(Exception ex) {
            Assert.fail('Should not reach this point.');
        }
        Test.stopTest();
        
    }
    
    @IsTest
    private static void testNotificationMEParentPmsAgent(){
        //Create Parent Account Pms Agent
        Account accParent = new Account(
            Name = 'PMS Parent Test',
            Type = 'Company',
            Industry = 'Automotive',
            Phone = '0800400501',
            Website = 'www.test1.com',
            Account_Status__c = 'Active Customer'
        );
        insert accParent;
        
        //Create Account PMS Agent
        Account accPms = new Account(
            Name = 'Agent Test',
            Type = 'Agency',
            Industry = 'Automotive',
            Phone = '0800400502',
            Website = 'www.test2.com',
            Account_Status__c = 'Active Customer',
            ParentId = accParent.Id
        );
        insert accPms;
        System.debug(accPms);
        
        //Create Contact
        Contact ct = new Contact(
                FirstName = 'John Pms',
                LastName = 'Jonson ',
                Email = 'John.Jonson@2test.com',
                Phone = '080040050',
                AccountId = accPms.Id,
                Position_valueset__c = 'Consultant',
                Contact_Type__c = 'Private Customer',
                Customer_Status__c = 'Active Customer',
                Gender__c = 'Male',
                pi__url__c = 'www.salesforce.com'
            );
        insert ct;
        
        //Create Property Londoner
        Property__c p = new Property__c(
            Name = 'Londoner Test Hotel',
            Is_Active__c = true
        );
        insert p;
        
        //Create Order for PMS Agent
        Order orderPms = new Order(
            AccountId = accPms.Id,
            PMS_Agent__c = accPms.Id,
            Contact_Name__c = ct.Id,
            Hotel__c = p.Id,
            Arrival_Date__c = System.today(),
            Length_of_Stay__c = 4,
            Type = 'SPA',
            Room_Revenue__c = 3000,
            Event_Revenue__c = 3000,
            Gross_Revenue__c = 50000,
            Status = 'Draft',
            EffectiveDate = System.today(),
            RecordTypeId = ORDER_M_E_RT_ID
        );
        
        Test.startTest();
        try{
            insert orderPms;
        }catch(Exception ex) {
            Assert.fail('Should not reach this point.');
        }
        Test.stopTest();
    }
    
    @IsTest
    private static void testNotificationMEOtherQueue(){
        //Create Account Newly Account Name
        Account acc = new Account(
            Name = 'Newly Imported Company',
            Type = 'Company',
            Industry = 'Automotive',
            Phone = '0800400501',
            Website = 'www.test1.com',
            Account_Status__c = 'Active Customer'
        );
        insert acc;
        
        //Create Contact
        Contact ct = new Contact(
                FirstName = 'John Sales Central',
                LastName = 'Jonson ',
                Email = 'John.Jonson@3test.com',
                Phone = '080040050',
                AccountId = acc.Id,
                Position_valueset__c = 'Consultant',
                Contact_Type__c = 'Private Customer',
                Customer_Status__c = 'Active Customer',
                Gender__c = 'Male',
                pi__url__c = 'www.salesforce.com'
            );
        insert ct;
        
        //Create Property Londoner
        Property__c p = new Property__c(
            Name = 'Grafton',
            Is_Active__c = true
        );
        insert p;
        
        //Create Order
        Order order = new Order(
            AccountId = acc.Id,
            Hotel__c = p.Id,
            Contact_Name__c = ct.Id,
            Arrival_Date__c = System.today(),
            Length_of_Stay__c = 4,
            Type = 'SPA',
            Room_Revenue__c = 3000,
            Event_Revenue__c = 3000,
            Gross_Revenue__c = 50000,
            Status = 'Draft',
            EffectiveDate = System.today(),
            RecordTypeId = ORDER_M_E_RT_ID
        );
        Test.startTest();
        try{
            insert order;
        }catch(Exception ex) {
            Assert.fail('Should not reach this point.');
        }
        Test.stopTest();
    }
    
    @IsTest
    private static void testNotificationVIP(){
        //Create Parent Account Company
        Account accParent = new Account(
            Name = 'Company Parent Test',
            Type = 'Company',
            Industry = 'Automotive',
            Phone = '0800400501',
            Website = 'www.test1.com',
            Account_Status__c = 'Active Customer'
        );
        insert accParent;
        //Create Account Company
        Account acc = new Account(
            Name = 'Company Test',
            Market_Segment__c = 'Consortia',
            Type = 'Company',
            Industry = 'Automotive',
            Phone = '0800400502',
            Website = 'www.test2.com',
            Account_Status__c = 'Active Customer',
            ParentId = accParent.Id
        );
        insert acc;
        
        //Create Contact
        Contact ct = new Contact(
                FirstName = 'John ',
                LastName = 'Jonson ',
                Email = 'John.Jonson@test.com',
                Phone = '080040050',
                AccountId = acc.Id,
                Position_valueset__c = 'Consultant',
                Contact_Type__c = 'Private Customer',
                Customer_Status__c = 'Active Customer',
                Gender__c = 'Male',
                pi__url__c = 'www.salesforce.com'
            );
        insert ct;
        
        //Create Property
        Property__c p = new Property__c(
            Name = 'Londoner Test Hotel',
            Is_Active__c = true
        );
        insert p;
        
        //Create Order
        Order order = new Order(
            AccountId = acc.Id,
            Contact_Name__c = ct.Id,
            Hotel__c = p.Id,
            Arrival_Date__c = System.today(),
            Length_of_Stay__c = 5,
            Type = 'SPA',
            Room_Revenue__c = 3000,
            Event_Revenue__c = 3000,
            Gross_Revenue__c = 50000,
            Status = 'Draft',
            EffectiveDate = System.today(),
            RecordTypeId = ORDER_ROOMS_RT_ID
        );
        
        Test.startTest();
        try{
            insert order;
        }catch(Exception ex) {
            Assert.fail('Should not reach this point.');
        }
        Test.stopTest();
    }

    @IsTest
    private static void testOrderCampaignMatch(){

        // Account and Contact record
        Contact ct = [
            SELECT Id, AccountId 
            FROM Contact 
            Limit 1
        ];

        // Campaign Record
        Campaign cmp = [
            SELECT Id, StartDate 
            FROM Campaign 
            LIMIT 1
        ];
        cmp.StartDate = System.today().addDays(-1);
        update cmp;

        // Create Campaign External Link
        Campaign_External_Link__c cel = TestDataFactory.generateCampaignExternalLink(
                cmp.Id, 
                RATE_CODE,
                false
            );
        cel.Rate_Code__c = 'RCAA';
        
        insert cel;

        // Create Booking Order
        Order order = TestDataFactory.generateOrder(
            ct.AccountId, 
            ORDER_ROOMS_RT_ID, 
            false
        );
        order.Contact_Name__c = ct.Id;
        order.Rate_Code__c = 'RCAA';
        order.Update_Date__c = System.now();
        insert order;

        Boolean isMatchFound = false;
        Test.startTest();
        isMatchFound = OrderToCampaignMatcher.isMatch(order, cel, 'Rate_Code__c');
        Test.stopTest();

        System.assertEquals(true, isMatchFound, 'Rate Codes do not match.');
    }

    @IsTest
    private static void testOrderCampaignNoMatch(){

        // Account and Contact record
        Contact ct = [
            SELECT Id, AccountId 
            FROM Contact 
            Limit 1
        ];

        // Campaign Record
        Campaign cmp = [
            SELECT Id, StartDate 
            FROM Campaign 
            LIMIT 1
        ];
        cmp.StartDate = System.today().addDays(-1);
        update cmp;

        // Create Campaign External Link
        Campaign_External_Link__c cel = TestDataFactory.generateCampaignExternalLink(
                cmp.Id, 
                RATE_CODE,
                false
            );
        insert cel;

        // Create Booking Order
        Order order = TestDataFactory.generateOrder(
            ct.AccountId, 
            ORDER_ROOMS_RT_ID, 
            false
        );
        order.Contact_Name__c = ct.Id;
        order.Rate_Code__c = 'RCAA';
        order.Update_Date__c = System.now();
        insert order;

        Boolean isMatchFound = false;
        Test.startTest();
        isMatchFound = OrderToCampaignMatcher.isMatch(order, cel, 'Rate_Code__c');
        Test.stopTest();

        System.assertNotEquals(true, isMatchFound, 'Rate Codes match.');
    }
}