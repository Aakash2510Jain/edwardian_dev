/**
 * @author Jamie Kennedy <Jamie.Kennedy@Cloudshiftgroup.com>
 * @date 2021-10-15
 * @group CloudShift
 * @description Class will return a List<String> of the required picklist values, this is utilized in the 'Opportunity - Update DDR Records' flow.
 *
 * Date          author             Change Description
 * -----------------------------------------------------------------------------------
 * 2021-10-15    Jamie Kennedy      Created Original Class
 */

global class FlowRetrievePicklistValues {

    // Utilize this class to pass in your parameters
    @testVisible
    global class Request {
        @InvocableVariable(Required=true)
        global String objectApiName;
        @InvocableVariable(Required=true)
        global String fieldApiName; 
    }
    
    // this is the exit class
    @testVisible
    global class Result {
        @InvocableVariable
        global List<String> pickListLabel;
    }

    /**
     * Method to 
     *
     * @param List<Request> inputParameters - a List of the Request object above. Only returns the first item in the list thats passed in.
     *
     * @return List<Result> resultsList - List of picklist values.
     */
    @InvocableMethod(Label='Get Picklist Values' Description='Used to obtain picklist values from Flow.')
    global static List<Result> picklistFieldValues(Request[] inputParameters) {
        
        Schema.SObjectType convertToObj = Schema.getGlobalDescribe().get(inputParameters[0].objectApiName);
        Schema.DescribeSObjectResult res = convertToObj.getDescribe();
        Schema.DescribeFieldResult fieldResult = res.fields.getMap().get(inputParameters[0].fieldApiName).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        List<String> tempString = new List<String>();
        
        for( Schema.PicklistEntry pickListVal : ple){
            
            tempString.add(pickListVal.getLabel());
        }
        
        Result r = new Result();
        r.pickListLabel = tempString;
        
        List<Result> resultsList = new List<Result>();
        resultsList.add(r);
        
     	return resultsList;
	}
}