({
    doInit: function (component, event, helper) {
        try {
            var allProducts = component.get("v.allProducts");
            var datePeriods = component.get("v.datePeriods");
            var supplementsMap = component.get("v.supplementsMap");

            var existedSup = new Map();
            var existedProds = new Map();
            for (var prod of allProducts) {
                var newData = [];
                if (prod.isSelected) {
                    var prodNew1 = prod;
                    prodNew1.prodName = prod.prodName;
                    prodNew1.startDate = prod.Product2.From_Date__c;
                    prodNew1.endDate = prod.Product2.To_Date__c;
                    prodNew1.daysOfWeek = prod.Product2.Day_of_Week__c;
                    prodNew1.oneAdultPrice = prod.UnitPrice;
                    prodNew1.twoAdultPrice = prod.X2_Adult_List_Price__c;
                    prodNew1.isBreakfast = false;
                    prodNew1.comment = '';
                    prodNew1.productId = prod.Product2Id;
                    prodNew1.Brand__c = prod.Product2.Brand__c;
                    prodNew1.ListPrice = prod.UnitPrice;
                    prodNew1.X2_Adult_List_Price__c = prod.X2_Adult_List_Price__c;
                    prodNew1.property = prod.Product2.Hotel_Property__c;
                    prodNew1.family = prod.Product2.Family;
                    prodNew1.roomType = prod.Product2.Conga_Room_Type__c;
                    prodNew1.hotel = prod.Product2.Hotel_Property__r.Short_Name__c;
                    prodNew1.toRemove = false;
                    prodNew1.preId = prod.Id;

                    if (existedProds.has(prod.Product2.Hotel_Property__c)) {
                        newData = existedProds.get(prod.Product2.Hotel_Property__c)
                    }

                    newData.push(prodNew1);
                    existedProds.set(prod.Product2.Hotel_Property__c, newData);

                    var keyMap = prod.Product2.Hotel_Property__c;
                    if (!existedSup.has(keyMap)) {
                        var currentSupplements = supplementsMap[keyMap];
                        
                        if (currentSupplements) {
                            var supList = [];
                            for (var supp of currentSupplements) {
                                var prodNew1 = {};
                                prodNew1.prodName = supp.Product2.Name;
                                prodNew1.preId = supp.Id;
                                prodNew1.dateRanges = 'SUPPLEMENT';
                                prodNew1.startDate = '';
                                prodNew1.endDate = '';
                                prodNew1.daysOfWeek = '';
                                prodNew1.oneAdultPrice = supp.UnitPrice;
                                prodNew1.twoAdultPrice = '';
                                prodNew1.isBreakfast = '';
                                prodNew1.comment = '';
                                prodNew1.productId = supp.Product2Id;
                                prodNew1.Brand__c = prod.Product2.Brand__c;
                                prodNew1.ListPrice = supp.UnitPrice;
                                prodNew1.property = supp.Product2.Hotel_Property__c;
                                prodNew1.hotel = prod.Product2.Hotel_Property__r.Short_Name__c;
                                prodNew1.family = prod.Product2.Family;
                                prodNew1.roomType = supp.Product2.Conga_Room_Type__c;
                                prodNew1.toRemove = false;
                                supList.push(prodNew1);
                            }

                            existedSup.set(keyMap, supList);
                        }
                    }
                    
                }
            }
            component.set("v.productsWithRanges", helper.sortNewProducts(existedProds, existedSup));
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
        var toRemoveId = productsWithRanges[index].property;
        for (var prod of productsWithRanges) {
            if (prod.property === toRemoveId) {
                prod.toRemove = true;
            }
        }
        component.set("v.productsWithRanges", productsWithRanges);
    }
})