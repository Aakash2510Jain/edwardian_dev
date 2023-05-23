({
    doInit: function (component, event, helper) {
        var recordId = component.get("v.recordId");

        var action = component.get("c.getItems");
        action.setParams({ oppId: recordId });
        action.setCallback(this, function (response) {
            var state = response.getState();
            component.set("v.showSpinner", false);
            if (state === "SUCCESS") {
                var products = response.getReturnValue();
                if ($A.util.isEmpty(products)) {
                    helper.showToast('Warning!', 'Opportunity has no related Products!', 'warning');
                    $A.get("e.force:closeQuickAction").fire();
                } else {
                    component.set("v.showForm", true);
                    component.set("v.prodList", products);
                }
            } else {
                helper.showToast('Error!', response.getError()[0].message, 'error');
            }
        });
        $A.enqueueAction(action);
    },

    removeAll: function (component, event, helper) {
        component.set("v.showSpinner", true);
        var prods = component.get("v.prodList");

        var action = component.get("c.removeAllItems");

        action.setParams({ prods: prods });
        action.setCallback(this, function (response) {
            component.set("v.showSpinner", true);
            var state = response.getState();
            if (state === "SUCCESS") {
                helper.showToast('Success!', 'All products succesfully removed!', 'success');
                $A.get("e.force:closeQuickAction").fire();
                $A.get('e.force:refreshView').fire();
            } else {
                helper.showToast('Error!', response.getError()[0].message, 'error');
            }
        });
        $A.enqueueAction(action);
    }
})