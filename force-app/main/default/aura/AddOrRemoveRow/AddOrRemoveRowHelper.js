({
    addGroupSeriesRatesRecord: function(component, event) {
        debugger;
        //get the List from component  
        var grpserieslist = component.get("v.grpserieslist"); 
        var propertyStdPrice = component.get("v.propertyRecActual");
        //Add New Record
        grpserieslist.push({
            'sobjectType': 'Group_Series_Rates__c',
            'Tour_Code__c': '',
            'Date_From__c': '',
            'Date_To__c': '',
            'Double_Twin_Double_Occupancy__c': propertyStdPrice.Standard_Price_For_Double_Twin_Double__c,
            'Double_Twin_Single_Occupancy__c': propertyStdPrice.Standard_Price_For_Double_Twin_Single__c,
            'Is_Breakfast_Included__c' : false,
            'Rooms__c': '',
            'Room_Type__c': '',
            'Triple_Room_3_Adults__c': propertyStdPrice.Standard_Price_For_Triple_Room_3_Adults__c,
            'Triple_Room_2_Adults_1_Child__c': propertyStdPrice.Standard_Price_For_Triple_Room_2_Adult__c,
            'Overwrite_Standard_Price__c' : false
        });
        component.set("v.grpserieslist", grpserieslist);
    },
    
    validateGroupSeriesratesList: function(component, event) { 
        //Validate all records
        debugger;
        var grpserieslist = component.get("v.grpserieslist");
        var propertyRec = component.get("v.propertyRecActual");
        if(grpserieslist.length == 0) return true;
        for (var i = 0; i < grpserieslist.length; i++) {
            if (grpserieslist[i].Tour_Code__c != '' && grpserieslist[i].Date_From__c != '' && grpserieslist[i].Date_To__c != '' && grpserieslist[i].Rooms__c != '' && grpserieslist[i].Room_Type__c != ''){
                if(grpserieslist[i].Date_From__c > grpserieslist[i].Date_To__c) {
                    var resultsToast = $A.get("e.force:showToast");
                    resultsToast.setParams({
                        mode: 'dismissible',
                        type : 'error',
                        "message": 'Date From cannot be greater than Date To.'
                    });
                    resultsToast.fire();
                    return false;
                }
                if(grpserieslist[i].Overwrite_Standard_Price__c == true){
                    if((grpserieslist[i].Double_Twin_Double_Occupancy__c == '' || grpserieslist[i].Double_Twin_Double_Occupancy__c == null || grpserieslist[i].Double_Twin_Double_Occupancy__c == undefined)||
                       (grpserieslist[i].Double_Twin_Single_Occupancy__c == '' || grpserieslist[i].Double_Twin_Single_Occupancy__c == null || grpserieslist[i].Double_Twin_Single_Occupancy__c == undefined ) ||
                       (grpserieslist[i].Triple_Room_3_Adults__c == '' || grpserieslist[i].Triple_Room_3_Adults__c == null || grpserieslist[i].Triple_Room_3_Adults__c == undefined ) ||
                       (grpserieslist[i].Triple_Room_2_Adults_1_Child__c == '' || grpserieslist[i].Triple_Room_2_Adults_1_Child__c == null || grpserieslist[i].Triple_Room_2_Adults_1_Child__c == undefined )){
                        component.set("v.showInput",true);
                        var resultsToast = $A.get("e.force:showToast");
                        resultsToast.setParams({
                            mode: 'dismissible',
                            type : 'error',
                            "message": 'Please fill price details for rows where Overwrite Std Price = True.'
                        });
                        resultsToast.fire();
                        return false;
                    }
                }
                if((propertyRec.Standard_Price_For_Double_Twin_Double__c == '' || propertyRec.Standard_Price_For_Double_Twin_Double__c == undefined || propertyRec.Standard_Price_For_Double_Twin_Double__c == null )|| 
                   (propertyRec.Standard_Price_For_Double_Twin_Single__c == '' || propertyRec.Standard_Price_For_Double_Twin_Single__c == undefined || propertyRec.Standard_Price_For_Double_Twin_Single__c == null) ||
                   (propertyRec.Standard_Price_For_Triple_Room_2_Adult__c == '' || propertyRec.Standard_Price_For_Triple_Room_2_Adult__c == undefined || propertyRec.Standard_Price_For_Triple_Room_2_Adult__c == null) ||
                   (propertyRec.Standard_Price_For_Triple_Room_3_Adults__c == '' || propertyRec.Standard_Price_For_Triple_Room_3_Adults__c == undefined || propertyRec.Standard_Price_For_Triple_Room_3_Adults__c == null)){
                    
                    component.set("v.showInput",true);
                    var resultsToast = $A.get("e.force:showToast");
                    resultsToast.setParams({
                        mode: 'dismissible',
                        type : 'error',
                        "message": 'Please fill standard price details.'
                    });
                    resultsToast.fire();
                    return false;
                    
                }
                component.set("v.showInput",false);
                var isValid = true;
            }
            else{
                isValid = false;
                var resultsToast = $A.get("e.force:showToast");
                resultsToast.setParams({
                     mode: 'dismissible',
                     type : 'error',
                    "message": 'Please fill all the required fields or delete the row.'
                });
                resultsToast.fire();}
            
        } return isValid;
    },
    
    
    saveGroupSeriesRatesList: function(component, event, helper) {
        //Call Apex class and pass account list parameters
        debugger;
         component.set("v.spinner", true); 
        var recId = component.get("v.recordId");
        var hotelName = component.get("v.hotelName");
        var dataList = component.get("v.grpserieslist");
        var delList = component.get("v.delgrpserieslist");
        var psrRec = component.get("v.propertyRecActual");
        psrRec.Opportunity__c = recId;
        psrRec.Property__c = hotelName;
        for (let i = 0; i < dataList.length; i++) {
            if(dataList[i].Opportunity__c == '' ||  dataList[i].Opportunity__c === undefined) {
                dataList[i].Opportunity__c = recId;
                dataList[i].Hotel__c = hotelName;
            }
            if(dataList[i].Overwrite_Standard_Price__c == false){
                dataList[i].Double_Twin_Double_Occupancy__c = psrRec.Standard_Price_For_Double_Twin_Double__c;
                dataList[i].Double_Twin_Single_Occupancy__c = psrRec.Standard_Price_For_Double_Twin_Single__c;
                dataList[i].Triple_Room_3_Adults__c = psrRec.Standard_Price_For_Triple_Room_3_Adults__c;
                dataList[i].Triple_Room_2_Adults_1_Child__c = psrRec.Standard_Price_For_Triple_Room_2_Adult__c;
            }
            
        }
        var action = component.get("c.upsertAndDeleteGroupSeriesRatesRecord");
        action.setParams({
            "grpserieslist" : dataList,
            "deletegrpserieslist" : delList,
            "propertyStdPrice" : psrRec
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.spinner", false);
                component.set("v.grpserieslist", response.getReturnValue());
               
                $A.get('e.force:refreshView').fire();
                
                var resultsToast = $A.get("e.force:showToast");
                resultsToast.setParams({
                    "type"   : 'success',
                    "message": 'Records saved successfully.'
                });
                resultsToast.fire();
            }
            else if (state === "ERROR") {
                debugger;
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].pageErrors[0].message) {
                        component.set("v.showError",false);
                        console.log("Error message: " + 
                                    errors[0].pageErrors[0].message);
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": "Error!",
                            "type": 'warning',
                            "message": errors[0].pageErrors[0].message
                        });
                        toastEvent.fire();
                    }
                } else {
                    component.set("v.showError",false);
                    console.log("Unknown error");
                }
            }
        }); 
        $A.enqueueAction(action);
        
    },
    
    updatingChangedValue: function (component, event, helper){
        debugger;
        var recId = component.get("v.recordId");
        var hotelName = component.get("v.hotelName");
        var datalist = component.get("v.grpserieslist");
        var changedValue = component.get("v.propertyRecActual");
        changedValue.Opportunity__c = recId;
        changedValue.Property__c = hotelName;
        for (let i = 0; i < datalist.length; i++) {
            if(datalist[i].Overwrite_Standard_Price__c == false){
                datalist[i].Double_Twin_Double_Occupancy__c = changedValue.Standard_Price_For_Double_Twin_Double__c;
                datalist[i].Double_Twin_Single_Occupancy__c = changedValue.Standard_Price_For_Double_Twin_Single__c;
                datalist[i].Triple_Room_3_Adults__c = changedValue.Standard_Price_For_Triple_Room_3_Adults__c;
                datalist[i].Triple_Room_2_Adults_1_Child__c = changedValue.Standard_Price_For_Triple_Room_2_Adult__c;
            }
            
        }
        component.set("v.grpserieslist", datalist);
        
        //$A.get('e.force:refreshView').fire();
        
    }

})