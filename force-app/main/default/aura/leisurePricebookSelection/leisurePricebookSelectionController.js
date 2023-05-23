({
    doInit: function (component, event, helper) {
        var actionGetPrb = component.get("c.getLeisurePricebooks");

        actionGetPrb.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var pricebooks = response.getReturnValue();
                component.set("v.pricebooks", pricebooks);
                component.set("v.selectedValue", pricebooks[0].Id);

            } else {
                this.showToast('Error!', response.getError[0].message, 'error');
            }
        });

        $A.enqueueAction(actionGetPrb);
    },

    showToast: function (title, message, type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type
        });
        toastEvent.fire();
    }
})