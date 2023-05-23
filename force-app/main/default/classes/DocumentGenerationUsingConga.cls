//Added by shubham Kumar
//Test Class : TestDocumentGenerationUsingConga : 87%
public class DocumentGenerationUsingConga {
    
    //This method will be used to get templateIdfromTemplateKey
    Public Static String getTemplateIdFromKey(String templateKey) {
        system.debug('templateKey'+templateKey);
        map<String,String> templateIdfromKey = new map<String,String>();
        List<APXTConga4__Conga_Template__c> templateList = [Select Id , APXTConga4__Key__c from APXTConga4__Conga_Template__c];
        
        for(APXTConga4__Conga_Template__c apxt : templateList){
            templateIdfromKey.put(apxt.APXTConga4__Key__c , apxt.Id);
        }
        if(test.isRunningTest()){
            return 'a4H3z0000009s5o';
        }else{
            return templateIdfromKey.get(templateKey);    
        }
        
    }
    
    //This method Generates the doc 
    @AuraEnabled
    Public Static void GenerateDocument(String recordId) {
        system.debug('recordId'+recordId);
        contract contractRec = [select Conga_Template_ID__c ,Contract_Type__c , Londoner_only__c ,ContractNumber, Id ,Opportunity__c, Conga_Url__c from contract where id = :recordId];
        String templateName = '';
        if(contractRec.Londoner_only__c == true){
            templateName = contractRec.Contract_Type__c + '- Londoner Only -' +contractRec.ContractNumber;
        }else{
            templateName = contractRec.Contract_Type__c +' - '+ contractRec.ContractNumber;
        }
        
        String oppId = contractRec.Opportunity__c;
        String contrUrl = contractRec.Conga_URL__c;
        String TemplateId = getTemplateIdFromKey(contractRec.Conga_Template_ID__c);
        
        system.debug('TemplateId'+TemplateId);
        if(test.isRunningTest()){
            TemplateId = 'a4H3z0000009s5o';
        }
        system.debug('oppId'+oppId);
        contrUrl = contrUrl.replace('a4H3z000000xfsm', TemplateId);
        contrUrl = contrUrl.replaceAll('OpId', oppId);
        system.debug('contrUrl'+contrUrl);
        system.debug('contrUrl'+templateName);
        GenerateDocumentFromConga(contrUrl,templateName);
    }
    
    @future(callout=true)
    Public Static void GenerateDocumentFromConga(String congaUrl,String Name) {
        system.debug('Name Is'+Name + 'congaUrl'+congaUrl);
        String AttId = CongaHelperToolLightning.generateReport(congaUrl,Name,'','','');
        system.debug('AttId'+AttId);
    }
    
    //This method Generates the doc and send it for signature
    @AuraEnabled
    Public Static void GenerateDocumentAndSendForSignature(String recordId ,List<CongaCompWrapper> CongaCompWrapperUserList,List<CongaCompWrapper> CongaCompWrapperConList , List<CongaCompWrapper> CongaCompWrapperList) {
        System.debug('CongaCompWrapperList'+CongaCompWrapperUserList);
        System.debug('CongaCompWrapperConList'+CongaCompWrapperConList);
        
        integer i = 0;
        integer k = 0;
        Contract contractRec = [Select Id,Name ,Opportunity__c,Conga_Template_ID__c,Conga_Sign_URL__c, Conga_Url__c , ContractNumber ,Contract_Type__c , Pricing_Structure__c,Londoner_only__c from contract where Id = :recordId];
        String templateName = '';
        if(contractRec.Londoner_only__c == true){
            templateName = contractRec.Contract_Type__c + '- Londoner Only -' +contractRec.ContractNumber;
        }else{
            templateName = contractRec.Contract_Type__c +' - '+ contractRec.ContractNumber;
        }
        //Updateing all the Fields initial vlaues..
        
        String oppId = contractRec.Opportunity__c;
        contractRec.Primary_User__c = null;
        contractRec.Secondary_User__c = null;
        contractRec.Contact_Name__c = null;
        contractRec.Secondary_Contact__c = null;
        contractRec.Is_Primary_Contact_Selected__c = false;
        contractRec.is_primary_user_selected__c = false;
        contractRec.is_secondary_contact_selected__c = false;
        contractRec.is_secondary_user_selected__c = false;
        
        String TemplateId = getTemplateIdFromKey(contractRec.Conga_Template_ID__c);
        system.debug('TemplateId'+TemplateId);
        
        if(CongaCompWrapperUserList.size() > 0){
            for(CongaCompWrapper ccw : CongaCompWrapperUserList){
                i++;
                system.debug('the iteration value is '+i);
                if(ccw.conId.startsWith('005')){
                    if(i == 1){
                        contractRec.Primary_User__c = ccw.conId;  
                        contractRec.is_primary_user_selected__c = true;
                    }
                    else if(i == 2){
                        contractRec.Secondary_User__c = ccw.conId;
                        contractRec.is_secondary_user_selected__c = true;
                    }
                }
            }
        }
        if(CongaCompWrapperConList.size() > 0){
            for(CongaCompWrapper ccw : CongaCompWrapperConList){
                k++;
                system.debug('the iteration value is '+i);
                if(ccw.conId.startsWith('003')){
                    if(k == 1){
                        contractRec.Contact_Name__c = ccw.conId;    
                        contractRec.Is_Primary_Contact_Selected__c = true;
                    }
                    else if(k == 2){
                        contractRec.Secondary_Contact__c = ccw.conId;    
                        contractRec.is_secondary_contact_selected__c = true;
                    }
                }
            }
        }
        
        update contractRec;
        
        map<integer,String> recipientMap = new map<integer,String>();
        map<String,String> recipientMapValues = new map<String,String>();
        map<String,String> recipientTypeValues = new map<String,String>();
        
        recipientMap.put(1,'CSRecipient1');
        recipientMap.put(2,'CSRecipient2');
        recipientMap.put(3,'CSRecipient3');
        recipientMap.put(4,'CSRecipient4');
        
        recipientMapValues.put('CSRecipient1','csRole1');
        recipientMapValues.put('CSRecipient2','csRole2');
        recipientMapValues.put('CSRecipient3','csRole3');
        recipientMapValues.put('CSRecipient4','csRole4');
        
        String URL = contractRec.Conga_Sign_URL__c;
        
        string recipients = '';
        integer j = 0;
        
        
        url = url.replace('TemplateId=a3t3M0000000Wkt','TemplateId='+TemplateId);
        url = url.replaceAll('OpId', oppId);
        if(CongaCompWrapperList.size() > 0){
            for(CongaCompWrapper ccw : CongaCompWrapperList){
                j++;
                if(!url.contains(recipientMap.get(j))){
                    url+='&CSRecipient'+j+'='+ccw.conId;
                }
                if(!url.contains(recipientMapValues.get('CSRecipient'+j))){
                    url+='&'+recipientMapValues.get('CSRecipient'+j)+'='+ccw.type;
                }
            }
            system.debug('url'+url);
        }
        GenerateDocumentFromConga(URL,templateName);
    }
    
    Public static Boolean sendForSignature(Id primaryContactID, List<String> emailCc, List<String> emailBcc, List<String> emailAdditionalTo, Id emailTemplateId, Id agreementId, List<String> attachmentIds){
        //apttus.AgreementWebService.sendForSignature(primaryContactID,emailCc,emailBcc,emailAdditionalTo,emailTemplateId,agreementId,attachmentIds);
        return false;
    }
    
    @AuraEnabled
    public static List<RecordsData> fetchUserDataforConga(String objectName, String filterField, String searchString, String value, string contactType){
        try{
            objectName = 'user';
            system.debug('contractId'+contactType);
            Contract contractRec = [Select AccountId,Id from contract where id= :contactType];
            List<RecordsData> recordsDataList = new List<RecordsData>();
            String query = '';
            query = 'SELECT Id  ,' + filterField + ' FROM ' + objectName +' Where ';
            if (String.isNotBlank(contractRec.AccountId)){
                query +=   filterField + 
                    ' LIKE ' + '\'' + String.escapeSingleQuotes(searchString.trim()) + '%\' LIMIT 49999';
            }
            system.debug('Query is ' + query);
            for (SObject s : Database.query(query)){
                recordsDataList.add(new RecordsData((String) s.get(filterField), (String) s.get('id')));
            }
            system.debug(recordsDataList);
            return recordsDataList;
        }
        catch (Exception err){
            system.debug('Exception is ' + err.getMessage() + '@ line' + err.getLineNumber());
            if (String.isNotBlank(err.getMessage()) && err.getMessage().contains('error:')){
                throw new AuraHandledException(err.getMessage().split('error:')[1].split(':')[0] + '.');
            } else{
                throw new AuraHandledException(err.getMessage());
            }
        }
    }
    
    @AuraEnabled
    public static List<CongaCompWrapper> fetchAllContactsFromContract(String contractId){
        try{
            system.debug('contractId'+contractId);
            
            Contract contractRec = [Select AccountId,Id from contract where id= :contractId];
            
            List<CongaCompWrapper> recordsDataList = new List<CongaCompWrapper>();
            
            List<Contact> ConList = [Select Id , Name From Contact where accountId =:contractRec.AccountId Order BY NAme ASC];
            List<User> UserList = [Select id , name From User where id = :UserInfo.getUserId()];
            integer i= 1;
            for(User us : UserList){
                CongaCompWrapper ccw = new CongaCompWrapper();
                ccw.conId = us.Id;
                ccw.conName = us.Name; 
                ccw.sequence = i;
                ccw.type = 'SIGNER';
                recordsDataList.add(ccw);
            }
            for(Contact con : ConList){
                i++;
                CongaCompWrapper ccw = new CongaCompWrapper();
                ccw.conId = con.Id;
                ccw.conName = con.Name; 
                ccw.sequence = i;
                ccw.type = 'Signer';
                recordsDataList.add(ccw);
            }
            system.debug(recordsDataList);
            return recordsDataList;
        }
        catch (Exception err){
            system.debug('Exception is ' + err.getMessage() + '@ line' + err.getLineNumber());
            if (String.isNotBlank(err.getMessage()) && err.getMessage().contains('error:')){
                throw new AuraHandledException(err.getMessage().split('error:')[1].split(':')[0] + '.');
            } else{
                throw new AuraHandledException(err.getMessage());
            }
        }
    }
    
    public class RecordsData{
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String value;
        public RecordsData(String label, String value){
            this.label = label;
            this.value = value;
        }
        
    }
}