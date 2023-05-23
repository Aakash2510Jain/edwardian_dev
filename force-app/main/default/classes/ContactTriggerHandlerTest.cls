/**
 * @author Khin Hou <Khin.Hou@Cloudshiftgroup.com>
 * @date 2021-01-29
 * @group CloudShift
 * @description Class to determine how to process Contact records from the trigger
 *
 * Date          author             Change Description
 * -----------------------------------------------------------------------------------
 * 2021-01-29    Khin Hou           Created Original Class
 */
@isTest
public with sharing class ContactTriggerHandlerTest {



    private static final Integer BULK_AMOUNT = 50;
    private static final SObjectRecordTypes ACCOUNT_RECORD_TYPES = new SObjectRecordTypes(
        'Account'
    );

    /**
     * Method tested: areFieldsNotEmpty()
     * Expected result: method to return true
     */
    @isTest
    private static void areFieldsNotEmptyTrue() {
        List<Account> accounts = TestDataFactory.generateAccounts(
            ACCOUNT_RECORD_TYPES.getDefaultId(),
            BULK_AMOUNT,
            true
        );

        List<Contact> contacts = TestDataFactory.generateContacts(accounts, false);

        ContactTriggerHandler handler = new ContactTriggerHandler();

        for (Contact contact : contacts) {
            System.assertEquals(
                true,
                handler.areFieldsNotEmpty(contact),
                'Method should return true as the Contact has the relevants fields populated'
            );
        }
    }

    /**
     * Method tested: areFieldsNotEmpty()
     * Expected result: method to return false
     */
    @isTest
    private static void areFieldsNotEmptyFalse() {
        List<Account> accounts = TestDataFactory.generateAccounts(
            ACCOUNT_RECORD_TYPES.getDefaultId(),
            BULK_AMOUNT,
            true
        );

        List<Contact> contacts = TestDataFactory.generateContacts(accounts, false);
        ContactTriggerHandler handler = new ContactTriggerHandler();

        for (Contact contact : contacts) {

            contact.FirstName = '';
            contact.LastName = '';

            System.assertEquals(
                false,
                handler.areFieldsNotEmpty(contact),
                'Method should return false as the Contact does not have the relevants fields populated'
            );
        }
    }

    /**
     * Method tested: areFieldsNotEmpty()
     * Expected result: method to return false
     */
    @isTest
    private static void getContactsToSendToPardotAddAll() {
        List<Account> accounts = TestDataFactory.generateAccounts(
            ACCOUNT_RECORD_TYPES.getDefaultId(),
            BULK_AMOUNT,
            true
        );

        List<Contact> contacts = TestDataFactory.generateContacts(accounts, false);

        for (Contact contact : contacts) {
            contact.pi__url__c = '';
        }

        ContactTriggerHandler handler = new ContactTriggerHandler();

        for (Contact contact : contacts) {
            System.assert(
                String.isBlank(contact.pi__url__c),
                'The Pardot URL field should be blank'
            );

            System.assert(
                !contact.isPersonAccount,
                'Contact should not be a persons account'
            );
        }

        List<Contact>  returnContacts = handler.getContactsToSendToPardot(contacts);

        System.assertEquals(
            BULK_AMOUNT,
            returnContacts.size(),
            'The same amount of Contacts should have been returned'
        );
    }

    /**
     * Method tested: areFieldsNotEmpty()
     * Expected result: method to return false
     */
    @isTest
    private static void getContactsToSendToPardotAddNone() {
        List<Account> accounts = TestDataFactory.generatePersonAccounts(
            BULK_AMOUNT,
            false
        );
        insert accounts;

        List<Contact> contacts = new List<Contact>([
            SELECT
                Id, FirstName, LastName, pi__url__c, isPersonAccount
            FROM Contact
            WHERE isPersonAccount = true
        ]);

        ContactTriggerHandler handler = new ContactTriggerHandler();

        System.assert(
            !contacts.isEmpty(),
            'Contacts should not be empty'
        );

        for (Contact contact : contacts) {
            System.assert(
                String.isBlank(contact.pi__url__c),
                'The Pardot URL field should be blank'
            );

            System.assert(
                contact.isPersonAccount,
                'Contact should be a persons account'
            );
        }

        List<Contact> returnContacts = handler.getContactsToSendToPardot(contacts);

        System.assertEquals(
            0,
            returnContacts.size(),
            'The same amount of Contacts should have been returned'
        );
    }

}