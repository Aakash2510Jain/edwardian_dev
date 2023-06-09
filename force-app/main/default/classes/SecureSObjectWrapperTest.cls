/**
* @author Gavin Palmer (gavinhughpalmer@gmail.com)
* @version 1.0
*
* 2019-03-23 : Gavin Palmer - Original
**/
@isTest
private class SecureSObjectWrapperTest {

    @isTest
    private static void getTestIsAccessible() {
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        SecureSObjectWrapper secureAccount = new SecureSObjectWrapper(testAccount);
        System.assertEquals(
            testAccount.Name, secureAccount.get('Name'),
            'The field should be returned for users that have access to it'
        );
    }

    @isTest
    private static void getTestIsNotAccessible() {
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        SecureSObjectWrapper secureAccount = new SecureSObjectWrapper(testAccount);
        System.runAs(getTestUser()) {
            System.assertEquals(
                null, secureAccount.get('Name'),
                'The field should not be returned for users that have access to it'
            );
        }
    }

    @isTest
    private static void putTestIsEditable() {
        Account testAccount = new Account();
        SecureSObjectWrapper secureAccount = new SecureSObjectWrapper(testAccount);
        final String testName = 'Gavin';
        secureAccount.put('Name', testName);
        System.assertEquals(
            testName, testAccount.Name,
            'The name should be set for the system admin as they have access'
        );
    }

    @isTest
    private static void putTestIsNotEditable() {
        Account testAccount = new Account();
        SecureSObjectWrapper secureAccount = new SecureSObjectWrapper(testAccount);
        System.runAs(getTestUser()) {
            secureAccount.put('Name', 'Gavin');
        }
        System.assertEquals(
            null, testAccount.Name,
            'The field should not be set if the user does not have edit access'
        );
    }

    private static User getTestUser() {
        return new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name LIKE '%Chatter%' LIMIT 1].Id,
            LastName = 'last',
            Email = 'puser000@amamama.com',
            Username = 'puser000@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
    }
}