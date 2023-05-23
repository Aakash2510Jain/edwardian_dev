@isTest
public with sharing class PardotServiceHandlerTest {

    private static final Integer BULK_AMOUNT = 50;
    private static final Id PRICEBOOK_ID = Test.getStandardPricebookId(); //As the api request method needs an Id, this used rather than creating a record
    private static final String UNAUTHORIZED_ERROR_MESSAGE = 'Unauthorized endpoint, please check Setup->Security->Remote site settings.';

    private class MockResponse implements HttpCalloutMock {
        public HttpResponse respond (HttpRequest request) {
            HttpResponse res = new HttpResponse();
            System.debug('request.getBody() ' + request.getBody());
            System.debug('request.getBody() != fail ' + (request.getBody() != 'fail'));
            if (request.getBody() != 'fail') {
                res.setBody('Success');
                res.setStatusCode(201);
            } else {
                res.setBody('Bad Request');
                res.setStatusCode(400);
            }
            return res;
        }
    }

    private class UnauthorizedMockResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            CalloutException calloutExcep = (CalloutException) CalloutException.class.newInstance();
            calloutExcep.setMessage(UNAUTHORIZED_ERROR_MESSAGE);
            throw calloutExcep;
        }
    }

    @TestSetup
    private static void createData() {
        Sync_Pardot_Settings__c settings = new Sync_Pardot_Settings__c(
            Prospect_Form_URL__c = 'http://www.salesforce.com/'
        );
        insert settings;
    }

    @isTest
    private static void apiRequestSuccessResponse() {
        Sync_Pardot_Settings__c settings = Sync_Pardot_Settings__c.getOrgDefaults();
        Test.setMock(HttpCalloutMock.class, new MockResponse());
        Test.startTest();

        try {
            HttpResponse res = PardotServiceHandler.httpCallout(
                settings.Prospect_Form_URL__c,
                'email=test@test.com&fn=TestFirstName&ln=TestLastName',
                PRICEBOOK_ID
            );

            System.assertEquals(
                201,
                res.getStatusCode(),
                'Status code should be 201'
            );

            System.assertEquals(
                'Success',
                res.getBody(),
                'Body should be success'
            );

        } catch (CalloutException excep) {
            System.assert(
                false,
                'Should never reach here'
            );
        }

        Test.stopTest();
    }

    @isTest
    private static void apiRequestBadRequestResponse() {
        Sync_Pardot_Settings__c settings = Sync_Pardot_Settings__c.getOrgDefaults();
        Test.setMock(HttpCalloutMock.class, new MockResponse());
        Test.startTest();

        try {
            HttpResponse res = PardotServiceHandler.httpCallout(
                settings.Prospect_Form_URL__c,
                'fail',
                PRICEBOOK_ID
            );

            System.assertEquals(
                400,
                res.getStatusCode(),
                'Status code should be 400'
            );

            System.assertEquals(
                'Bad Request',
                res.getBody(),
                'Body return Bad Request'
            );

        } catch (CalloutException excep) {
            System.assert(
                false,
                'Should never reach here'
            );
        }

        Test.stopTest();
    }

    @isTest
    private static void apiRequestErrorResponse() {
        Sync_Pardot_Settings__c settings = Sync_Pardot_Settings__c.getOrgDefaults();

        List<Logs__c> listOfExistingLogs = new List<Logs__c>([
            SELECT Id
            FROM Logs__c
        ]);

        System.assert(
            listOfExistingLogs.size() == 0,
            'There should be no Logs in the system'
        );

        Test.setMock(HttpCalloutMock.class, new UnauthorizedMockResponse());
        Test.startTest();

        HttpResponse res = PardotServiceHandler.httpCallout(
            settings.Prospect_Form_URL__c,
            'email=test@test.com&fn=TestFirstName&ln=TestLastName',
            PRICEBOOK_ID
        );

        Logger log = new Logger(BulkLogObjectAdapter.getInstance('Pardot Service Handler'));
        BulkLogObjectAdapter.writeLogs();
        Test.stopTest();

        List<Logs__c> newLogs = new List<Logs__c>([
            SELECT Id, Messages__c
            FROM Logs__c
        ]);

        System.assert(
            newLogs.size() != 0,
            'There should be no Logs in the system'
        );

        System.assert(
            newLogs[0].Messages__c.contains(UNAUTHORIZED_ERROR_MESSAGE),
            'There should be no Logs in the system'
        );
    }
}