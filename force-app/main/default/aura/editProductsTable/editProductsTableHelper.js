({
    handleRemoveRow : function(component, event) {
        var index = event.getSource().get("v.name");
        var existingProducts = component.get("v.existingProducts");
        if (component.get("v.opportunity").Pricing_Structure__c == 'Seasonal') {
            existingProducts[index].toRemove = true;
            if (existingProducts[index].productId === existingProducts[index + 1].productId) {
                existingProducts[index + 1].toRemove = true;
            } else {
                existingProducts[index - 1].toRemove = true;
            }
            component.set("v.countRemoved", component.get("v.countRemoved") + 2);
        } else {
            existingProducts[index].toRemove = true;
            component.set("v.countRemoved", component.get("v.countRemoved") + 1);
        }
        component.set("v.existingProducts", existingProducts);

    }
})