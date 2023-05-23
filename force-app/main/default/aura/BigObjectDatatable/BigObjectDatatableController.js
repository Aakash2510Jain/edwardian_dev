({
    doInit : function(component, event, helper) {
        component.set('v.columns', [
            
            // {label: 'Campaign Member ID', fieldName: 'Campaign_Member_ID__c', type: 'text'},
            {label: 'Clicked', fieldName: 'Clicked__c', type: 'text'},
            //  {label: 'Contact CurrentTimeInstance', fieldName: 'Contact_CurrentTimeInstance__c', type: 'text'},
            {label: 'Date Bounced', fieldName: 'Date_Bounced__c', type: 'text'},
            //   {label: 'Date Opened', fieldName: 'Date_Opened__c', type: 'text'},
            
            {label: 'Date Sent', fieldName: 'Date_Sent__c', type: 'text'},
            //  {label: 'Date Unsubscribed', fieldName: 'Date_Unsubscribed__c', type: 'text'},
            {label: 'Email Asset ID', fieldName: 'Email_Asset_ID__c', type: 'text'},
            {label: 'Email ID', fieldName: 'Email_ID__c', type: 'text'},
            {label: 'Email Name', fieldName: 'Email_Name__c', type: 'text'},
            //  {label: 'Email Send', fieldName: 'Email_Send__c', type: 'text'},
            {label: 'Email', fieldName: 'Email__c', type: 'text'},
            {label: 'From Address', fieldName: 'From_Address__c', type: 'text'},
            
            
            {label: 'From Name', fieldName: 'From_Name__c', type: 'text'},
            {label: 'Hard Bounce', fieldName: 'Hard_Bounce__c', type: 'text'},
            // {label: 'Links Clicked', fieldName: 'Links_Clicked__c', type: 'text'},
            //  {label: 'ListID', fieldName: 'ListID__c', type: 'text'},
            //  {label: 'Merge Id', fieldName: 'Merge_Id__c', type: 'text'},
            
            // {label: 'Number of Total Clicks', fieldName: 'Number_of_Total_Clicks__c', type: 'text'},
            {label: 'Opened', fieldName: 'Opened__c', type: 'text'},
            //   {label: 'Send Definition', fieldName: 'Send_Definition__c', type: 'text'},
            {label: 'Soft Bounce', fieldName: 'Soft_Bounce__c', type: 'text'},
            {label: 'Subject Line', fieldName: 'Subject_Line__c', type: 'text'},
            //  {label: 'SubscriberID', fieldName: 'SubscriberID__c', type: 'text'},
            {label: 'Tracking As Of', fieldName: 'Tracking_As_Of__c', type: 'text'},
            {label: 'Triggered Send Name', fieldName: 'Triggered_Send_Name__c', type: 'text'}
            //  {label: 'Triggered Send', fieldName: 'Triggered_Send__c', type: 'text'}
            
        ]);
        helper.fetchAccounts(component, helper);
        
    },
    
    
    updateSorting: function (cmp, event, helper) {
        debugger;
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        cmp.set("v.sortedBy", fieldName);
        cmp.set("v.sortedDirection", sortDirection);
        helper.sortData(cmp, fieldName, sortDirection);
    },
    
    handleNext: function(component, event, helper){     
        debugger;
        component.set("v.currentPageNumber", component.get("v.currentPageNumber") + 1);
        helper.setPaginateData(component);
    },
    
    handlePrevious: function(component, event, helper){
        debugger;
        component.set("v.currentPageNumber", component.get("v.currentPageNumber") - 1);
        helper.setPaginateData(component);
    },
    
    onFirst: function(component, event, helper) {   
        debugger;
        component.set("v.currentPageNumber", 1);
        helper.setPaginateData(component);
    },
    
    onLast: function(component, event, helper) {  
        debugger;
        component.set("v.currentPageNumber", component.get("v.totalPages"));
        helper.setPaginateData(component);
    },
    
    
})