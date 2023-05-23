public class generateDocController {
    @AuraEnabled
    public static List<CongaCompWrapper> fetchAllContactsFromContract(String contractId){
        try{
            
            system.debug('contractId'+contractId);
            
            Contract contractRec = [Select AccountId,Id from contract where id= :contractId];
            
            List<CongaCompWrapper> recordsDataList = new List<CongaCompWrapper>();
            
            List<Contact> ConList = [Select Id , Name From Contact where accountId =:contractRec.AccountId];
            
            for(Contact con : ConList){
                CongaCompWrapper ccw = new CongaCompWrapper();
                ccw.conId = con.Id;
                ccw.conName = con.Name; 
                ccw.sequence = 0;
                ccw.type = '';
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
    
}