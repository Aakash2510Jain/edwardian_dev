({
    runEditMode : function(component, event, helper) {
        component.set("v.isEditMode", !component.get("v.isEditMode"));
        console.log(JSON.parse(JSON.stringify(component.get("v.existingProducts"))));
    },

    removeRow : function(component, event,helper) {
        helper.handleRemoveRow(component, event);
    },

    cancelDeletions: function(component, event,helper) {
        var existingProducts = component.get("v.existingProducts");
        for (var prod of existingProducts) {
            prod.toRemove = false;
        }


        component.set("v.existingProducts", existingProducts);
        component.set("v.countRemoved", 0);
    },
    changeBreakfast: function(component, event, helper) {
        const prod = event.getSource().get("v.value");
        const breakfast = prod.prodList[0].Breakfast_Incl__c;
        prod.prodList.forEach(i => {
            i.Breakfast_Incl__c = breakfast;
        })
    }


})