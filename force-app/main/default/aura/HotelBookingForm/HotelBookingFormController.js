({
    doInit : function(component, event, helper) {
        debugger;
        var action = component.get("c.getBooking");
        component.set("v.isDisabled", true);
        action.setParams({
            "recordId" : component.get("v.recordId")
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                var data = response.getReturnValue();
               /* if(data.Access_For_Setup__c != null){
                    data.Access_For_Setup__c = helper.convertMillisecondsToTimeString( component,data.Access_For_Setup__c);
                }*/
                component.set("v.BookingRec",data);
             }
         });
        $A.enqueueAction(action);
    },
   /* TimeOnchanage : function(component, event, helper){
       debugger;
        var selectedTime = event.getSource().get("v.value"); 
        console.log("Selected Time: " + selectedTime);
       component.set("v.accesstime",selectedTime);
    },*/
    updateBookDetails : function(component, event, helper){
        debugger;
        var action = component.get("c.getUpdateBookingRec");
        var updatrbookRec = component.get("v.BookingRec");
        // var acctime = component.get("v.accesstime");
       // delete updatrbookRec.nihrm__BookingContact__r;
         action.setParams({
              "recordId" : component.get("v.recordId"),
            "bookingRec": updatrbookRec
           // "accessTime":acctime
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                var data = response.getReturnValue();
                component.set("v.BookingRec", data);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title : 'Success',
                    message: 'Record has been Updated',
                    duration:' 5000',
                    key: 'info_alt',
                    type: 'success',
                    mode: 'pester'
                });
                toastEvent.fire();
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
                $A.get('e.force:refreshView').fire();s
            }
        });
      $A.enqueueAction(action);
    }
  })