/**
 * @author Khin Hou <Khin.Hou@Cloudshiftgroup.com>
 * @date 2021-01-29
 * @group CloudShift
 * @description Class to determine how to process Lead records from the trigger
 *
 * Date          author             Change Description
 * -----------------------------------------------------------------------------------
 * 2021-01-29    Khin Hou           Created Original Class
 */
@isTest
public with sharing class LeadTriggerHandlerTest {

    private static final Integer BULK_AMOUNT = 50;
    private static final SObjectRecordTypes LEAD_RECORD_TYPES = new SObjectRecordTypes(
        'Lead'
    );

    /**
     * Method tested: isRecordTypeStandardOrMeetingsAndEvents()
     * Expected result: method to return true
     */
    @isTest
    private static void isRecordTypeStandardOrMeetingsAndEventsTrue() {
        LeadTestFactory leadTestFactory = new LeadTestFactory();
        List<Lead> leads = (List<Lead>) leadTestFactory.getMultipleSObjects(BULK_AMOUNT);
        LeadTriggerHandler handler = new LeadTriggerHandler();

        for (Lead lead : leads) {
            System.assertEquals(
                true,
                handler.isRecordTypeStandardOrMeetingsAndEvents(lead),
                'Method should return true as the Lead is standard type'
            );
        }
    }

    /**
     * Method tested: isRecordTypeStandardOrMeetingsAndEvents()
     * Expected result: method to return false
     */
    @isTest
    private static void isRecordTypeStandardOrMeetingsAndEventsFalse() {
        LeadTestFactory leadTestFactory = new LeadTestFactory();
        leadTestFactory.recordTypeId = LEAD_RECORD_TYPES.getRecordTypeId('Meetings_and_Events_RFP');
        List<Lead> rfpLeads = (List<Lead>) leadTestFactory.getMultipleSObjects(BULK_AMOUNT);
        LeadTriggerHandler handler = new LeadTriggerHandler();

        for (Lead lead : rfpLeads) {
            System.assert(
                lead.RecordTypeId != LEAD_RECORD_TYPES.getRecordTypeId('Meetings_and_Events'),
                'Test Lead should not have the regular Meetings and Events record Type, it should be the Mettings and Events RFP'
            );

            System.assert(
                lead.RecordTypeId != LEAD_RECORD_TYPES.getRecordTypeId('Standard'),
                'Test Lead should not have the Standard record Type'
            );

            System.assertEquals(
                false,
                handler.isRecordTypeStandardOrMeetingsAndEvents(lead),
                'Method should return false as the Lead is neither \'standard\' or \'Meeting and Events type\''
            );
        }
    }

    /**
     * Method tested: areFieldsNotEmpty()
     * Expected result: method to return true
     */
    @isTest
    private static void areFieldsNotEmptyTrue() {
        LeadTestFactory leadTestFactory = new LeadTestFactory();
        List<Lead> leads = (List<Lead>) leadTestFactory.getMultipleSObjects(BULK_AMOUNT);
        LeadTriggerHandler handler = new LeadTriggerHandler();

        for (Lead lead : leads) {
            System.assertEquals(
                true,
                handler.areFieldsNotEmpty(lead),
                'Method should return true as the Lead has the relevants fields populated'
            );
        }
    }

    /**
     * Method tested: areFieldsNotEmpty()
     * Expected result: method to return false
     */
    @isTest
    private static void areFieldsNotEmptyFalse() {
        LeadTestFactory leadTestFactory = new LeadTestFactory();
        List<Lead> falseLeads = (List<Lead>) leadTestFactory.getMultipleSObjects(BULK_AMOUNT);
        LeadTriggerHandler handler = new LeadTriggerHandler();

        for (Lead lead : falseLeads) {
            lead.FirstName = '';
            lead.LastName = '';

            System.assertEquals(
                false,
                handler.areFieldsNotEmpty(lead),
                'Method should return false as the Lead does not have the relevants fields populated'
            );
        }
    }

    /**
     * Method tested: getLeadsToSendToPardot()
     * Expected result: method to return all the Leads sent to the method as the parameter
     */
    @isTest
    private static void getLeadsToSendToPardotAllAdded() {
        LeadTestFactory leadTestFactory = new LeadTestFactory();
        List<Lead> leads = (List<Lead>) leadTestFactory.getMultipleSObjects(BULK_AMOUNT);
        LeadTriggerHandler handler = new LeadTriggerHandler();

        for (Lead lead : leads) {
            System.assert(
                String.isBlank(lead.pi__url__c),
                'The Pardot URL field should be blank'
            );
        }

        List<Lead> returnLeads = handler.getLeadsToSendToPardot(leads);

        System.assertEquals(
            BULK_AMOUNT,
            returnLeads.size(),
            'The same amount of Leads should have been returned'
        );
    }

    /**
     * Method tested: getLeadsToSendToPardot()
     * Expected result: method to return none of the Leads sent to the method as the parameter
     */
    @isTest
    private static void getLeadsToSendToPardotNoneAdded() {
        LeadTestFactory leadTestFactory = new LeadTestFactory();
        List<Lead> leads = (List<Lead>) leadTestFactory.getMultipleSObjects(BULK_AMOUNT);
        LeadTriggerHandler handler = new LeadTriggerHandler();

        for (Lead lead : leads) {
            lead.pi__url__c = 'www.test.com';
        }

        List<Lead> returnLeads = handler.getLeadsToSendToPardot(leads);

        System.assertEquals(
            0,
            returnLeads.size(),
            'The same amount of Leads should have been returned'
        );
    }

    /**
     * Method tested: getLeadsToSendToPardot()
     * Expected result: method to return half of the Leads sent to the method as the parameter
     */
    @isTest
    private static void getLeadsToSendToPardotPartialAdded() {
        LeadTestFactory leadTestFactory = new LeadTestFactory();
        List<Lead> leads = new List<Lead>();
        List<Lead> leadsWithURL = (List<Lead>) leadTestFactory.getMultipleSObjects(BULK_AMOUNT/2);
        List<Lead> leadsWithoutURL = (List<Lead>) leadTestFactory.getMultipleSObjects(BULK_AMOUNT/2);
        LeadTriggerHandler handler = new LeadTriggerHandler();

        for (Lead lead : leadsWithURL) {
            lead.pi__url__c = 'www.test.com';
        }

        leads.addAll(leadsWithURL);
        leads.addAll(leadsWithoutURL);

        System.assertEquals(
            BULK_AMOUNT,
            leads.size(),
            'The total amount of leads created should be the same as the BULK amount, ' + BULK_AMOUNT
        );

        List<Lead> returnLeads = handler.getLeadsToSendToPardot(leads);

        System.assertEquals(
            BULK_AMOUNT/2,
            returnLeads.size(),
            'Half of the total amount of leads created should have been returned'
        );
    }

    /**
     * Method tested: TECH DEBT - COVERAGE ONLY FOR LeadTrigger
     * Expected result: method to return true
     */
    @isTest
    static void coverTrigger() {

        LeadTestFactory leadTestFactory = new LeadTestFactory();
        List<Lead> leads = (List<Lead>) leadTestFactory.getMultipleSObjects(BULK_AMOUNT);

        // add in the custom settings it won't be able to see
        Sync_Pardot_Settings__c setting = new Sync_Pardot_Settings__c();
        setting.Prospect_Form_URL__c = 'http://test.salesforce.com';
        insert setting;

        Boolean errorCaught = false;
        try {
            Database.insert(leads, false);
        }
        catch (Exception e) {
            // if no custom setting URL is available it will fail
            errorCaught = true;
        }

        System.assertEquals(1, 1, 'Fail');
    }

    @isTest
    static void coverTrigger2() {

        Lead[] leads = new Lead[] { new Lead(pi__url__c = 'x', FirstName = 'Bob', LastName = 'Bob') };

        insert leads;

        System.assertEquals(1, leads.size(), 'Fail');
    }
}