({
    doInit : function(component, event, helper) {
        component.set("v.listExistingId", []);
        component.set("v.showSpinner", true);
        var oppId = component.get("v.recordId");

        var action = component.get("c.getInitData");
        action.setParams({oppId: oppId});

        action.setCallback(this, function(response) {
            var state = response.getState();
            component.set("v.showSpinner", false);
            if (state === "SUCCESS") {
                try {
                    var oppWrapper = response.getReturnValue();

                    if (!oppWrapper.opp.Proposed_Contract_Start_Date__c || !oppWrapper.opp.Proposed_Contract_End_Date__c) {
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": 'Warning!',
                            "message": 'Please, fill contract start and end dates before adding products',
                            "type": 'warning'
                        });
                        toastEvent.fire();
                        $A.get("e.force:closeQuickAction").fire();
                    } else {
                        component.set("v.optionsFamily", oppWrapper.productFamilies);
                        component.set("v.opportunity", oppWrapper.opp);
                        component.set("v.datePeriods", oppWrapper.datePeriods);

                        if (oppWrapper.opp.Pricebook2Id) {
                            if (oppWrapper.existingProducts) {
                                var existingProds = helper.sortExistingProducts(oppWrapper.existingProducts);
                                component.set("v.existingProducts", existingProds);
                                component.set("v.flowStage", 1);
                                component.set("v.headerLabel", 'Existing products');
                                component.set("v.selectedPricebookId", oppWrapper.opp.Pricebook2Id);
                            } else {
                                component.set("v.selectedPricebookId", oppWrapper.opp.Pricebook2Id);
                                component.set("v.flowStage", 2);
                                component.set("v.headerLabel", 'Add products');
                            }
                        } else {
                            component.set("v.flowStage", 0);
                        }
                    }
                } catch (error) {
                    helper.showToast('Error!', JSON.stringify(error), 'error');
                }

            } else {
                helper.showToast('Error!', response.getError(), 'error');
            }
        });
        $A.enqueueAction(action);

    },

    handleExit : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }, 

    handleNext : function(component, event, helper) {
        var flowStage = component.get("v.flowStage");
        if (flowStage === 0 ) {
            component.set("v.showSpinner", true);
            var opp = component.get("v.opportunity");
            var selectedPrb = component.get("v.selectedPricebookId");
            console.log(component.get("v.selectedPricebookId"));
            opp.Pricebook2Id = selectedPrb;
            component.set("v.opportunity", opp);
            var action = component.get("c.updateOpportunityPricebook");
            action.setParams({opp:opp});
            
            action.setCallback(this, function(response) {
                console.log(opp);
                var state = response.getState();
                component.set("v.showSpinner", false);
                if (state === "SUCCESS") {
                    component.set("v.flowStage", 2);
                    component.set("v.headerLabel", 'Add products');
                } else {
                    helper.showToast('Error!', response.getError()[0].message, 'error');
                }
            });
            $A.enqueueAction(action);

        } else if (flowStage === 1) {
            component.set("v.showSpinner", true);
            var existingProducts = component.get("v.existingProducts");
            var actionUpdate = component.get("c.updateExistingProducts");
            actionUpdate.setParams({
                products : existingProducts
            });
            actionUpdate.setCallback(this, function(response) {
                var state = response.getState();
                component.set("v.showSpinner", false);
                if (state === "SUCCESS") {
                    component.set("v.listExistingId", response.getReturnValue());
                    var eventType = event.getSource().get("v.name");
                    if (eventType === 'SaveAndClose') {
                        helper.showToast('Success!', 'Existing products successfully updated!', 'success');
                        $A.get("e.force:closeQuickAction").fire();
                        $A.get('e.force:refreshView').fire();
                    } else if (eventType === 'SaveAndNext') {
                        helper.showToast('Success!', 'Existing products successfully updated!', 'success');
                        component.set("v.flowStage", 2);
                        component.set("v.headerLabel", 'Add products');
                    }
                } else {
                    helper.showToast('Error!', response.getError()[0].message, 'error');
                }
            });
            $A.enqueueAction(actionUpdate);
        } else
            if (flowStage === 2) {
                if (component.get("v.selectedRowsCount") > 0) {
                    component.set("v.flowStage", 3);
                    component.set("v.headerLabel", 'Edit Product Ranges');
                } else {
                    helper.showToast('Select products', 'You must select at least one product', 'error');
                }
            } else
                if (flowStage === 3) {
                    var rateSelection = component.find("rateSelection");
                    rateSelection.saveProducts();
                }
    }
})