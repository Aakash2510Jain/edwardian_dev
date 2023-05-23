import { LightningElement, api, track, wire  } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import insertRecords from '@salesforce/apex/GroupSeriesRatesController.insertRecords';
import { getRecord } from 'lightning/uiRecordApi';

export default class GroupSeriesRatesComponent extends LightningElement {
    @api recordId;
    groupSeriesEmptyRecord = {
        "sobjectType": "Group_Series_Rates__c",
        "Opportunity__c" : "",
        "Hotel__c" : "",
        "Tour_Code__c" : "",
        "Date_From__c" : "",
        "Date_To__c" : "",
        "Rooms__c" : "",
        "Double_Twin_Single_Occupancy__c" : "",
        "Double_Twin_Double_Occupancy__c" : "",
        "Triple_Room_2_Adults_1_Child__c" : "",
        "Triple_Room_3_Adults__c" : "",
        "isOverwrite" : false
    };
    groupSeriesEmptyRecordString = JSON.stringify(this.groupSeriesEmptyRecord);
    //Initialize first four empty records
    @track
    groupSeriesRatesList = this.initializeEmptyRecords();
    adjustHeightForDatePickerClass = "slds-hide";
    closeResizeDiv = false;

    @wire(getRecord, { recordId: '$recordId', fields: 'Opportunity.Name' })
    contact;

    get name() {
        if(this.contact.data)return this.contact.data.fields.Name.value;
        else return '';
        
    }
    
    initializeEmptyRecords(){
        return [this.cloneGroupSeriesEmptyRecord(),
            this.cloneGroupSeriesEmptyRecord(),
            this.cloneGroupSeriesEmptyRecord(),
            this.cloneGroupSeriesEmptyRecord()];
    }
    initializeStandardRates(){
        this.template.querySelector('[data-id="Hotel__c"]').value = null;
        this.template.querySelector('[data-id="Double_Twin_Single_Occupancy__c"]').value = null;
        this.template.querySelector('[data-id="Double_Twin_Double_Occupancy__c"]').value = null;
        this.template.querySelector('[data-id="Triple_Room_2_Adults_1_Child__c"]').value = null;
        this.template.querySelector('[data-id="Triple_Room_3_Adults__c"]').value = null;            
    }

    cloneGroupSeriesEmptyRecord(){
        var emptyRecord = JSON.parse(this.groupSeriesEmptyRecordString);
        emptyRecord.key = Math.random();
        return emptyRecord;
    }
    handleResize(event){
        if(event.currentTarget.dataset.index==0)this.adjustHeightForDatePickerClass = "slds-show";
        this.closeResizeDiv = false;
    }
    handleOnFocusOut(event){
        this.closeResizeDiv = true;
    }
    closeResizeElement(){
        if(this.closeResizeDiv)this.adjustHeightForDatePickerClass = "slds-hide";
    }
    handleOnChange(event){
        let index = event.currentTarget.dataset.index;
        let fieldName = event.currentTarget.dataset.field;
        let value = event.currentTarget.value;
        this.groupSeriesRatesList[index][fieldName] = value;
        if(index==0 && (fieldName=="Date_From__c" || fieldName=="Date_To__c")){
            this.adjustHeightForDatePickerClass = "slds-hide";
            this.closeResizeDiv = false;
        }
        if((fieldName=="Date_From__c" || fieldName=="Date_To__c") && value){
            this.template.querySelector(`[data-index="${index}"][data-field="${fieldName}"]`).className = "";
        }
    }
    handleOnChangeCheckbox(event){
        let index = event.currentTarget.dataset.index;
        let setValue = !event.currentTarget.checked;
        this.groupSeriesRatesList[index]["isOverwrite"] = event.currentTarget.checked;
        this.template.querySelector(`[data-index="${index}"][data-field="Double_Twin_Single_Occupancy__c"]`).disabled = setValue;
        this.template.querySelector(`[data-index="${index}"][data-field="Double_Twin_Double_Occupancy__c"]`).disabled = setValue;
        this.template.querySelector(`[data-index="${index}"][data-field="Triple_Room_2_Adults_1_Child__c"]`).disabled = setValue;
        this.template.querySelector(`[data-index="${index}"][data-field="Triple_Room_3_Adults__c"]`).disabled = setValue;

    }
    addRow(){
        this.groupSeriesRatesList.push(this.cloneGroupSeriesEmptyRecord());
    }
    handleCancel(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    handleError(event){
        event.preventDefault();
        event.stopImmediatePropagation();
    }
    clearFieldErrorAttributes(){
        this.template.querySelectorAll('lightning-input-field').forEach(element => {
            if(element.dataset.id!="Hotel__c")element.required = false;
        });
        this.template.querySelectorAll('lightning-input').forEach(element => {
            element.className = "";
        });
        
    }
    setErrorOnElement(index,fieldName){
        this.template.querySelector(`[data-index="${index}"][data-field="${fieldName}"]`).className = "slds-has-error";
    }
    getRecordsToSave(){
        var recordsToSave = [];
        var hasErrors = false;
        var submitForm = false;
        var hotelValue = this.template.querySelector('[data-id="Hotel__c"]').value;
        var twinSingleValue = this.template.querySelector('[data-id="Double_Twin_Single_Occupancy__c"]').value;
        var twinDoubleValue = this.template.querySelector('[data-id="Double_Twin_Double_Occupancy__c"]').value;
        var tripleAdultsAndChildValue = this.template.querySelector('[data-id="Triple_Room_2_Adults_1_Child__c"]').value;
        var tripleAdultsValue = this.template.querySelector('[data-id="Triple_Room_3_Adults__c"]').value;

        this.clearFieldErrorAttributes();

        if(!hotelValue){
            submitForm = true;
            hasErrors = true;
        }
        //Create Deep Copy to avoid issues due pass by reference.]
        var deepCopyArray = JSON.parse(JSON.stringify(this.groupSeriesRatesList));
        for (var i = 0; i < deepCopyArray.length; i++){
            var record = deepCopyArray[i];
            var skipIteration = false;
            var hasRecord = record.Tour_Code__c || record.Date_From__c || record.Date_To__c || record.Rooms__c;
            if(hasRecord && (!record.Tour_Code__c || !record.Date_From__c || !record.Date_To__c || !record.Rooms__c)){
                if(!record.Tour_Code__c){
                    this.setErrorOnElement(i,"Tour_Code__c");
                }
                if(!record.Date_From__c){
                    this.setErrorOnElement(i,"Date_From__c");
                }
                if(!record.Date_To__c){
                    this.setErrorOnElement(i,"Date_To__c");
                }
                if(!record.Rooms__c){
                    this.setErrorOnElement(i,"Rooms__c");
                }
                hasErrors = true;
                skipIteration = true;
            }
            if(hasRecord && !record.isOverwrite && (!twinSingleValue || !twinDoubleValue || !tripleAdultsAndChildValue || !tripleAdultsValue)){
                if(!twinSingleValue){
                    this.template.querySelector('[data-id="Double_Twin_Single_Occupancy__c"]').required = true;
                }
                if(!twinDoubleValue){
                    this.template.querySelector('[data-id="Double_Twin_Double_Occupancy__c"]').required = true;
                }
                if(!tripleAdultsAndChildValue){
                    this.template.querySelector('[data-id="Triple_Room_2_Adults_1_Child__c"]').required = true;
                }
                if(!tripleAdultsValue){
                    this.template.querySelector('[data-id="Triple_Room_3_Adults__c"]').required = true;
                }
                hasErrors = true;
                submitForm = true;
                skipIteration = true;
            }

            if(hasRecord && record.isOverwrite && (!record.Double_Twin_Single_Occupancy__c || !record.Double_Twin_Double_Occupancy__c || !record.Triple_Room_2_Adults_1_Child__c || !record.Triple_Room_3_Adults__c)){
                if(!record.Double_Twin_Single_Occupancy__c){
                    this.setErrorOnElement(i,"Double_Twin_Single_Occupancy__c");
                }  
                if(!record.Double_Twin_Double_Occupancy__c){
                    this.setErrorOnElement(i,"Double_Twin_Double_Occupancy__c");
                }
                if(!record.Triple_Room_2_Adults_1_Child__c){
                    this.setErrorOnElement(i,"Triple_Room_2_Adults_1_Child__c");
                }
                if(!record.Triple_Room_3_Adults__c){
                    this.setErrorOnElement(i,"Triple_Room_3_Adults__c");
                }      
                hasErrors = true;
                skipIteration = true;
            }
            if(skipIteration)continue;

            if(hasRecord && !hasErrors){
                record.Opportunity__c = this.recordId;
                record.Hotel__c = hotelValue;
                if(!record.isOverwrite){
                    record.Double_Twin_Single_Occupancy__c = twinSingleValue;
                    record.Double_Twin_Double_Occupancy__c = twinDoubleValue;
                    record.Triple_Room_2_Adults_1_Child__c = tripleAdultsAndChildValue;
                    record.Triple_Room_3_Adults__c = tripleAdultsValue;
                }
                delete record.isOverwrite;
                delete record.key;
                recordsToSave.push(record);
            }
        }
        if(submitForm)this.template.querySelector('[data-id="lightningForm"]').submit();
        if(hasErrors)return [];
        else return recordsToSave;
    }
    handleSaveAndNew(){
        var recordsToSave = this.getRecordsToSave();
        if(recordsToSave.length!=0){
            insertRecords({ recordsList: recordsToSave })
            .then((result) => {
                if(result)this.fireToastEvent("Success!","Group Series Rates records created successfully.","success");
                else this.fireToastEvent("Error!","Unable to create records.","error");
                this.groupSeriesRatesList = this.initializeEmptyRecords();
                this.initializeStandardRates();
            })
            .catch((error) => {
                this.fireToastEvent("Error!","Unable to create records.","error");
                this.groupSeriesRatesList = this.initializeEmptyRecords();
                this.initializeStandardRates();
            });
        }else {
            this.fireToastEvent("Error!","Please fill all the fields to save the records.","error");
        }         
    }
    handleSave(){
        var recordsToSave = this.getRecordsToSave();
        if(recordsToSave.length!=0){
            insertRecords({ recordsList: recordsToSave })
            .then((result) => {
                if(result){
                    this.fireToastEvent("Success!","Group Series Rates records created successfully.","success");
                    this.dispatchEvent(new CloseActionScreenEvent());
                }
                else {
                    this.fireToastEvent("Error!","Unable to create records.","error");
                    this.dispatchEvent(new CloseActionScreenEvent());
                }
            })
            .catch((error) => {
                this.fireToastEvent("Error!","Unable to create records.","error");
            });
        }else {
            this.fireToastEvent("Error!","Please fill all the fields to save the records.","error");
        } 
    }

    fireToastEvent(title,message,variant){
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}