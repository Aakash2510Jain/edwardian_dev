/**
* @author Gavin Palmer (gavinhughpalmer@gmail.com)
* @version 1.0
*
* 2019-02-02 : Gavin Palmer - Original
**/
@IsTest
public without sharing class LeadTestFactory extends AbstractSObjectTestFactory {

    private static final SObjectRecordTypes LEAD_RECORD_TYPES = new SObjectRecordTypes(
        'Lead'
    );

    public String firstName = 'Test FirstName ';
    public String lastName = 'Test LastName ';
    public String company = 'Test Company';
    public String status = 'New';
    public Id recordTypeId = LEAD_RECORD_TYPES.getDefaultId();

    public override SObject getSObject() {
        return new Lead(
            FirstName = firstName + uniqueValue,
            LastName = lastName + uniqueValue,
            Company = company,
            Status = status,
            RecordTypeId = recordTypeId
        );
    }
}