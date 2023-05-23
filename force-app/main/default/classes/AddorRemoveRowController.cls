public class AddorRemoveRowController {

     /* @AuraEnabled
    public static List<Group_Series_Rates__c> saveGroupSeriesRatesRecord(String recordId, List<Group_Series_Rates__c> grpserieslist){
        system.debug('grpserieslist'+grpserieslist.size());
        system.debug('recordId' + recordId);
        
        system.debug('grpserieslist'+grpserieslist);
        upsert grpserieslist;
        system.debug('grpserieslist'+grpserieslist);
        return grpserieslist;
    }*/
    
    
    @AuraEnabled
    public static List<Group_Series_Rates__c> upsertAndDeleteGroupSeriesRatesRecord(List<Group_Series_Rates__c> grpserieslist, List<String> deletegrpserieslist, Property_Standard_Price__c propertyStdPrice){
        system.debug('grpserieslist' + grpserieslist);
        system.debug('deletegrpserieslist' + deletegrpserieslist);
        system.debug('propertyStdPrice' + propertyStdPrice);
        if(propertyStdPrice.Opportunity__c != null && propertyStdPrice.Id != null){
            update propertyStdPrice;
        }else{
            insert propertyStdPrice;
        }
        for(Group_Series_Rates__c gsrObj : grpserieslist) {
            System.debug('gsrObj:::'+gsrObj);
        }
        upsert grpserieslist;
        
        if(deletegrpserieslist.size() > 0)
        {
            database.delete(deletegrpserieslist);
        }
        return grpserieslist;
    }
}