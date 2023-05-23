@SuppressWarnings('PMD.ExcessivePublicCount')public with sharing class RateInputProcessController{
    public static final String DEFAULT_INPUT_VALUE = '- None -';
    @AuraEnabled
    public static List<Pricebook2> getFilteredPricebooks(String recordType) {
        String pbFilter = '%' + recordType + '%';
        List<Pricebook2> pricebooks = [SELECT Id, Name, IsStandard
                                       FROM Pricebook2
                                       WHERE Pricebook_Category__c LIKE :pbFilter
                                       ORDER BY Name ];
        return pricebooks;
    }

    @AuraEnabled
    public static List<PicklistWrapper> getProductFamily(){
        return producePicklist(Product2.Family, false);
    }

    @AuraEnabled
    public static OpportunityWrapper getInitData(String oppId){
        try{
            OpportunityWrapper oppWrap = new OpportunityWrapper();
            Opportunity opp = [
                SELECT Id, Pricebook2Id, Pricebook2.Name, Proposed_Contract_Start_Date__c, Proposed_Contract_End_Date__c, RecordType.Name, Pricing_Structure__c,
                    (SELECT Id FROM OpportunityLineItems)
                FROM Opportunity
                WHERE Id = :oppId];

            if (opp.Proposed_Contract_Start_Date__c != null && opp.Proposed_Contract_End_Date__c != null){
                List<DatePeriodWrapper> datePeriods = getPeriodsTable(opp);
                List<PicklistWrapper> prodFamilies = producePicklist(Product2.Family, false);
                if (opp.OpportunityLineItems != null && opp.OpportunityLineItems.size() != 0){
                    oppWrap.existingProducts = getExistingProducts(opp);
                }
                oppWrap.datePeriods = datePeriods;
                oppWrap.productFamilies = prodFamilies;
            }
            oppWrap.opp = opp;
            return oppWrap;
        } catch (Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static List<ExistingProductWrapper> getExistingProducts(Opportunity opp){
        try{
            List<OpportunityLineItem> oppLineItems = [
                SELECT Id, Product2Id, Product2.Name, From_Date__c, To_Date__c, X1_Adult_Price__c, X2_Adult_Price__c, Day_of_Week__c, OpportunityId, Breakfast_Incl__c,
                    X2_Adult_List_Price__c, Description
                FROM OpportunityLineItem
                WHERE OpportunityId = :opp.Id
                ORDER BY From_Date__c ASC];
            Map<String, List<OpportunityLineItem>> mapIdToItem = new Map<String, List<OpportunityLineItem>>();

            for (OpportunityLineItem item : oppLineItems){
                String itemKey = item.Product2Id + item.Day_of_Week__c;
                if (mapIdToItem.containsKey(itemKey)){
                    List<OpportunityLineItem> exList = mapIdToItem.get(itemKey);
                    exList.add(item);
                    mapIdToItem.put(itemKey, exList);
                } else{
                    List<OpportunityLineItem> newList = new List<OpportunityLineItem>();
                    newList.add(item);
                    mapIdToItem.put(itemKey, newList);
                }
            }
            List<List<OpportunityLineItem>> toReturn = mapIdToItem.values();
            List<ExistingProductWrapper> exProdWrappers = new List<ExistingProductWrapper>();

            // For productName in wrapper we use prodList[0].Product2.Name because each prodList 
            // from List<OpportunityLineItem> toReturn contain products with the same Name and Id of Product2
            // Difference only in fields Start and End date. In this case we can use any item from prodList, but we use 0, 
            // because prodList[0] already exists. In another case prodlist for this prod doesn't exist
            for (List<OpportunityLineItem> prodList : toReturn){
                ExistingProductWrapper newWrap = new ExistingProductWrapper();
                newWrap.productName = prodList[0].Product2.Name;
                newWrap.daysOfWeek = prodList[0].Day_of_Week__c;
                String sortingHandlerText = prodList[0].Day_of_Week__c == 'Mon - Thu' ? 'a' : 'z';
                newWrap.fieldForSorting = prodList[0].Product2.Name + sortingHandlerText;
                newWrap.toRemove = false;
                newWrap.productId = prodList[0].Product2Id;
                newWrap.prodList = prodList;
                exProdWrappers.add(newWrap);
            }
            return exProdWrappers;

        } catch (Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * To get all product on init component
     *
     * @param isInit boolean attribute that shows on which step calls method (on init of component or in another place)
     * @param prBookId String that contains selected pricebook related to opportunity
     * @param existingProductList List that contains Ids of products that already exist to exclude them from results
     *
     * @return products List<PricebookEntry> containing list of all pricebookenties that match criteria
     */
    @AuraEnabled
    public static List<PricebookEntry> getAllProducts(Boolean isInit, String prBookId, List<String> existingProductList){
        RecordType rt = [SELECT Id, Name, DeveloperName
                         FROM RecordType
                         WHERE DeveloperName = 'Hotel_Rooms'
                         LIMIT 1];
        List<PricebookEntry> toReturn = [
            SELECT Pricebook2.IsActive, Name, ProductCode, UnitPrice, Pricebook2Id, X2_Adult_List_Price__c, Product2.Name, Product2.RecordTypeId, 
                Product2.Id, Product2.Description, Product2.Brand__c, Product2.Hotel_Property__c, Product2.Family, Product2.ProductCode, Product2Id, Product2.Conga_Room_Type__c
            FROM PricebookEntry
            WHERE (Pricebook2Id = :prBookId) AND (Product2.Id NOT IN :existingProductList) AND (Product2.RecordTypeId = :rt.Id)
            ORDER BY Product2.Name ASC NULLS LAST];
        return toReturn;
    }

    /**
     * To get all product on init component
     *
     * @param opp contain opportunity record with needed fields
     *
     * @return List<DatePeriodWrapper> - all contract periods splitted by month
     */
    private static List<DatePeriodWrapper> getPeriodsTable(Opportunity opp){
        Date startContractDate = opp.Proposed_Contract_Start_Date__c;
        Date endContractDate = opp.Proposed_Contract_End_Date__c;

        Integer monthsBetweenDates = startContractDate.monthsBetween(endContractDate);

        Date currentDate = startContractDate.addMonths(1).toStartOfMonth();
        Date firstPeriodEndDate = currentDate.addDays(-1);
        currentDate = currentDate.addMonths(-1);

        List<DatePeriodWrapper> allDatePeriods = new List<DatePeriodWrapper>();
        DatePeriodWrapper firstPeriod = new DatePeriodWrapper();
        firstPeriod.periodNumber = 1;
        firstPeriod.startPeriodDate = startContractDate;
        firstPeriod.endPeriodDate = firstPeriodEndDate;
        firstPeriod.startPeriodDateString = startContractDate.format();
        firstPeriod.endPeriodDateString = firstPeriodEndDate.format();
        allDatePeriods.add(firstPeriod);

        for (Integer i = 0; i < monthsBetweenDates; i++) {
            Date firstNextMonth = currentDate.addMonths(1);
            Date lastNextMonth;
            if (i != monthsBetweenDates - 1){
                lastNextMonth = firstNextMonth.addMonths(1).addDays(-1);
            } else{
                lastNextMonth = endContractDate;
            }

            DatePeriodWrapper currentPeriod = new DatePeriodWrapper();
            currentPeriod.periodNumber = i + 2;
            currentPeriod.startPeriodDate = firstNextMonth;
            currentPeriod.endPeriodDate = lastNextMonth;
            currentPeriod.startPeriodDateString = firstNextMonth.format();
            currentPeriod.endPeriodDateString = lastNextMonth.format();

            allDatePeriods.add(currentPeriod);

            currentDate = firstNextMonth;
        }
        return allDatePeriods;
    }

    /**
     * To get all product on init component
     *
     * @param allLineItems opportunityLineItems for inserting
     *
     * @return void
     */
    @AuraEnabled
    public static void saveLineItems(List<OpportunityLineItem> allLineItems){
        try{
            insert allLineItems;
        } catch (Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<String> updateExistingProducts(List<ExistingProductWrapper> products){
        try {       
            List<OpportunityLineItem> listToUpdate = new List<OpportunityLineItem>();
            List<OpportunityLineItem> listToRemove = new List<OpportunityLineItem>();
            Set<String> setExistingId = new Set<String>();
    
            for (ExistingProductWrapper prod : products){
                if (prod.toRemove){
                    listToRemove.addAll(prod.prodList);
                } else{
                    listToUpdate.addAll(prod.prodList);
                    setExistingId.add(prod.productId);
                }
            }
    
            update listToUpdate;
            delete listToRemove;
    
            return new List<String>(setExistingId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateOpportunityPricebook(Opportunity opp){
        try{
            update opp;
        } catch (Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    @TestVisible
    private static List<PicklistWrapper> producePicklist(SObjectField field, Boolean addDefault){
        List<PicklistWrapper> pv = new List<PicklistWrapper>();
        if (addDefault){
            pv.add(new PicklistWrapper(DEFAULT_INPUT_VALUE, DEFAULT_INPUT_VALUE));
        }
        Schema.DescribeFieldResult f = field.getDescribe();
        List<Schema.PicklistEntry> ple = f.getPicklistValues();

        for (Schema.PicklistEntry pickListVal : ple){
            pv.add(new PicklistWrapper(pickListVal.getLabel(), pickListVal.getValue()));
        }
        return pv;
    }

    public class PicklistWrapper{
        @AuraEnabled
        public String value{ get; set; }

        @AuraEnabled
        public String label{ get; set; }

        public PicklistWrapper(String label, String value){
            this.label = label;
            this.value = value;
        }
    }

    public class OpportunityWrapper{
        @AuraEnabled
        public Opportunity opp{ get; set; }

        @AuraEnabled
        public List<PicklistWrapper> productFamilies{ get; set; }

        @AuraEnabled
        public List<DatePeriodWrapper> datePeriods{ get; set; }

        @AuraEnabled
        public List<ExistingProductWrapper> existingProducts{ get; set; }
    }

    public class DatePeriodWrapper{
        @AuraEnabled
        public integer periodNumber{ get; set; }

        @AuraEnabled
        public Date startPeriodDate{ get; set; }

        @AuraEnabled
        public Date endPeriodDate{ get; set; }

        @AuraEnabled
        public String startPeriodDateString{ get; set; }

        @AuraEnabled
        public String endPeriodDateString{ get; set; }
    }

    public class ExistingProductWrapper{
        @AuraEnabled
        public String productName{ get; set; }

        @AuraEnabled
        public String daysOfWeek{ get; set; }

        @AuraEnabled
        public String productId{ get; set; }

        @AuraEnabled
        public Boolean toRemove{ get; set; }

        @AuraEnabled
        public String fieldForSorting{ get; set; }

        @AuraEnabled
        public List<OpportunityLineItem> prodList{ get; set; }
    }
}