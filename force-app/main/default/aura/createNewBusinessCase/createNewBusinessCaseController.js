({
    init  : function(cmp, event, helper) {
         debugger;
        var action = cmp.get('c.getBuisnessRecordTypeId');
        action.setParams({ oppId : cmp.get("v.recordId")});
        action.setCallback(this, function(response) {
            //Get state of response
            var state = response.getState();
            if (state === "SUCCESS") {
                var navService = cmp.find("navService");
                var pageRef = {
                    type: "standard__objectPage",
                    attributes: {
                        objectApiName: "Quote",
                        actionName: "new"
                    },
                    state: {
                    }
                }
                // Replace with your own field values
                var defaultFieldValues = {
                    RecordTypeId: response.getReturnValue()[0],
                    Name: response.getReturnValue()[1],
                    OpportunityId:cmp.get("v.recordId"),
                    Close_Out_Dates__c: response.getReturnValue()[2],
                    Multiple_Occupancy_Child_Policy__c: response.getReturnValue()[3],
                    Arrivals_Departures__c: response.getReturnValue()[4],
                    Charges_Payment__c: response.getReturnValue()[5],
                    Deposits__c: response.getReturnValue()[6],
                };
                pageRef.state.defaultFieldValues = cmp.find("pageRefUtils").encodeDefaultFieldValues(defaultFieldValues);
                navService.navigate(pageRef);
            }
        });
        $A.enqueueAction(action);		
    }
})