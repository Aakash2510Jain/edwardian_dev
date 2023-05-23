({
    doInit : function(component, event, helper) {
        debugger;
        var action = component.get("c.getCurrentBookingDetails");
         component.set("v.isDisabled", true);
        action.setParams({
            "recordId" : component.get("v.recordId")
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                var data = response.getReturnValue();
                 if(data.Coffee_Tea__c == true){
                    component.set("v.selectedCoffeeValue","True");
                }else if(data.Coffee_Tea__c == false){
                    component.set("v.selectedCoffeeValue","False");
                }
                 if(data.Soft_Drinks__c == true){
                    component.set("v.selectedDrinksValue","True");
                }else if(data.Soft_Drinks__c == false){
                    component.set("v.selectedDrinksValue","False");
                }
                 if(data.Laptop_Hire__c == true){
                    component.set("v.selectedLaptopvalue","True");
                }else if(data.Laptop_Hire__c == false){
                    component.set("v.selectedLaptopvalue","False");
                }
                
               if(data.Arrival__c != null){
                    data.Arrival__c = helper.convertMillisecondsToTimeString( component,data.Arrival__c);
                }
                 if(data.Access_For_Setup__c != null){
                    data.Access_For_Setup__c = helper.convertMillisecondsToTimeString( component,data.Access_For_Setup__c);
                }
                if(data.Breaks__c != null){
                    data.Breaks__c = helper.convertMillisecondsToTimeString(component, data.Breaks__c);
                }
                if(data.Lunch__c != null){
                    data.Lunch__c = helper.convertMillisecondsToTimeString(component, data.Lunch__c);
                }
                
                if(data.Finish__c != null){
                    data.Finish__c = helper.convertMillisecondsToTimeString(component,data.Finish__c);
                }
                if(data.Other__c != null){
                    data.Other__c = helper.convertMillisecondsToTimeString(component,data.Other__c);
                }
                
                component.set("v.BookingRec", data); 
                
            }
            else if(state === "ERROR"){e
            var errors = action.getError();
                                       if (errors) {
                                           if (errors[0] && errors[0].message) {
                                               alert(errors[0].message);
                                           }
                                       }
                                      }else if (status === "INCOMPLETE") {
                                          alert('No response from server or client is offline.');
                                      }
        });
        $A.enqueueAction(action);
    },
    
    updateBookDetails : function(component, event, helper){
        debugger;
        var action = component.get("c.UpdateBookingDetails");
        var bookrec = component.get("v.BookingRec");
        //delete bookrec.nihrm__BookingContact__r;
               
        var coffevalue = component.get("v.selectedCoffeeValue");
        var drinkvalue = component.get("v.selectedDrinksValue");
        var laptopvalue = component.get("v.selectedLaptopvalue");
        action.setParams({
            "recordId" : component.get("v.recordId"),
            "bookingRec" : bookrec,
            "Coffeevalue" : coffevalue,
            "Drinksvalue" : drinkvalue,
            "Laptopvalue" : laptopvalue
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                var data = response.getReturnValue();
                component.set("v.BookingRec", data);
                 var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title : 'Success',
                    message: 'This is a success message',
                    duration:' 5000',
                    key: 'info_alt',
                    type: 'success',
                    mode: 'pester'
                });
                toastEvent.fire();
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
                $A.get('e.force:refreshView').fire();
            }else if(state === "ERROR"){
                var errors = action.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        alert(errors[0].message);
                    }
                }
            }else if (status === "INCOMPLETE") {
                alert('No response from server or client is offline.');
            }
        });
          $A.enqueueAction(action);
    },
    
    TimeOnchanage : function(component, event, helper) {
        debugger;
        var data = component.find("timeInput").get("v.value");
    },
})