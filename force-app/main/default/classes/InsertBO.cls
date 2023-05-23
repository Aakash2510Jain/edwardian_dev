public class InsertBO {
    public static void isertObjects(){
        set<id> conId = new Set<Id>();
        conId.add('0033M0000048srtQAA');
        conId.add('0033M0000048t5zQAA');
        conId.add('0033M000004EvKhQAK');
        conId.add('0033M0000048YazQAE');
        conId.add('0033M000004IG63QAG');
        conId.add('0033M000004IG6lQAG');
        conId.add('0033M000004V3SlQAK');
        conId.add('0033M000004i0EuQAI');
        conId.add('0033M000004jL94QAE');
        conId.add('0033M00000495OUQAY');        
        
        Datetime myDate = Datetime.newInstance(2023, 01, 01, 10, 30, 0);
        integer i = 1;
        List<Archive_Individual_Email_Result__b> bigObjecRecToInsertList = new List<Archive_Individual_Email_Result__b>();

        for(integer j=0;j<500;j++){
            for(id songleId : conId){
                Archive_Individual_Email_Result__b ArIndEmReBig = new Archive_Individual_Email_Result__b();
                ArIndEmReBig.Contact_Id__c = songleId;
                ArIndEmReBig.Created_Date_Time__c = myDate;
                ArIndEmReBig.Name__c = 'Aakash - '+i;
                ArIndEmReBig.Unique_Identifier__c = i;    
                i++;
                bigObjecRecToInsertList.add(ArIndEmReBig);
            }
            
        }
        system.debug('bigObjecRecToInsertList-->'+bigObjecRecToInsertList.size());
        system.debug('bigObjecRecToInsertList--->'+bigObjecRecToInsertList);
    }
}