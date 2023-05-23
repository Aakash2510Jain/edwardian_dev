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
public with sharing class LeadTriggerHandler extends TriggerHandlerFramework {

    private static final Set<String> FIELDS_TO_CHECK_ISNT_NULL = new Set<String>{
        'FirstName',
        'LastName'
    };

    private static final Set<String> FIELDS_TO_CHECK_IS_NULL = new Set<String>{
        'pi__url__c'
    };

    private static final SObjectRecordTypes LEAD_RECORD_TYPES = new SObjectRecordTypes(
        'Lead'
    );

    public override void afterInsert() {
        List<Lead> leadsToSendToPardot = getLeadsToSendToPardot((List<Lead>) Trigger.new);
        PardotServiceHandler.createProspectsByLead(leadsToSendToPardot);
    }

    /**
     * Function to build up a list of Leads that should be sent to Pardot
     *
     * @param List<Lead> leadsInserted - The list of newly inserted Leads
     *
     * @return List<Lead> leadsToSendToPardot - The list of Leads that need to be sent to Pardot
     */
    @TestVisible
    private List<Lead> getLeadsToSendToPardot(List<Lead> leadsInserted) {
        List<Lead> leadsToSendToPardot = new List<Lead>();

        for (Lead lead : leadsInserted) {
            if (
                isRecordTypeStandardOrMeetingsAndEvents(lead) &&
                areFieldsNotEmpty(lead) &&
                String.isBlank(lead.pi__url__c)
            ) {
                leadsToSendToPardot.add(lead);
            }
        }

        return leadsToSendToPardot;
    }

    /**
     * Function to check if the Lead has the correct record type of Standard or Meetings and Events
     *
     * @param Lead lead - The current Lead to check the record type
     *
     * @return Boolean - True if the Lead's record type is either Standard or Meetings and Events
     */
    @TestVisible
    private Boolean isRecordTypeStandardOrMeetingsAndEvents(Lead lead) {
        return (
            lead.RecordTypeId == LEAD_RECORD_TYPES.getRecordTypeId('Standard') ||
            lead.RecordTypeId == LEAD_RECORD_TYPES.getRecordTypeId('Meetings_and_Events')
        );
    }

    /**
     * Function to check if fields on the Lead are not null
     *
     * @param Lead lead - The current Lead to check the fields against
     *
     * @return Boolean - True if all fields are not null, false, if one or more fields are null
     */
    @TestVisible
    private Boolean areFieldsNotEmpty(Lead lead) {
        for (String fieldName : FIELDS_TO_CHECK_ISNT_NULL) {
            if (String.isBlank((String) lead.get(fieldName))) {
                return false;
            }
        }
        return true;
    }
}