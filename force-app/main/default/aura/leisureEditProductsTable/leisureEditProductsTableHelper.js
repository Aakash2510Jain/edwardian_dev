({
    handleRemoveRow : function(component, event) {
        var index = event.getSource().get("v.name");
        var existingProducts = component.get("v.existingProducts");
        var propertyToRemove = existingProducts[index].Product2.Hotel_Property__c;
        var countRem = 0;
        for (var prod of existingProducts) {
            if (prod.Product2.Hotel_Property__c === propertyToRemove) {
                prod.toRemove = true;
                countRem++;
            }
        }

        component.set("v.existingProducts", existingProducts);
        component.set("v.countRemoved", component.get("v.countRemoved") + countRem);
    }
})