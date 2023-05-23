({
    addRow: function(component, event, helper) {
        helper.addGroupSeriesRatesRecord(component, event);
    },
    
    fetchgrpSeriesRates : function(component, event, helper) {
        debugger;
        var propRec = component.get("v.propertyRec");
        var Hotelname = component.get("v.hotelName");
        var DynamicLabel = 'Save ' + Hotelname + ' Record'; 
        component.set("v.dynamicSaveLabel", DynamicLabel);
        var propRecData  = propRec[Hotelname];
        component.set("v.propertyRecActual", propRecData);
        
        
        var grpserieslist = component.get("v.grpserieslist");
        for (let i = 0; i < grpserieslist.length; i++) {
            if(grpserieslist[i].Double_Twin_Double_Occupancy__c == '' || grpserieslist[i].Double_Twin_Double_Occupancy__c == null ||grpserieslist[i].Double_Twin_Double_Occupancy__c == undefined  ){
                grpserieslist[i].Double_Twin_Double_Occupancy__c = propRecData.Standard_Price_For_Double_Twin_Double__c;
            }
            if(grpserieslist[i].Double_Twin_Single_Occupancy__c == '' || grpserieslist[i].Double_Twin_Single_Occupancy__c == null ||grpserieslist[i].Double_Twin_Single_Occupancy__c == undefined  ){
                grpserieslist[i].Double_Twin_Single_Occupancy__c = propRecData.Standard_Price_For_Double_Twin_Single__c;
            }
            if(grpserieslist[i].Triple_Room_2_Adults_1_Child__c == '' || grpserieslist[i].Triple_Room_2_Adults_1_Child__c == null ||grpserieslist[i].Triple_Room_2_Adults_1_Child__c == undefined  ){
                grpserieslist[i].Triple_Room_2_Adults_1_Child__c = propRecData.Standard_Price_For_Triple_Room_2_Adult__c;
            }
            if(grpserieslist[i].Triple_Room_3_Adults__c == '' || grpserieslist[i].Triple_Room_3_Adults__c == null ||grpserieslist[i].Triple_Room_3_Adults__c == undefined  ){
                grpserieslist[i].Triple_Room_3_Adults__c = propRecData.Standard_Price_For_Triple_Room_3_Adults__c;
            }
        }      
        if(grpserieslist.length >= 0 && grpserieslist.length < 1){
            var grpSeriesLength = grpserieslist.length;
            //for (let i = 0; i <= 5 - grpserieslist.length ; i++) {
            for (let i = 0; i < 1 - grpSeriesLength ; i++) {   
                
                     grpserieslist.push({
                    'sobjectType': 'Group_Series_Rates__c',
                    'Tour_Code__c': '',
                    'Date_From__c': '',
                    'Date_To__c': '',
                    'Double_Twin_Double_Occupancy__c': propRecData.Standard_Price_For_Double_Twin_Double__c,
                    'Double_Twin_Single_Occupancy__c': propRecData.Standard_Price_For_Double_Twin_Single__c,
                    'Rooms__c': '',
                    'Room_Type__c': '',
                    'Triple_Room_3_Adults__c': propRecData.Standard_Price_For_Triple_Room_3_Adults__c,
                    'Triple_Room_2_Adults_1_Child__c': propRecData.Standard_Price_For_Triple_Room_2_Adult__c,
                    'Overwrite_Standard_Price__c' : false,
                    'Is_Breakfast_Included__c' : false,
                    'Opportunity__c' : '',
                    'Hotel__c' : ''
                    });                              
                }   
        }
        component.set("v.grpserieslist", grpserieslist);
    },
    
     handleChange: function (component, event, helper) {
        helper.updatingChangedValue(component, event);
     },
    
    removeRow: function(component, event, helper) {
        //Get the list
        var grpserieslist = component.get("v.grpserieslist");
        //Get the target object
        var selectedItem = event.currentTarget;
        //Get the selected item index
        var index = selectedItem.dataset.record;
        grpserieslist.splice(index, 1);
        component.set("v.grpserieslist", grpserieslist);
        
        var selectedId = event.currentTarget.id;
        
        var delgrpserieslist = component.get("v.delgrpserieslist");
        
        if(selectedId != undefined && selectedId != null && selectedId != '')
        {
            delgrpserieslist.push(selectedId);            
        }
        component.set("v.delgrpserieslist", delgrpserieslist);
    },
    
    save: function(component, event, helper) {
        debugger;
        if (helper.validateGroupSeriesratesList(component, event)) {
            helper.saveGroupSeriesRatesList(component, event);
        }
    },
    
    allowInput: function(component, event, helper) {
        debugger;
        var grpserieslist = component.get("v.grpserieslist");
        var rowIndex = event.target.id; 
        var row = parseInt(rowIndex);
        
        if(grpserieslist[row].Overwrite_Standard_Price__c == true){
            grpserieslist[row].Overwrite_Standard_Price__c = false;
            component.set("v.grpserieslist",grpserieslist);
        }
        else{
            grpserieslist[row].Overwrite_Standard_Price__c = true;
            component.set("v.grpserieslist",grpserieslist);  
        }
        
    },
    
    cancelGroupSeriesRates: function(component, event, helper) {
        debugger;
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();       
    },
    
    showSpinner: function(component, event, helper) {
        component.set("v.spinner", true); 
    },
    
    hideSpinner : function(component,event,helper){
        component.set("v.spinner", false);
    }
    
})