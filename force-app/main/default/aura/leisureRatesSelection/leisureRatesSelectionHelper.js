({
    saveOpportunityLineItems: function (component) {
        try {
            component.set("v.showSpinner", true);
            var oppLineItems = this.fetchDataForSaving(component);

            var saveAllAction = component.get("c.saveLineItems");
            saveAllAction.setParams({ allLineItems: oppLineItems });
            saveAllAction.setCallback(this, function (response) {
                component.set("v.showSpinner", false);
                var state = response.getState();
                if (state === "SUCCESS") {
                    try {
                        this.showToast('Success!', 'All opportunity products successfully created!', 'success');
                        $A.get("e.force:closeQuickAction").fire();
                        $A.get('e.force:refreshView').fire();

                    } catch (error) {
                        this.showToast('Error!', JSON.stringify(error), 'error');
                    }
                } else {
                    var errors = response.getError();
                    if (errors && errors[0] && errors[0].message) {
                        this.showToast('Error!', errors[0].message, 'error');
                    }    
                }
            });

            $A.enqueueAction(saveAllAction);
        } catch (error) {
            this.showToast('Error!', JSON.stringify(error), 'error');
            component.set("v.showSpinner", false);
        }
    },

    sortNewProducts : function(productsMap, suppMap) {
        var newProdsList = [];
        var _self = this;
        var hotelKeys = Array.from(productsMap.keys());
        hotelKeys.forEach(function(key) {
            if(productsMap.size) {
                newProdsList.push.apply(newProdsList, Array.from(productsMap.get(key)));
            }
            if(suppMap.size) {
                newProdsList.push.apply(newProdsList, Array.from(suppMap.get(key)));
            }
        });
        return newProdsList;
    }, 

    fetchDataForSaving: function (component) {
        var productsWithRanges = component.get("v.productsWithRanges");
        var opp = component.get("v.opportunity");
        var oppLineItems = [];
        for (var prod of productsWithRanges) {
            if (!prod.toRemove) {
                var oppItem = { 'sObjectType': 'OpportunityLineItem' };
                oppItem.OpportunityId = opp.Id;
                oppItem.PricebookEntryId = prod.preId;
                oppItem.Product2Id = prod.Product2Id;
                oppItem.Description = prod.comments;
                oppItem.Day_of_Week__c = prod.daysOfWeek;
                oppItem.Breakfast_Incl__c = prod.isBreakfast;
                oppItem.Brand__c = prod.Brand__c;
                oppItem.ListPrice = prod.ListPrice;
                oppItem.X2_Adult_List_Price__c = prod.X2_Adult_List_Price__c;
                oppItem.X1_Adult_Price__c = prod.oneAdultPrice;
                oppItem.X2_Adult_Price__c = prod.twoAdultPrice;
                oppItem.From_Date__c = prod.startDate;
                oppItem.To_Date__c = prod.endDate;
                oppItem.Quantity = 1;
                oppItem.TotalPrice = oppItem.ListPrice;
                oppItem.Property__c = prod.property;
                oppItem.Product_Family__c = prod.family;
                oppItem.Room_Type__c = prod.roomType;
                oppLineItems.push(oppItem);
            }
        }
        return oppLineItems;
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