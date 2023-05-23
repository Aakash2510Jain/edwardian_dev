public with sharing class RemoveAllProductsController {

    @AuraEnabled
    public static List<OpportunityLineItem> getItems(String oppId) {

        List<OpportunityLineItem> oppLineItems = [
            SELECT Id, Product2Id, Product2.Name, From_Date__c, To_Date__c, X1_Adult_Price__c, X2_Adult_List_Price__c, Day_of_Week__c, OpportunityId
            FROM OpportunityLineItem
            WHERE OpportunityId = :oppId
            ORDER BY From_Date__c ASC];

            return oppLineItems;
    }

    

    @AuraEnabled
    public static void removeAllItems(List<OpportunityLineItem> prods) {
        try {
            delete prods;
        } catch (DmlException e) {
            throw new AuraHandledException(e.getDmlMessage(0));
        } 
    
    }
}