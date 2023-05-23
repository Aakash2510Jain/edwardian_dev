/**
* @author [Dinesh B]
* @email dinesh.b@utilitarianLab.com
* @create date 2023-04-05 14:09:23
* @modify date 2023-04-05 14:09:23
* @desc [description]
*/

public without sharing class BatchOnIndividualEmailResult implements Database.Batchable<sObject> {
    
    Public Database.QueryLocator Start( Database.BatchableContext bc){
       
        return Database.getQueryLocator([SELECT Id,Name,CurrencyIsoCode,et4ae5__BatchId__c,et4ae5__CampaignMemberId__c,Contact_Id_18__c,CreatedDate,et4ae5__Clicked__c,et4ae5__Contact__c,et4ae5__Contact__r.Is_Related_Email_Archived__c,et4ae5__Contact__r.createdDate,et4ae5__Contact_ID__c,et4ae5__DateBounced__c,et4ae5__DateOpened__c,et4ae5__DateSent__c,et4ae5__DateUnsubscribed__c,et4ae5__Email__c,et4ae5__Email_Asset_ID__c,et4ae5__Email_ID__c,et4ae5__FromAddress__c,et4ae5__FromName__c,et4ae5__HardBounce__c	,et4ae5__JobId__c,et4ae5__Lead__c,et4ae5__Lead_ID__c,et4ae5__NumberOfUniqueClicks__c,et4ae5__ListId__c,et4ae5__MergeId__c,et4ae5__NumberOfTotalClicks__c,et4ae5__Opened__c,et4ae5__SendDefinition__c,et4ae5__SoftBounce__c,et4ae5__SubjectLine__c,et4ae5__SubscriberId__c,et4ae5__Tracking_As_Of__c,et4ae5__TriggeredSendDefinition__c,et4ae5__TriggeredSendDefinitionName__c FROM et4ae5__IndividualEmailResult__c WHERE CreatedDate < LAST_N_DAYS:90 order by CreatedDate ASC]);
    }
    public void Execute(Database.BatchableContext bc,List<et4ae5__IndividualEmailResult__c> IndiEmailResList){
        try{
            System.debug('Query Record === >'+IndiEmailResList);
            System.debug('Size of Records === >'+IndiEmailResList.size());
            if(IndiEmailResList.size() > 0){
                
                Set<id> ItFromBatchList = new Set<Id>();
                List<et4ae5__IndividualEmailResult__c> individualEmailResultToDelete = new List<et4ae5__IndividualEmailResult__c>();
                List<Archive_Individual_Email_Result__b> bigObjectListToInsert = new List<Archive_Individual_Email_Result__b>();
                List<et4ae5__IndividualEmailResult__c> individualEmailRecordListToDelete = new List<et4ae5__IndividualEmailResult__c>();
                List<Contact> conTactListTOUpdate = new List<Contact>();
                
                for(et4ae5__IndividualEmailResult__c individualEmailRecord : IndiEmailResList){
                    System.debug('Created DateTime ==== >'+individualEmailRecord.CreatedDate);
                    ItFromBatchList.add(individualEmailRecord.id);
                    Archive_Individual_Email_Result__b archievedIndivEmailRecord = new Archive_Individual_Email_Result__b();
                    archievedIndivEmailRecord.Created_Date_Time__c = individualEmailRecord.CreatedDate;
                    archievedIndivEmailRecord.Contact__c = individualEmailRecord.et4ae5__Contact__c;
                    archievedIndivEmailRecord.Contact_Id__c = individualEmailRecord.et4ae5__Contact__c;
                    archievedIndivEmailRecord.Unique_Identifier__c = integer.valueOf(System.currentTimeMillis());
                    archievedIndivEmailRecord.Email_Name__c = individualEmailRecord.Name;
                    archievedIndivEmailRecord.IndividualEmailResult_Id__c = individualEmailRecord.Id;
                    archievedIndivEmailRecord.BatchID__c = individualEmailRecord.et4ae5__BatchId__c;
                    archievedIndivEmailRecord.Campaign_Member_ID__c = individualEmailRecord.et4ae5__CampaignMemberId__c;
                    if(individualEmailRecord.et4ae5__Clicked__c){
                        archievedIndivEmailRecord.Clicked__c = 'true';
                    } else{
                        archievedIndivEmailRecord.Clicked__c = 'false';
                    }
                    archievedIndivEmailRecord.Contact_ID__c = individualEmailRecord.Contact_Id_18__c;
                    archievedIndivEmailRecord.Currency__c = individualEmailRecord.CurrencyIsoCode;
                    archievedIndivEmailRecord.Date_Bounced__c = individualEmailRecord.et4ae5__DateBounced__c;
                    archievedIndivEmailRecord.Date_Opened__c = individualEmailRecord.et4ae5__DateOpened__c;
                    archievedIndivEmailRecord.Date_Sent__c = individualEmailRecord.et4ae5__DateSent__c;
                    archievedIndivEmailRecord.Date_Unsubscribed__c = individualEmailRecord.et4ae5__DateUnsubscribed__c;
                    archievedIndivEmailRecord.Email__c = individualEmailRecord.et4ae5__Email__c;
                    archievedIndivEmailRecord.Email_Asset_ID__c = individualEmailRecord.et4ae5__Email_Asset_ID__c;
                    archievedIndivEmailRecord.Email_ID__c= individualEmailRecord.et4ae5__Email_ID__c;
                    archievedIndivEmailRecord.From_Address__c = individualEmailRecord.et4ae5__FromAddress__c;
                    archievedIndivEmailRecord.From_Name__c = individualEmailRecord.et4ae5__FromName__c;
                    if(individualEmailRecord.et4ae5__HardBounce__c){
                        archievedIndivEmailRecord.Hard_Bounce__c = 'true';
                    } else{
                        archievedIndivEmailRecord.Hard_Bounce__c = 'false';
                    }
                    archievedIndivEmailRecord.JobID__c = individualEmailRecord.et4ae5__JobId__c;
                    archievedIndivEmailRecord.Lead__c = individualEmailRecord.et4ae5__Lead__c;
                    archievedIndivEmailRecord.Lead_ID__c = individualEmailRecord.et4ae5__Lead_ID__c;
                    archievedIndivEmailRecord.Links_Clicked__c = individualEmailRecord.et4ae5__NumberOfUniqueClicks__c;
                    archievedIndivEmailRecord.ListID__c = individualEmailRecord.et4ae5__ListId__c;
                    archievedIndivEmailRecord.Merge_Id__c= individualEmailRecord.et4ae5__MergeId__c;
                    archievedIndivEmailRecord.Number_of_Total_Clicks__c = individualEmailRecord.et4ae5__NumberOfTotalClicks__c;
                    if(individualEmailRecord.et4ae5__Opened__c){
                        archievedIndivEmailRecord.Opened__c = 'true';
                    } else {
                        archievedIndivEmailRecord.Opened__c = 'false';
                    }
                    if(individualEmailRecord.et4ae5__SoftBounce__c){
                        archievedIndivEmailRecord.Soft_Bounce__c = 'true';
                    } else{
                        archievedIndivEmailRecord.Soft_Bounce__c = 'false';
                    }
                    archievedIndivEmailRecord.Subject_Line__c = individualEmailRecord.et4ae5__SubjectLine__c;
                    archievedIndivEmailRecord.SubscriberID__c = individualEmailRecord.et4ae5__SubscriberId__c;
                    archievedIndivEmailRecord.Tracking_As_Of__c = String.valueOf(individualEmailRecord.et4ae5__Tracking_As_Of__c);
                    archievedIndivEmailRecord.Triggered_Send__c = individualEmailRecord.et4ae5__TriggeredSendDefinition__c;
                    archievedIndivEmailRecord.Triggered_Send_Name__c = individualEmailRecord.et4ae5__TriggeredSendDefinitionName__c;
                    archievedIndivEmailRecord.Send_Definition__c = individualEmailRecord.et4ae5__SendDefinition__c;
                    archievedIndivEmailRecord.Email_Send__c = individualEmailRecord.et4ae5__SendDefinition__c;
                    archievedIndivEmailRecord.Name__c = individualEmailRecord.name.left(23);
                    bigObjectListToInsert.add(archievedIndivEmailRecord);
                    individualEmailResultToDelete.add(individualEmailRecord);
                    
                    Contact contactRecToUpdate = new Contact();
                    contactRecToUpdate.Id = individualEmailRecord.et4ae5__Contact__c;
                    contactRecToUpdate.Is_Related_Big_Object_Deleted__c = false;
                    conTactListTOUpdate.add(contactRecToUpdate);
                }
                if(bigObjectListToInsert.size() > 0){
                    Map<String, String> errorMap =new Map<String, String>();
                    Map<String, SObject> IdToSObjectMap = new Map<String, SObject>(); 
                    
                    if( !Test.isRunningTest()){
                        Database.SaveResult[] succesResults =  database.insertImmediate(bigObjectListToInsert);
                        System.debug('SUCCESS Big Object Record ==> '+succesResults);
                        System.debug('SUCCESS Big Object Size ==> '+succesResults.size());
                        Integer index = 0;
                        for(Database.SaveResult dsr : succesResults){
                            if(!dsr.isSuccess()){
                                for(Database.Error error : dsr.getErrors()){
                                    String errMsg = error.getMessage();
                                    errorMap.put('record '+index, errMsg);
                                    IdToSObjectMap.put('record '+index, bigObjectListToInsert[index]);
                                }
                            }
                            index++;
                        }
                    }                   
                    Set<Id> failedRecordIDList = new Set<Id>();
                    if(!errorMap.isEmpty()){
                        for(String id  : errorMap.keySet()){
                            string err = errorMap.get(id);
                            SObject sr = IdToSObjectMap.get(id); 
                            String accountString = String.ValueOf(sr);
                            String failedRecordId = accountString.substringBetween('Id=', ',');
                            failedRecordIDList.add(failedRecordId);
                        } 
                    }   
                    System.debug('failedRecordIDList === >'+failedRecordIDList); 
                    individualEmailRecordListToDelete = [SELECt Id FROM et4ae5__IndividualEmailResult__c WHERE Id IN :ItFromBatchList AND Id NOT IN : failedRecordIDList];
                    if(individualEmailRecordListToDelete.size()> 0){
                        Database.DeleteResult[] drList = Database.delete(individualEmailRecordListToDelete, false);
                        for(Database.DeleteResult dr : drList) {
                            if (dr.isSuccess()) {
                                System.debug('Successfully deleted Record with ID: ' + dr.getId());
                            }
                            else {             
                                for(Database.Error err : dr.getErrors()) {
                                    System.debug('The following error has occurred.');                    
                                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                                    System.debug('Record fields that affected this error: ' + err.getFields());
                                }
                            }
                        }
                    }
                    if(!conTactListTOUpdate.isEmpty()){
                        update conTactListTOUpdate;
                    }
                }
            }
        }catch(Exception e){
            System.debug('The Error '+e.getMessage());
            System.debug('Erron Line '+e.getLineNumber());
        }
    }
    public void Finish(Database.BatchableContext bc){
        
    }
}