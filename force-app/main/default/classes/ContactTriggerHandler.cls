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
public with sharing class ContactTriggerHandler extends TriggerHandlerFramework {

    private static final Set<String> FIELDS_TO_CHECK_ISNT_NULL = new Set<String>{
        'FirstName',
        'LastName'
    };

    public override void afterInsert() {
        List<Contact> contactsToSendToPardot = getContactsToSendToPardot((List<Contact>) Trigger.new);
        PardotServiceHandler.createProspectsByContact(contactsToSendToPardot);
    }

    /**
     * Function to build up a list of Contacts that should be sent to Pardot
     *
     * @param List<Contact> contactsInserted - The list of newly inserted contacts
     *
     * @return List<Contact> contactToSendToPardot - The list of Leads that need to be sent to Pardot
     */
    @TestVisible
    private List<Contact> getContactsToSendToPardot(List<Contact> contactsInserted) {
        List<Contact> contactToSendToPardot = new List<Contact>();

        for (Contact contact : contactsInserted) {
            if (
                areFieldsNotEmpty(contact) &&
                String.isBlank(contact.pi__url__c) &&
                !contact.isPersonAccount
            ) {
                contactToSendToPardot.add(contact);
            }
        }

        return contactToSendToPardot;
    }

    /**
     * Function to check if fields on the Contact are not null
     *
     * @param Contact contact - The current Contact to check the fields against
     *
     * @return Boolean - True if all fields are not null, false, if one or more fields are null
     */
    @TestVisible
    private Boolean areFieldsNotEmpty(Contact contact) {
        for (String fieldName : FIELDS_TO_CHECK_ISNT_NULL) {
            if (String.isBlank((String) contact.get(fieldName))) {
                return false;
            }
        }
        return true;
    }
}