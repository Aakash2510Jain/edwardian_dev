({
    fetchgrpSeriesRatesHelper : function(component, event, helper) {
        debugger;
        var recId = component.get("v.recordId");
        
        var action = component.get("c.getPropertyFromOpp");
        action.setParams({
            recordId : recId
        });
        action.setCallback(this, function(response){
            debugger;
            var state = response.getState();
            if (state === "SUCCESS") {
                var custs = [];
                
                component.set("v.propertyRec",response.getReturnValue().hotelAndStandardPriceMap);
                component.set("v.selectedProperties", response.getReturnValue().propertyList);
                var conts = response.getReturnValue().hotelAndGroupListMap;
                for ( var key in conts ) {
                    custs.push({value:conts[key], key:key});
                }
                component.set("v.groupSeriesMap", custs);
                component.set("v.showSpinner", false);
            }
            component.set("v.showSpinner", false);
        });
        $A.enqueueAction(action);
   
    },
    
    toastMsg : function( strType, strMessage ) { 
        
        var showToast = $A.get("e.force:showToast"); 
        
        if(showToast == undefined) {
            alert('Record updated successfully');
        }
        
        else {
            showToast.setParams({  
                
                message : strMessage, 
                type : strType, 
                mode : 'sticky' 
                
            });  
            showToast.fire(); 
        }
    }

})