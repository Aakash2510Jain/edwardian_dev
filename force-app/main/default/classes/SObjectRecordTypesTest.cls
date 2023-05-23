/**
 * @author Gavin Palmer (gavinhughpalmer@gmail.com)
 * @version 1.0
 * @description Test class for the SObjectRecordTypes class
 *
 * 2019-09-24 : Gavin Palmer - Original
 **/
@IsTest
private class SObjectRecordTypesTest {
    @IsTest
    private static void constructorInvalidSObjectTest() {
        final String invalidObjectName = 'This is not an object';
        try {
            new SObjectRecordTypes(invalidObjectName);
            System.assert(
                false,
                'An exception should have been thrown when the object is not valid'
            );
        } catch (Exception exceptionThrown) {
            final String errorMessage = exceptionThrown.getMessage();
            System.assert(
                errorMessage.containsIgnoreCase(invalidObjectName),
                'The error should have contained ' +
                invalidObjectName +
                ' actual error message ' +
                errorMessage
            );
        }
    }

    @IsTest
    private static void getDefaultIdTest() {
        SObjectRecordTypes recordTypes = new SObjectRecordTypes('Account');
        System.assertNotEquals(
            null,
            recordTypes.getDefaultId(),
            'The Account should have a default record type id'
        );
    }

    @IsTest
    private static void getRecordTypeIdTest() {
        SObjectRecordTypes recordTypes = new SObjectRecordTypes('Account');
        final String recordTypeName = (new List<String>(
            Account.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().keySet()
        ))[0];
        System.assertNotEquals(
            null,
            recordTypes.getRecordTypeId(recordTypeName),
            'The Account should return the record type from the SObjectRecordTypes instance'
        );
    }

    @IsTest
    private static void getRecordTypeIdInvalidDeveloperNameTest() {
        SObjectRecordTypes recordTypes = new SObjectRecordTypes('Account');
        System.assertEquals(
            null,
            recordTypes.getRecordTypeId('Invalid record type developer name'),
            'The invalid record type name should return null as the record type id'
        );
    }
}