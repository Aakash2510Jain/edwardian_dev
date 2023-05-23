/**
 * @author Vasile Fana <vasile.fana@cloudshiftgroup.com>
 * @date 2020-12-01
 * @group CloudShiftGroup
 * @description  This class is responsible for generating the order (Bookings) unique Ids
 *               used in campaign record matching 
 *
 * Date          author             Change Description
 * -----------------------------------------------------------------------------------
 * 2020-12-01    Vasile Fana       Created Class
 * 20201-01-11   Tobias Hastings.  Added sourceCode to constructor and generateId method
 * 2021-04-21    Andrei Budescu    Deleted Class
 */
public without sharing class OrderToCampaignMatchingIdGenerator {
    private Id pmsAgent; 
    private Id pmsCompany; 
    private Id pmsSource; 
    private String rateCode; 
    private Id propSalesInit; 
    private Id corpSalesInit; 
    private String sourceCode;
    private final String uniqueId;

    public OrderToCampaignMatchingIdGenerator(Order order) {
        this.pmsAgent = order.PMS_Agent__c;
        this.pmsCompany = order.PMS_Company__c;
        this.pmsSource = order.PMS_Source__c;
        this.rateCode = order.Rate_Code__c;
        this.propSalesInit = order.nisc_Property_Sales_Initiative__c;
        this.corpSalesInit = order.nisc_Corporate_Sales_Initiative__c;
        this.sourceCode = order.S_Code__c;
        
    }


    
}