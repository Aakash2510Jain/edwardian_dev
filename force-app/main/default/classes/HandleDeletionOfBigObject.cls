public class HandleDeletionOfBigObject {
   /* Public static Integer count = 0;
    public static integer totalContactCount = [select count() from contact];

    public static void getContacts(){
        Map<Id, Contact> contactIdByContactRec = new Map<Id, Contact>([Select Id,Is_Related_Big_Object_Deleted__c From Contact where Is_Related_Big_Object_Deleted__c = false limit 10000]);
        system.debug('contactIdByContactRec--->'+contactIdByContactRec.size());
        getBigObjectRecords(contactIdByContactRec.keySet());
    }
    public static void getBigObjectRecords(set<id> contactIdsSet){
        system.debug('contactIdByContactRec--->'+contactIdsSet.size());
        List<Test_V3__b> bigObjectRecordList = new List<Test_V3__b>();
        bigObjectRecordList = [SELECT Name__c FROM Test_V3__b where  Contact_Id__c	in: contactIdsSet and Created_Date_Time__c < TODAY LIMIT 50000];
        List<Contact> contactListToUpdate = new List<Contact>();
        
        for(Test_V3__b bigObjectRec : bigObjectRecordList){
            // contactIds.add(bigObjectRec.Name__c);             
        }
        if(!contactIdsSet.isEmpty()){
            for(Id conId :  contactIdsSet){
                Contact contactRecToUpdate = new Contact();
                contactRecToUpdate.Id = conId;
                contactRecToUpdate.Is_Related_Big_Object_Deleted__c = true;
                contactListToUpdate.add(contactRecToUpdate);
            }
            update contactListToUpdate;
        }
        count = count + 10000;
        system.debug('count--->'+count);
        system.debug('totalContactCount--->'+totalContactCount);
        if(count <totalContactCount ){
            system.debug('Again CAlling method');
            getContacts();
        }
    }
    */
}