public class GroupSeriesCSVFileController {
    @AuraEnabled
    
    public static Group_Series_Rates_Mapping__mdt groupSeriesCSVFormat(){
        
        List<Group_Series_Rates_Mapping__mdt> gsrCSVFileFormat = [SELECT Group_Series_Field_API_Name__c,Id,Label,Sequence__c FROM Group_Series_Rates_Mapping__mdt];
        system.debug('gsrCSVFileFormat'+gsrCSVFileFormat);
        return gsrCSVFileFormat[0];
    } 

}