public with sharing class GroupSeriesRatesController {

    @AuraEnabled
    public static Boolean insertRecords(List<Group_Series_Rates__c> recordsList){
        Boolean result = false;
        try{
            if(!recordsList.isEmpty()){
                insert recordsList;
                result = true;
            }
        }catch(Exception exp){
            system.debug('Error Message: '+exp.getMessage());
            result = false;
        }
        return result;
    }
}