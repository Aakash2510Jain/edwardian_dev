/**
 * @author Khin Hou <Khin.Hou@Cloudshiftgroup.com>
 * @date 2021-01-29
 * @group CloudShift
 * @description Class to send Prospects (Leads and Contacts) to Pardot
 *
 * Date          author             Change Description
 * -----------------------------------------------------------------------------------
 * 2021-01-29    Khin Hou           Created Original Class
 */
public without sharing class PardotServiceHandler {

    private static final Sync_Pardot_Settings__c SETTINGS = Sync_Pardot_Settings__c.getOrgDefaults();
    private static Logger log = new Logger(BulkLogObjectAdapter.getInstance('Pardot Service Handler'));
    private static final String PARDOT_SERVICE_ERROR_MESSAGE = 'An error has occured while trying to send prospects to Pardot.';

    public static void createProspectsByLead(List<Lead> leads) {
        for (Lead lead : leads) {
            apiRequest(
                SETTINGS.Prospect_Form_URL__c,
                'email=' + lead.Email + '&fn=' + lead.FirstName + '&ln=' + lead.LastName,
                lead.Id
            );
        }
        BulkLogObjectAdapter.writeLogs();
    }

    public static void createProspectsByContact(List<Contact> contacts) {
        for (Contact contact : contacts) {
            apiRequest(
                SETTINGS.Prospect_Form_URL__c,
                'email=' + contact.Email + '&fn=' + contact.FirstName + '&ln=' + contact.LastName,
                contact.Id
            );
        }
        BulkLogObjectAdapter.writeLogs();
    }

    @future (callout=true)
    private static void apiRequest(String url, String body, Id recordId) {

        // tests can't do callouts - need a mock here TECH DEBT
        if (!Test.isRunningTest()) {

            HttpResponse response = httpCallout(url, body, recordId);
        }
    }

    @TestVisible
    private static HttpResponse httpCallout(String url, String body, Id recordId) {
        HttpRequest request = new HttpRequest();
        HttpResponse response = new HttpResponse();
        Http http = new Http();

        request.setEndPoint(url);
        request.setBody(body);
        request.setMethod('POST');

        try {
            response = http.send(request);
            return response;
        } catch (System.CalloutException calloutException) {

            log.error(
                PARDOT_SERVICE_ERROR_MESSAGE +
                ' // ' + calloutException, recordId
            );

            return null;
        } finally {
            BulkLogObjectAdapter.writeLogs();
        }
    }
}