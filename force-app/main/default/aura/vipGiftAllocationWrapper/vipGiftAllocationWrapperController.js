({
	doInit: function(component, event, helper){
        var pageReference = component.get("v.pageReference");
        if(pageReference!==undefined && pageReference!==null && pageReference.state!=null)
        {
            var recordId=pageReference.state.c__recordId;
            component.set("v.recordId",recordId);
        }
    },

	close: function(component, event, helper) {
		$A.get("e.force:closeQuickAction").fire();
	}
})