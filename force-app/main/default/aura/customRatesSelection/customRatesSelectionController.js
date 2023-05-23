({
    doInit: function (component, event, helper) {
        try {
            var allProducts = component.get("v.allProducts");
            var datePeriods = component.get("v.datePeriods");
            var newData = [];
            for (var prod of allProducts) {
                if (prod.isSelected) {
                    if (component.get("v.opportunity").Pricing_Structure__c == 'Seasonal') {
                        var prodNew1 = prod;
                        prodNew1.datePeriods = JSON.parse(JSON.stringify(datePeriods));
                        prodNew1.toRemove = false;
                        for (var oneDate of prodNew1.datePeriods) {
                            oneDate.oneAdultPrice = prodNew1.UnitPrice;
                            oneDate.twoAdultPrice = prodNew1.X2_Adult_List_Price__c;
                        }
                        prodNew1.daysOfWeek = "FRI-SUN";
                        prodNew1.brand = prod.Product2.Brand__c;
                        prodNew1.property = prod.Product2.Hotel_Property__c;
                        newData.push(prodNew1);
                        var prodNew2 = JSON.parse(JSON.stringify(prodNew1));
                        prodNew1.daysOfWeek = "MON-THU";
                        newData.push(prodNew2);
                    } else {
                        var prodNew1 = prod;
                        var opportunity = component.get("v.opportunity");
                        var prodNew1 = {};
                        prodNew1.prodName = prod.prodName;
                        prodNew1.dateRanges = opportunity.Proposed_Contract_Start_Date__c + ' - ' + opportunity.Proposed_Contract_End_Date__c;
                        prodNew1.startDate = opportunity.Proposed_Contract_Start_Date__c;
                        prodNew1.endDate = opportunity.Proposed_Contract_End_Date__c;
                        prodNew1.oneAdultPrice = prod.UnitPrice;
                        prodNew1.twoAdultPrice = prod.X2_Adult_List_Price__c;
                        prodNew1.isBreakfast = false;
                        prodNew1.comment = '';
                        prodNew1.Product2Id = prod.Product2Id;
                        prodNew1.brand = prod.Product2.Brand__c;
                        prodNew1.ListPrice = prod.UnitPrice;
                        prodNew1.X2_Adult_List_Price__c = prod.X2_Adult_List_Price__c;
                        prodNew1.property = prod.Product2.Hotel_Property__c;
                        prodNew1.family = prod.Product2.Family;
                        prodNew1.roomType = prod.Product2.Conga_Room_Type__c;
                        prodNew1.toRemove = false;
                        prodNew1.preId = prod.Id;
                        newData.push(prodNew1);
                    }
                }
            }
            component.set("v.productsWithRanges", newData);

        } catch (error) {
            helper.showToast('Error!', JSON.stringify(error), 'error');
        }
    },

    saveProducts : function(component, event, helper) {
        helper.saveOpportunityLineItems(component);
    }, 

    removeRow: function (component, event, helper) {

        var index = event.getSource().get("v.name");

        var productsWithRanges = component.get("v.productsWithRanges");
        productsWithRanges[index].toRemove = true;
        if (component.get("v.opportunity").Pricing_Structure__c == 'Seasonal') {
            if (productsWithRanges[index].Product2Id == productsWithRanges[index + 1].Product2Id) {
                productsWithRanges[index + 1].toRemove = true;
            } else {
                productsWithRanges[index - 1].toRemove = true;
            }
        }
        component.set("v.productsWithRanges", productsWithRanges);
    },

    changeBreakfast: function (component, event) {
        var index = event.getSource().get("v.name");
        var products = component.get("v.productsWithRanges");
        
        products.forEach(function(prod) {
            if (prod.Product2Id == index) {
                prod.isBreakfast = event.getSource().get("v.checked");
            }
        });
        component.set("v.productsWithRanges", products);
    },
})