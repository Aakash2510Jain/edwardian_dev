/**
 * @author Jamie Kennedy <Jamie.Kennedy@Cloudshiftgroup.com>
 * @date 2021-10-15
 * @group CloudShift
 * @description test class validates the values returned in FlowRetrievePicklistValues
 *   FlowRetrievePicklistValue: will return a List<String> of the required picklist values, Class is utilized in the 'Opportunity - Update DDR Records' flow.
 *
 * Date          author             Change Description
 * -----------------------------------------------------------------------------------
 * 2021-10-15    Jamie Kennedy      Created Original Class
 */

@isTest
public class FlowRetrievePicklistValues_Test {

    /*
     * The following test class validates if we send in a multi-select picklist (Object and FieldName) 
     * then we are returned a list of all the picklist values.
     */
    @isTest
    public static void testPicklistReturn(){
        
		List<FlowRetrievePicklistValues.Request> inputClass = new List<FlowRetrievePicklistValues.Request>();        
        FlowRetrievePicklistValues.Request tempClass = new FlowRetrievePicklistValues.Request();
        tempClass.objectApiName = 'Opportunity';
        tempClass.fieldApiName = 'Properties__c';
        
        inputClass.add(tempClass);
        
        List<FlowRetrievePicklistValues.Result> returnValues = FlowRetrievePicklistValues.picklistFieldValues(inputClass);
        
        system.debug('Values Returned:: ' + returnValues);
        
        for(FlowRetrievePicklistValues.Result picklistList : returnValues) {
            for(String value : picklistList.pickListLabel) {
                system.debug('Value:: ' + value);
            }
        }
        
        system.assert(returnValues.Size() > 0, 'Nothing has been returned from the picklist');
    }
}