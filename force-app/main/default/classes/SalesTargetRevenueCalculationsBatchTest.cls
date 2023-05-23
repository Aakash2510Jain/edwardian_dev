@isTest
public without sharing class SalesTargetRevenueCalculationsBatchTest {

    private static final Id AGENCY_ACCOUNT_RECORD_TYPE_ID = new SObjectRecordTypes('Account').getRecordTypeId('Agency');
    private static final Integer BULK_AMOUNT = 50;
    private static final Id STANDARD_PRICEBOOK_ID = Test.getStandardPricebookId();
    private static final Id DEFAULT_PRODUCT_RECORD_TYPE_ID = new SObjectRecordTypes('Product2').getDefaultId();

    private static final String REVENUE_VALUE = TestDataFactory.getPickListValues('Actual_Revenue_Status__c')[0];
    private static final String REGIONS_VALUE = TestDataFactory.getPickListAPIValues('Regions__c')[0];
    private static final String MARKETING_VALUE = TestDataFactory.getPickListValues('Market_Segments__c')[0];

    private static final Set<String> FIELDS_TO_CHECK_IF_ACCOUNTS_CONTAINED = new Set<String>{
        'Master_Company_ID__c',
        'Parent_Company_ID__c',
        'Master_Agent_ID__c',
        'Parent_Agent_ID__c'
    };

    @TestSetup
    static void setup(){
        Configuration__c config = new Configuration__c(
            Are_Processes_Off__c  = true
        );
        insert config;

        List<Account> accountList = createAccountStructure();

        Property__c newHotel = new Property__c(
            Name = 'Test Hotel'
        );

        insert newHotel;

        List<Sales_Target__c> salesTargetsToInsert = TestDataFactory.createSalesTargets(
            accountList,
            newHotel,
            true
        );

        List<PricebookEntry> pricebookEntriesList = createdPricebookEntries();
        createdOrdersWithOrderItems(accountList, pricebookEntriesList, newHotel);

    }

    @isTest
    public static void actualRevenueCalculationTest() {

        Map<Id, Map<Id, Order>> ordersByAccount = new Map<Id, Map<Id, Order>>();

        List<Order> orderList = new List<Order>([
            SELECT
                Id, AccountId, Net_Revenue__c, Master_Company_ID__c, Parent_Company_ID__c,
                Master_Agent_ID__c, Parent_Agent_ID__c
            FROM Order
        ]);

        for (Order order : orderList) {
            order.Reservation_Status__c = REVENUE_VALUE;

            for (String fieldName : FIELDS_TO_CHECK_IF_ACCOUNTS_CONTAINED) {
                Id accountId = (Id) order.get(fieldName);
                if (!ordersByAccount.keySet().contains(accountId)) {
                    ordersByAccount.put(
                        accountId,
                        new Map<Id, Order>()
                    );
                }
                if (!ordersByAccount.get(accountId).keySet().contains(order.Id)) {
                    ordersByAccount.get(accountId).put(
                        order.Id,
                        order
                    );
                }
            }

        }
        Test.startTest();
        update orderList;

        SalesTargetRevenueCalculationsBatch salesTargetRevenueCalculationsBatch = new SalesTargetRevenueCalculationsBatch();
        Database.executeBatch(salesTargetRevenueCalculationsBatch);
        Test.stopTest();

        List<Sales_Target__c> salesTargets = [
            SELECT Id, Actual_Revenue__c, Account__c, Pipeline_Revenue__c
            FROM Sales_Target__c
            LIMIT 5
        ];

        for (Sales_Target__c salesTarget : salesTargets) {
            Map<Id, Order> ordersRelatedToAccount = ordersByAccount.get(salesTarget.Account__c);

            Decimal total = 0.00;
            for (Order order : ordersRelatedToAccount.values()) {
                total += order.Net_Revenue__c;
            }

            System.assertEquals(
                total,
                salesTarget.Actual_Revenue__c,
                'The Actual Revenue should be the same as the total from the orders'
            );
        }

    }

    /**
     * Inserts x amount of Accounts with Parent Accounts attached
     *
     * @return List<Account> allAccounts - a list of accounts with a combination of parent and child accounts
     */
    private static List<Account> createAccountStructure() {
        List<Account> allAccounts = new List<Account>();

        List<Account> parentAccountList = TestDataFactory.generateAccounts(
            AGENCY_ACCOUNT_RECORD_TYPE_ID,
            BULK_AMOUNT/2,
            true
        );

        allAccounts.addAll(parentAccountList);

        List<Account> childAccountList = TestDataFactory.generateAccounts(
            AGENCY_ACCOUNT_RECORD_TYPE_ID,
            BULK_AMOUNT/2,
            false
        );

        for (Integer i = 0; i < childAccountList.size(); i++) {
            childAccountList[i].ParentId = parentAccountList[0].Id;
        }
        insert childAccountList;

        allAccounts.addAll(childAccountList);
        System.debug('allAccounts ' + allAccounts.size());
        return allAccounts;
    }

    /**
     * Creates a new custom pricebook and a list of products, for each pricebook a price book entry is created
     * for the custom price book
     *
     * @return List<PricebookEntry> pricebookEntriesToInsert - a list of the pricebook entries created
     */
    private static List<PricebookEntry> createdPricebookEntries() {
        List<PricebookEntry> pricebookEntriesToInsert = new List<PricebookEntry>();
        List<PricebookEntry> customPriceBookEntries = new List<PricebookEntry>();

        Pricebook2 customPriceBook = new Pricebook2(
            Name = 'Custom Pricebook',
            isActive = true
        );

        insert customPriceBook;

        List<Product2> productList = TestDataFactory.createProducts(
            DEFAULT_PRODUCT_RECORD_TYPE_ID,
            BULK_AMOUNT,
            true
        );

        for (Product2 product : productList) {
            pricebookEntriesToInsert.add(
                new PricebookEntry(
                    Pricebook2Id = STANDARD_PRICEBOOK_ID,
                    Product2Id = product.Id,
                    UnitPrice = 10000,
                    IsActive = true
                )
            );
        }

        insert pricebookEntriesToInsert;

        for (Product2 product : productList) {
            customPriceBookEntries.add(
                new PricebookEntry(
                    Pricebook2Id = customPriceBook.Id,
                    Product2Id = product.Id,
                    UnitPrice = 10000,
                    IsActive = true
                )
            );
        }

        insert customPriceBookEntries;

        return customPriceBookEntries;
    }

    /**
     * Creates test record for Orders and Order Items and links them together
     *
     * @param List<Account> accountList - List of Accounts to link orders to
     * @param List<PricebookEntry> priceBookEntriesList - List of Pricebooks to create create the orders and order items with
     * @param Property__c hotel - the property to link the Orders to
     */
    private static void createdOrdersWithOrderItems(List<Account> accountList, List<PricebookEntry> priceBookEntriesList, Property__c hotel) {
        List<Order> ordersToInsert = new List<Order>();
        List<OrderItem> orderItemsToInsert = new List<OrderItem>();

        for (Account account: accountList) {
            ordersToInsert.add(
                new Order(
                    AccountId = account.Id,
                    Reservation_Status__c = 'CI',
                    Status = 'Draft',
                    Arrival_Date__c = Date.newinstance(Date.Today().year() + 1, 1, 2),
                    Archived_Hotel_Id__c = hotel.Id,
                    Region__c = REGIONS_VALUE,
                    EffectiveDate = System.today().addYears(1) + 1,
                    Net_Revenue__c = 11,
                    Pricebook2Id = priceBookEntriesList[0].Pricebook2Id,
                    Master_Company__c = account.Id,
                    Master_Agent__c = account.Id,
                    Parent_Company__c = account.ParentId,
                    Parent_Agent__c = account.ParentId,
                    PMS_Agent__c = account.Id,
                    PMS_Company__c = account.Id,
                    Market_Description__c = MARKETING_VALUE
                )
            );
        }

        insert ordersToInsert;

        for (Integer i = 0; accountList.size() < 1; i++) {
            orderItemsToInsert.add(
                new OrderItem(
                    Product2Id = priceBookEntriesList[i].Product2Id,
                    OrderId = ordersToInsert[i].Id,
                    PricebookEntryId = priceBookEntriesList[i].Id,
                    UnitPrice = 111,
                    Quantity = 1
                )
            );
        }

        insert orderItemsToInsert;

    }

}