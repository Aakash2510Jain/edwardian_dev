public class GroupSeriesRateCompController {
    
    @AuraEnabled
    
    public static List<Group_Series_Rates__c> fetchGroupSeriesRates(String recordId){
        
        List<Group_Series_Rates__c> grpseriesList = [SELECT Is_Breakfast_Included__c,Overwrite_Standard_Price__c,Opportunity__c, Date_From__c,Date_To__c,
                                                     Double_Twin_Double_Occupancy__c,Double_Twin_Single_Occupancy__c,Hotel__c,Id,Rooms__c,Room_Type__c,Tour_Code__c,
                                                     Triple_Room_2_Adults_1_Child__c,Triple_Room_3_Adults__c FROM Group_Series_Rates__c where Opportunity__c = :recordId];
        
        return grpseriesList;
    }
    
    @AuraEnabled
    
    public static GroupSeriesWrapper getPropertyFromOpp(String recordId){
        
        Map<String, List<Group_Series_Rates__c>> hotelAndGroupListMap = new Map<String, List<Group_Series_Rates__c>>();
        Map<String,Property_Standard_Price__c> hotelAndStandardPriceMap = new Map<String,Property_Standard_Price__c>();
        
        String fetchopp = [SELECT Id,Properties__c FROM Opportunity WHERE Id =:recordId].Properties__c;
        
        List<String> lstString = fetchopp.split(';');
        
        List<Group_Series_Rates__c> grpseriesList = [SELECT Is_Breakfast_Included__c,Overwrite_Standard_Price__c,Date_From__c,Date_To__c,Opportunity__c,Double_Twin_Double_Occupancy__c,
                                                     Double_Twin_Single_Occupancy__c,Hotel__c,Id,Rooms__c,Room_Type__c,Tour_Code__c,Triple_Room_2_Adults_1_Child__c,Triple_Room_3_Adults__c 
                                                     FROM Group_Series_Rates__c where Opportunity__c = :recordId];
        
        List<Property_Standard_Price__c> propertyStdPrice = [Select Id, Name, Opportunity__c, Property__c, Standard_Price_For_Double_Twin_Double__c,
                                                             Standard_Price_For_Double_Twin_Single__c, Standard_Price_For_Triple_Room_2_Adult__c, Standard_Price_For_Triple_Room_3_Adults__c 
                                                             FROM Property_Standard_Price__c WHERE Opportunity__c = :recordId];
        
        for(String propertyStr : lstString) {
            hotelAndGroupListMap.put(propertyStr, new List<Group_Series_Rates__c>());
            hotelAndStandardPriceMap.put(propertyStr,new Property_Standard_Price__c());
        }        
        
        for(Property_Standard_Price__c prp : propertyStdPrice){
            hotelAndStandardPriceMap.put(prp.Property__c,prp);
            System.debug(hotelAndStandardPriceMap.get(prp.Property__c));
        }
        
        for(Group_Series_Rates__c groupObj : grpseriesList) {
            //groupObj.Overwrite_Standard_Price__c = false;
            if(lstString.contains(groupObj.Hotel__c)) {
                if(hotelAndGroupListMap.containsKey(groupObj.Hotel__c)) 
                {
                    hotelAndGroupListMap.get(groupObj.Hotel__c).add(groupObj);
                }else{
                    hotelAndGroupListMap.put(groupObj.Hotel__c, new List<Group_Series_Rates__c>{groupObj});  
                } 
            }            
        }
        system.debug('hotelAndGroupListMap'+hotelAndGroupListMap);
        
        GroupSeriesWrapper wrapObj = new GroupSeriesWrapper(lstString, hotelAndGroupListMap, hotelAndStandardPriceMap);
        system.debug('GroupSeriesWrapper'+wrapObj);
        return wrapObj;
    }
    
    
    public class GroupSeriesWrapper {
        
        @AuraEnabled
        
        public List<String> propertyList {get; set;}
        
        @AuraEnabled
        
        public Map<String, List<Group_Series_Rates__c>> hotelAndGroupListMap {get; set;}
        
        @AuraEnabled
        
        public Map<String,Property_Standard_Price__c> hotelAndStandardPriceMap {get; set;}
        
        public GroupSeriesWrapper(List<String> propertyList, Map<String, List<Group_Series_Rates__c>> hotelAndGroupListMap, Map<String,Property_Standard_Price__c> hotelAndStandardPriceMap) {
            this.propertyList			= propertyList;
            this.hotelAndGroupListMap	= hotelAndGroupListMap;
            this.hotelAndStandardPriceMap = hotelAndStandardPriceMap;
        }
    }
}