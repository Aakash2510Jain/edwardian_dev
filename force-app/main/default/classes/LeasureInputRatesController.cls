/**
 * Class uses as controller for all components that use in Rate input process for Leasure opportunities.
 *
 * @author  Anton Salanovich (anton.salanovich@cloudshiftgroup.com)
 * @since   October 2020
 */

@SuppressWarnings('PMD.ExcessivePublicCount, PMD.CyclomaticComplexity')
public with sharing class LeasureInputRatesController {

    public static final String DEFAULT_INPUT_VALUE = '- None -';


	    /**
     * Method calls on Init of component leisureRates to retrieve required data (Opportunity detail, Existing products, Product families,
	 * Metadata periods limited by Contract dates)
     *
     * @param  oppId  opportunity Id from record detail page
     * @return   OpportunityWrapper object that contains periods from metadata, opportunity and existing products related to opportunity
     */
	@AuraEnabled
	public static OpportunityWrapper getInitData(String oppId){
		try{
			OpportunityWrapper oppWrap = new OpportunityWrapper();
            Opportunity opp = [
				SELECT Id, Pricebook2Id, Pricebook2.Name, Proposed_Contract_Start_Date__c, Proposed_Contract_End_Date__c,
                	(SELECT Id FROM OpportunityLineItems)
			    FROM Opportunity
			    WHERE Id = :oppId];

            List<Leisure_Seasonal_Dates__mdt> datePeriods = getMetadataPeriods(opp);
			List<PicklistWrapper> prodFamilies = producePicklist(Product2.Family, false);
			oppWrap.datePeriods = datePeriods;
            oppWrap.productFamilies = prodFamilies;

			if (opp.OpportunityLineItems != null && opp.OpportunityLineItems.size() != 0){
				oppWrap.existingProducts = getExistingProducts(opp);
			}
			oppWrap.opp = opp;
			return oppWrap;
		} catch (Exception e){
			throw new AuraHandledException(e.getMessage());
		}
    }

	  /**
     *Method to retrieve pricebooks with Category Leisure only. Need to load values for pricebookSelection screen.
     *
     * @return   List<Pricebook2> that contains only Leisure pricebooks
     */
	@AuraEnabled
	public static List<Pricebook2> getLeisurePricebooks(){
		List<Pricebook2> pricebooks = [
			SELECT Id, Name, IsStandard, Pricebook_Category__c
			FROM Pricebook2
			WHERE Pricebook_Category__c = 'Leisure'
		    ORDER BY Name];
		return pricebooks;
	}

		  /**
     *Method updates opportunity after selecting pricebook related to it.
     *
	 * @param opp Opportunity with assigned pricebook
     * @return   List<Pricebook2> that contains only Leisure pricebooks
     */
	@AuraEnabled
	public static void updateOpportunityPricebook(Opportunity opp){
		try{
			update opp;
		} catch (Exception e){
			throw new AuraHandledException(e.getMessage());
		}
	}


			  /**
	 *Method to retrieve all existing periods in Metadata Leisure_Seasonal_Dates__mdt and limited by
	 *Proposed contract start and end Date. Only periods between Start and End date will be returned.
	 *If metadata periods splitted by contract start or end date - this period will be restricted by new dates
     *
	 * @param opp Opportunity with contract Start & End dates
     * @return   List<Leisure_Seasonal_Dates__mdt> that contains only periods between contract dates
     */
    @AuraEnabled
	public static List<Leisure_Seasonal_Dates__mdt> getMetadataPeriods(Opportunity opp){
        List<Leisure_Seasonal_Dates__mdt> allPeriods =  [
            SELECT Id, DeveloperName, MasterLabel, Label, QualifiedApiName, Start_Date__c, End_Date__c, Day_of_Week__c
            FROM Leisure_Seasonal_Dates__mdt
			ORDER BY Start_Date__c ASC];

		List<Leisure_Seasonal_Dates__mdt> periodsToReturn = new List<Leisure_Seasonal_Dates__mdt>();

		for (Leisure_Seasonal_Dates__mdt per: allPeriods) {
			// Checking if period start - end date between contract dates - to return all period
			if (per.Start_Date__c >= opp.Proposed_Contract_Start_Date__c && per.End_Date__c >= opp.Proposed_Contract_Start_Date__c
				&& per.Start_Date__c <= opp.Proposed_Contract_End_Date__c && per.End_Date__c <= opp.Proposed_Contract_End_Date__c) {
				periodsToReturn.add(per);
			} else
			// Checking if period start date less contract start date - update period start date with contract start and return this period
				if (per.Start_Date__c < opp.Proposed_Contract_Start_Date__c && per.End_Date__c >= opp.Proposed_Contract_Start_Date__c
					&& per.End_Date__c <= opp.Proposed_Contract_End_Date__c) {
					per.Start_Date__c = opp.Proposed_Contract_Start_Date__c;
					periodsToReturn.add(per);
				} else
				// Checking if period end date creater than contract end date - update period end date with contract end and return this period
					if (per.Start_Date__c >= opp.Proposed_Contract_Start_Date__c && per.End_Date__c >= opp.Proposed_Contract_End_Date__c
						&& per.Start_Date__c <= opp.Proposed_Contract_End_Date__c) {
							per.End_Date__c = opp.Proposed_Contract_End_Date__c;
							periodsToReturn.add(per);
					}
		}
		return periodsToReturn;

    }

				  /**
	 *Method to retrieve picklist values to list Label-Value
     *
	 * @param SObjectField field - API name of field with picklist type
	 * @param Boolean addDefault - true if need to add default value ' None ' to list with values
     * @return   List<PicklistWrapper> that contains all picklist values with labels and
     */
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

	/**
	 *Method to retrieve all existing Opportunity products splitted by Hotels (Hotel_Property__c) field
	 * Need to split because we need to show products in correct order hotel by hotel
	 * Also all line items ordered by From_Date__c field with nulls last. It allows to place supplements in the end of each
	 * property, because from date didn't fill in Supplements
     *
	 * @param opp Opportunity with contract Start & End dates
     * @return   List<Leisure_Seasonal_Dates__mdt> that contains only periods between contract dates
     */
    private static List<OpportunityLineItem> getExistingProducts(Opportunity opp){
		try{
			List<OpportunityLineItem> oppLineItems = [
				SELECT Id, Product2Id, Product2.Name, Product2.Hotel_Property__c, From_Date__c, To_Date__c, X1_Adult_Price__c, X2_Adult_Price__c,
					X2_Adult_List_Price__c, Description, Day_of_Week__c, Breakfast_Incl__c, OpportunityId
			    FROM OpportunityLineItem
			    WHERE OpportunityId = :opp.Id
			    ORDER BY From_Date__c ASC NULLS LAST];
			Map<String, List<OpportunityLineItem>> mapIdToItem = new Map<String, List<OpportunityLineItem>>();


			//Use Property as key for mapping to make sure that we have no duplicate hotels in the list and each item
			//with propperty added to correct list
			for (OpportunityLineItem item : oppLineItems){
				String itemKey = item.Product2.Hotel_Property__c;
				if (mapIdToItem.containsKey(itemKey)){
					List<OpportunityLineItem> exList = mapIdToItem.get(itemKey);
					exList.add(item);
					mapIdToItem.put(itemKey, exList);
				} else {
					List<OpportunityLineItem> newList = new List<OpportunityLineItem>();
					newList.add(item);
					mapIdToItem.put(itemKey, newList);
				}
			}
			List<List<OpportunityLineItem>> toReturn = mapIdToItem.values();
			List<OpportunityLineItem> dataToReturn = new List<OpportunityLineItem>();

			List<Property__c> properties = [SELECT Id, Name FROM Property__c ORDER BY Name ASC];

			for (Property__c prop: properties) {
				if (mapIdToItem.containsKey(prop.Id)) {
					for (OpportunityLineItem item: mapIdToItem.get(prop.Id)) {
						dataToReturn.add(item);
					}
				}
			}
			return dataToReturn;
		} catch (Exception e){
			throw new AuraHandledException(e.getMessage());
		}
	}

		/**
	 * Method to update existing product after clicking save on the leasureEditProduct component.
	 * After saving returns List<Id> with existing products - to limit products for product selection
     *
	 * @param List<OpportunityLineItem> listToUpdate list with line items for updating
	 * @param List<OpportunityLineItem> listToRemove list with line items for removing
	 *
     * @return   List<String> that contains only id of products that was updated
     */
	@AuraEnabled
	public static List<String> updateExistingProducts(List<OpportunityLineItem> listToUpdate, List<OpportunityLineItem> listToRemove){
        try {
            Set<String> setExistingId = new Set<String>();
            update listToUpdate;
			delete listToRemove;

			for (OpportunityLineItem item: listToUpdate) {
				setExistingId.add(item.Product2Id);
			}
            return new List<String>(setExistingId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
	}

    	/**
	 * To get all product on init component leasureProductSelection for leasure Opportunities. Method returns supplements and rooms in different lists,
	 * because we don't need to show supplements on the product selection screen but need to show on rates selection.
	 * Supplements has type Map<Id, List<PricebookEntry>> because we need to show supplements after each hotel and usage of Map give easy way to split
	 * Supplements by hotels
	 *
	 * @param isInit boolean attribute that shows on which step calls method (on init of component or in another place)
	 * @param prBookId String that contains selected pricebook related to opportunity
	 * @param existingProductList List that contains Ids of products that already exist to exclude them from results
	 *
	 * @return products List<PricebookEntry> containing list of all pricebookenties that match criteria
	 */

	@AuraEnabled
	public static ProductWrapper getLeasureProducts(Boolean isInit, String prBookId, List<String> existingProductList){
		ProductWrapper prodWrap = new ProductWrapper();
		String productObject = 'Product2';
		List<String> recTypesNames = new List<String>();
        recTypesNames.add('Supplement');
        recTypesNames.add('Leisure');
		List<RecordType> rt = [SELECT Id, Name, DeveloperName FROM RecordType WHERE DeveloperName IN :recTypesNames AND SObjectType = :productObject ORDER BY DeveloperName ASC];
		// use two different SOQLS to retrieve supplements and rooms because we need to split these lists and each must be ordered by Name
		List<PricebookEntry> products = [
			SELECT Pricebook2.IsActive, Name, ProductCode, UnitPrice, Product2.Day_of_Week__c, Product2.To_Date__c, Product2.From_Date__c, Pricebook2Id, X2_Adult_List_Price__c, Product2.Hotel_Property__c, Product2.Name,
				Product2.Brand__c, Product2.RecordTypeId, Product2.Id, Product2.Description, Product2.Family, Product2.ProductCode, Product2.Hotel_Property__r.Short_Name__c, Product2Id, Product2.Conga_Room_Type__c
		    FROM PricebookEntry
			WHERE
				(Pricebook2Id = :prBookId)
				AND (Product2.Id NOT IN :existingProductList)
				AND (Product2.RecordTypeId = :rt[0].Id)
			ORDER BY Product2.Hotel_Property__r.Short_Name__c ASC, Product2.From_Date__c ASC, Product2.To_Date__c ASC, Product2.Day_of_Week__c ASC
            ];
		prodWrap.products =  products;
		List<PricebookEntry> supplements = [
			SELECT Pricebook2.IsActive, Name, ProductCode, UnitPrice, Product2.Day_of_Week__c, Product2.To_Date__c, Product2.From_Date__c, Pricebook2Id, X2_Adult_List_Price__c, Product2.Hotel_Property__c, Product2.Name,
				Product2.RecordTypeId, Product2.Id, Product2.Description, Product2.Family, Product2.ProductCode, Product2.Hotel_Property__r.Short_Name__c, Product2Id, Product2.Conga_Room_Type__c
		    FROM PricebookEntry
			WHERE
				(Pricebook2Id = :prBookId)
				AND (Product2.Id NOT IN :existingProductList)
				AND (Product2.RecordTypeId = :rt[1].Id)
            ORDER BY Product2.Name ASC
			];
		Map<String, List<PricebookEntry>> supplmentsMap = new Map<String, List<PricebookEntry>>();
		for (PricebookEntry supp : supplements) {
			String itemKey = supp.Product2.Hotel_Property__c;
			if (supplmentsMap.containsKey(itemKey)) {
				List<PricebookEntry> exList = supplmentsMap.get(itemKey);
				exList.add(supp);
				supplmentsMap.put(itemKey, exList);
			} else {
				List<PricebookEntry> newList = new List<PricebookEntry>();
				newList.add(supp);
				supplmentsMap.put(itemKey, newList);
			}
		}
		prodWrap.supplements = supplmentsMap;

		return prodWrap;
	}

	/**
	 * To save all products after input rates
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

    public class OpportunityWrapper{
		@AuraEnabled public Opportunity opp{ get; set; }
		@AuraEnabled public List<PicklistWrapper> productFamilies{ get; set; }
		@AuraEnabled public List<Leisure_Seasonal_Dates__mdt> datePeriods{ get; set; }
		@AuraEnabled public List<OpportunityLineItem> existingProducts{ get; set; }
	}

	public class ProductWrapper{
		@AuraEnabled public List<PricebookEntry> products{ get; set; }
		@AuraEnabled public Map<String, List<PricebookEntry>> supplements{ get; set; }
	}

    public class PicklistWrapper{
		@AuraEnabled public String value{ get; set; }
		@AuraEnabled public String label{ get; set; }
		public PicklistWrapper(String label, String value){
			this.label = label;
			this.value = value;
		}
	}

}