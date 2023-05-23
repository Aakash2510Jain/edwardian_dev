public class CreateNewBusinessCtrl {

    @AuraEnabled
    public static List<String> getBuisnessRecordTypeId(String oppId) {
        List<String> strList = new List<String>();
        
        Business_Case_Default_Values_Mapping__mdt bcFieldValues = [Select id , Multiple_Occupancy_Child_Policy__c, Arrivals_Departures__c , Charges_Payment__c , Close_Out_Dates__c ,Deposits__c , Record_Type_Name__c from Business_Case_Default_Values_Mapping__mdt];
        Opportunity oppObj 	= [Select Id, Name, RecordType.Name from Opportunity where Id =: oppId];
        strList.add(Schema.SObjectType.Quote.getRecordTypeInfosByName().get(oppObj.RecordType.Name).getRecordTypeId()) ;
        strList.add(oppObj.Name);
        strList.add(bcFieldValues.Close_Out_Dates__c);
        strList.add(bcFieldValues.Multiple_Occupancy_Child_Policy__c);
        strList.add(bcFieldValues.Arrivals_Departures__c);
        strList.add(bcFieldValues.Charges_Payment__c);
        strList.add(bcFieldValues.Deposits__c);
        return strList;
    }
}