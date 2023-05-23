({
    doInit : function(component, event, helper) {
        var actionGetPrb = component.get("c.getFilteredPricebooks");

        var rtName = component.get("v.recordTypeName");
        var rtToFilter = '';
        if (rtName.includes('Corporate')) {
            rtToFilter = 'Corporate';
        } else if (rtName.includes('Leisure')) {
            rtToFilter = 'Leisure';
        }

        actionGetPrb.setParams({
            recordType : rtToFilter
        });

        actionGetPrb.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                    var pricebooks = response.getReturnValue();
                    component.set("v.pricebooks", pricebooks);
                    if ((component.get("v.selectedValue") === null || component.get("v.selectedValue") === '') && pricebooks != null && pricebooks.length != 0) {
                        component.set("v.selectedValue", pricebooks[0].Id);
                    }
            } else 
                if (state === "ERROR") {
                    this.showToast('Error!', response.getError(), 'error');
                }
        });

        $A.enqueueAction(actionGetPrb);
    },

    showToast :function (title, message, type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type
        });
        toastEvent.fire();
    }
})