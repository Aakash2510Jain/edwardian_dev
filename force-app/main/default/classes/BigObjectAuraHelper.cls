/**
 * @author [Dinesh B]
 * @email dinesh.b@utilitarianLab.com
 * @create date 2023-04-07 12:27:21
 * @modify date 2023-04-07 12:27:21
 * @desc [description]
 */

public without sharing class BigObjectAuraHelper {

 
    // Show All Bigobject Related Record to Person Account / Contact
    @AuraEnabled
    public Static List<Archive_Individual_Email_Result__b> getContacRelatedBigObjectsForAura(String recordId){
        if(!String.isBlank(recordId)){
            try{
                set<Id> contactIds = new Set<Id>();
                List<Archive_Individual_Email_Result__b	>  getBigObjectList = new List<Archive_Individual_Email_Result__b	> ();
                List<Contact> contactList = new List<Contact>();
                Id myId = recordId;
                String sObjName = myId.getSObjectType().getDescribe().getName();
                if(sObjName == 'Account'){
                     contactList = [select id,AccountId from Contact where AccountId =:recordId];
                    if(!contactList.isEmpty()){
                        for(Contact conRecord : contactList){
                            contactIds.add(conRecord.Id);
                        }
                        if(!contactIds.isEmpty()){
                            getBigObjectList = [SELECT BatchID__c,Campaign_Member_ID__c,Clicked__c,Contact_Id__c,Contact__c,CreatedById,CreatedDate,Created_Date_Time__c,Currency__c,Date_Bounced__c,Date_Opened__c,Date_Sent__c,Date_Unsubscribed__c,Email_Asset_ID__c,Email_ID__c,Email_Name__c,Email_Send__c,Email__c,From_Address__c,From_Name__c,Hard_Bounce__c,Id,IndividualEmailResult_Id__c,JobID__c,Lead_ID__c,Lead__c,Links_Clicked__c,ListID__c,Merge_Id__c,Name__c,Number_of_Total_Clicks__c,Opened__c,Send_Definition__c,Soft_Bounce__c,Subject_Line__c,SubscriberID__c,SystemModstamp,Tracking_As_Of__c,Triggered_Send_Name__c,Triggered_Send__c,Unique_Identifier__c FROM Archive_Individual_Email_Result__b WHERE  Contact_Id__c in: contactIds order by Created_Date_Time__c DESC ];
                            System.debug('getBigObjectList on Account Size ==>'+getBigObjectList.size());
                            if(getBigObjectList.size() > 0){
                                return getBigObjectList;
                            }
                        }
                    }
                }
                else if(sObjName == 'Contact'){
                    if(!String.isBlank(recordId)){
                        getBigObjectList = [SELECT BatchID__c,Campaign_Member_ID__c,Clicked__c,Contact_Id__c,Contact__c,CreatedById,CreatedDate,Created_Date_Time__c,Currency__c,Date_Bounced__c,Date_Opened__c,Date_Sent__c,Date_Unsubscribed__c,Email_Asset_ID__c,Email_ID__c,Email_Name__c,Email_Send__c,Email__c,From_Address__c,From_Name__c,Hard_Bounce__c,Id,IndividualEmailResult_Id__c,JobID__c,Lead_ID__c,Lead__c,Links_Clicked__c,ListID__c,Merge_Id__c,Name__c,Number_of_Total_Clicks__c,Opened__c,Send_Definition__c,Soft_Bounce__c,Subject_Line__c,SubscriberID__c,SystemModstamp,Tracking_As_Of__c,Triggered_Send_Name__c,Triggered_Send__c,Unique_Identifier__c FROM Archive_Individual_Email_Result__b WHERE Contact_Id__c =: recordId order by Created_Date_Time__c DESC ];
                        System.debug('getBigObjectList on Contact Size ==>'+getBigObjectList.size());
                        if(getBigObjectList.size() > 0){
                            return getBigObjectList;
                        }   
                    }
                }
            }catch(Exception e){
                System.debug('Error Message ==>'+e.getMessage() + ' && Error Line ===>'+e.getLineNumber());
            }
        }
        return null;
    }

   // Record Details page Showing 5 big object Records in Aura Comp
    @AuraEnabled
    public Static List<Archive_Individual_Email_Result__b> getObjecForRelatedContact(String recordId){
       if(!String.isBlank(recordId)){
        System.debug('recordId === >'+recordId);
        try{
            contact conRec = new Contact();
            Id myId = recordId;
            String sObjName = myId.getSObjectType().getDescribe().getName();
            System.debug('sObjName == >'+sObjName);
            List<Archive_Individual_Email_Result__b> getObjectList = new List<Archive_Individual_Email_Result__b>();
            if(sObjName == 'Account'){
                string contactId = [select id,AccountId from Contact where AccountId =:recordId].Id;
                if(!String.isBlank(contactId)){
                    Set<DateTime> datTimeSet = new Set<DateTime>();
                    Set<String> contactIdSet = new Set<String>{contactId};
                     getObjectList = [SELECT BatchID__c,Campaign_Member_ID__c,Clicked__c,Contact_Id__c,Contact__c,CreatedById,CreatedDate,Created_Date_Time__c,Currency__c,Date_Bounced__c,Date_Opened__c,Date_Sent__c,Date_Unsubscribed__c,Email_Asset_ID__c,Email_ID__c,Email_Name__c,Email_Send__c,Email__c,From_Address__c,From_Name__c,Hard_Bounce__c,Id,IndividualEmailResult_Id__c,JobID__c,Lead_ID__c,Lead__c,Links_Clicked__c,ListID__c,Merge_Id__c,Name__c,Number_of_Total_Clicks__c,Opened__c,Send_Definition__c,Soft_Bounce__c,Subject_Line__c,SubscriberID__c,SystemModstamp,Tracking_As_Of__c,Triggered_Send_Name__c,Triggered_Send__c,Unique_Identifier__c FROM Archive_Individual_Email_Result__b WHERE  Contact_Id__c =: contactId order by Created_Date_Time__c DESC  LIMIT 5];
                    System.debug('getObjectList Size == >'+getObjectList);
                    if(getObjectList.size() > 0){
                        return getObjectList;
                    }
                     }
            }
            else if(sObjName == 'Contact'){
                if(!String.isBlank(recordId)){
                    conRec = [SELECT id,Name,CreatedDate FROM Contact where Id =:recordId LIMIT 1]; 
                    Set<String> contactIdSet = new Set<String>{recordId};
                    getObjectList = [SELECT BatchID__c,Campaign_Member_ID__c,Clicked__c,Contact_Id__c,Contact__c,CreatedById,CreatedDate,Created_Date_Time__c,Currency__c,Date_Bounced__c,Date_Opened__c,Date_Sent__c,Date_Unsubscribed__c,Email_Asset_ID__c,Email_ID__c,Email_Name__c,Email_Send__c,Email__c,From_Address__c,From_Name__c,Hard_Bounce__c,Id,IndividualEmailResult_Id__c,JobID__c,Lead_ID__c,Lead__c,Links_Clicked__c,ListID__c,Merge_Id__c,Name__c,Number_of_Total_Clicks__c,Opened__c,Send_Definition__c,Soft_Bounce__c,Subject_Line__c,SubscriberID__c,SystemModstamp,Tracking_As_Of__c,Triggered_Send_Name__c,Triggered_Send__c,Unique_Identifier__c FROM Archive_Individual_Email_Result__b WHERE  Contact_Id__c =: recordId  order by Created_Date_Time__c DESC  LIMIT 5];
                    System.debug('getObjectList Size == >'+getObjectList.size());
                    if(getObjectList.size() > 0){
                        return getObjectList;
                    }
                     }
            }
            return null;
        }catch(Exception e){
            System.debug('Error Message ==>'+e.getMessage() + ' && Error Line ===>'+e.getLineNumber());
        }
       }
        return null;
    }


}