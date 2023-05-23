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
                    this.showToast('Error!', response.getError(), 'error');
                }
            });

            $A.enqueueAction(saveAllAction);
        } catch (error) {
            this.showToast('Error!', JSON.stringify(error), 'error');
            component.set("v.showSpinner", false);
        }
    }, 

    fetchDataForSaving : function (component) {
        var productsWithRanges = component.get("v.productsWithRanges");
        var opp = component.get("v.opportunity");
        var oppLineItems = [];
        for (var prod of productsWithRanges) {
            if (!prod.toRemove) {
                if (opp.Pricing_Structure__c == 'Seasonal') {
                    for (var oneDate of prod.datePeriods) {
                        var oppItem = {'sObjectType':'OpportunityLineItem'};
                        oppItem.OpportunityId = opp.Id;
                        oppItem.Product2Id = prod.Product2Id;
                        oppItem.Product_Family__c = prod.Product2.Family;
                        oppItem.Room_Type__c = prod.Product2.Conga_Room_Type__c;
                        oppItem.Day_of_Week__c = prod.daysOfWeek === "FRI-SUN"? 'Fri - Sun': 'Mon - Thu';
                        oppItem.ListPrice = prod.UnitPrice;
                        oppItem.Breakfast_Incl__c = prod.isBreakfast;
                        oppItem.X2_Adult_List_Price__c = prod.X2_Adult_List_Price__c;
                        oppItem.X1_Adult_Price__c = oneDate.oneAdultPrice;
                        oppItem.X2_Adult_Price__c = oneDate.twoAdultPrice;
                        oppItem.From_Date__c = oneDate.startPeriodDate;
                        oppItem.To_Date__c = oneDate.endPeriodDate;
                        oppItem.Brand__c = prod.brand;
                        oppItem.Property__c = prod.property;
                        oppItem.Quantity = 1;
                        oppItem.TotalPrice = oppItem.ListPrice;
                        oppLineItems.push(oppItem);
                    }   
                } else {
                    var oppItem = { 'sObjectType' : 'OpportunityLineItem' };
                    oppItem.OpportunityId = opp.Id;
                    oppItem.PricebookEntryId = prod.preId;
                    oppItem.Product2Id = prod.Product2Id;
                    oppItem.Breakfast_Incl__c = prod.isBreakfast;
                    oppItem.From_Date__c = prod.startDate;
                    oppItem.To_Date__c = prod.endDate;
                    oppItem.Brand__c = prod.brand;
                    oppItem.Property__c = prod.property;
                    oppItem.ListPrice = prod.ListPrice;
                    oppItem.X2_Adult_List_Price__c = prod.X2_Adult_List_Price__c;
                    oppItem.X1_Adult_Price__c = prod.oneAdultPrice;
                    oppItem.X2_Adult_Price__c = prod.twoAdultPrice;
                    oppItem.Quantity = 1;
                    oppItem.Description = prod.Description;
                    oppItem.TotalPrice = oppItem.ListPrice;
                    oppItem.Product_Family__c = prod.family;
                    oppItem.Room_Type__c = prod.roomType;
                    oppLineItems.push(oppItem);
                }
            }
        }
        return oppLineItems;
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