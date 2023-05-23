({
    fetchgrpSeriesRates : function(component, event, helper) {
        debugger;
        component.set("v.tabId", '1');
        component.set("v.showSpinner", true); 
        helper.fetchgrpSeriesRatesHelper(component, event, helper);
        
    },
    
    /*onSave : function( component, event, helper ) {  
        debugger;
        var updatedRecords = component.find("groupSeriesRatesTable").get("v.draftValues"); 
        var recId = updatedRecords[0].id;
        
        var action = component.get("c.updategrpSeriesRatesList"); 
        action.setParams({ 
            'updatedgroupSeriesRatesList' : updatedRecords 
        }); 
        
        action.setCallback( this, function( response ) { 
            
            var state = response.getState();  
            if ( state === "SUCCESS") { 
                
                if ( response.getReturnValue() === true ) { 
                    helper.toastMsg( 'success', 'Records Saved Successfully.' ); 
                    component.find("groupSeriesRatesTable").set("v.draftValues", null); 
                    helper.fetchgrpSeriesRatesHelper(component, event, helper);
                } 
                
                else {  
                    helper.toastMsg('error','Something went wrong. Contact your system administrator.');    
                } 
            }
            
        }); 
        $A.enqueueAction( action ); 
        
    }*/

})