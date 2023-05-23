({
    runEditMode : function(component, event, helper) {
        component.set("v.isEditMode", !component.get("v.isEditMode"));
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
    }

})