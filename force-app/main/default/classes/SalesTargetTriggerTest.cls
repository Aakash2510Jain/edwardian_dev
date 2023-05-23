@isTest
public class SalesTargetTriggerTest {

    @isTest
    public static void autocompleteStartAndEndDateTest() {
        Property__c newHotel = new Property__c(Name = 'Test Hotel');
        String periodValue = TestDataFactory.getPickListValues('Period__c')[0];
        insert newHotel;
        Id accountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Agency').getRecordTypeId();
        Account newAccount = new Account(RecordTypeId = accountRecordTypeId, Name = 'Test Account');
        insert newAccount;
        Sales_Target__c newSalesTarget = new Sales_Target__c(
            Name = 'Test Sales Target',
            Sales_Person__c = UserInfo.getUserId(),
            Actual_Revenue_Status__c = TestDataFactory.getPickListValues('Actual_Revenue_Status__c')[0],
            Pipeline_Revenue_Status__c = TestDataFactory.getPickListValues('Actual_Revenue_Status__c')[0],
            Account_based_Target__c = true,
            All_Hotels__c = false,
            Regional_Target__c = true,
            Regions__c = TestDataFactory.getPickListValues('Regions__c')[0],
            Market_Segments__c = TestDataFactory.getPickListValues('Market_Segments__c')[0],
            Hotel__c = newHotel.Id,
            Target_Period__c = TestDataFactory.getPickListValues('Target_Period__c')[0],
            Year__c = String.valueOf(Date.Today().year() + 1),
            Pipeline_Revenue_Target__c = 11,
            Actual_Revenue_Target__c = 11,
            Period__c = periodValue,
            Account__c = newAccount.Id
        );
        Test.startTest();
        insert newSalesTarget;
        Test.stopTest();
        List<Sales_Target__c> salesTargetList = [
            SELECT Id, Name, Target_Start_Date__c
            FROM Sales_Target__c
            WHERE Name = 'Test Sales Target'
        ];
        String year = String.valueOf(Date.Today().year() + 1);
        List<Periods__mdt> periods = [SELECT Start_Date__c FROM Periods__mdt WHERE Year__c = :year AND Period__c = :periodValue];
        System.assertEquals(periods[0].Start_Date__c, salesTargetList[0].Target_Start_Date__c);
    }
}