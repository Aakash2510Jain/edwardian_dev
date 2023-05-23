({
    doInit : function(component, event, helper) {
        debugger;
        var action = component.get("c.getObjecForRelatedContact");
        action.setParams({
            recordId: component.get("v.recordId")
        });
        action.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                var data = response.getReturnValue();
                component.set("v.bigobjectList", data);
                if (data.length > 0) {
                    component.set("v.ShowViewAll", true);
                }
            }
        });
        $A.enqueueAction(action);
    },
    
    viewAll : function(component, event, helper) {
        debugger;
        var BaseURL = $A.get("$Label.c.BigObjectVFURL");
        window.open(BaseURL + component.get("v.recordId"));
    }
})