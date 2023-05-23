@IsTest
public with sharing class CaseTriggerTest {
    @TestSetup
    static void createRecords(){
        Configuration__c config = new Configuration__c(
            Are_Processes_Off__c  = true
        );
        insert config;
        
        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Social_Cases').getRecordTypeId();
        Case aCase = new Case(RecordTypeId = recordTypeId, Department__c = '', Category__c = '');
        insert aCase;
    }

    @IsTest
    public static void setRTandDepartmentTest() {
        Case createdCase = [
            SELECT Category__c, RecordTypeId
            FROM Case
            LIMIT 1
        ];
        String caseRtName = Schema.SObjectType.Case.getRecordTypeInfosById().get(createdCase.RecordTypeId).Name;
        createdCase.Category__c = 'Complaint';
        createdCase.Group_Id__c = 'FandB';
        update createdCase;
        Case updatedCase = [
            SELECT Id, RecordTypeId
            FROM Case
            LIMIT 1
        ];
        String caseNewRtName = Schema.SObjectType.Case.getRecordTypeInfosById().get(updatedCase.RecordTypeId).Name;
        System.assertEquals('Guest Feedback', caseNewRtName);
    }
}