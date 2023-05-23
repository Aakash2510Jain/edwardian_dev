public class DeleteBigObjectRecordsAsync implements Queueable{
    List<contact> contactList = New List<contact>();
    List<contact> contactListTobeUpdate = new List<contact>();
    integer thisTransactionContactCount;
    integer totalContactCount;
    public DeleteBigObjectRecordsAsync(List<Contact> contactList,integer thisTransactionContactCount,integer totalContactCount){
        this.contactList = contactList;
        this.thisTransactionContactCount = thisTransactionContactCount;
        this.totalContactCount = totalContactCount;
    }
    public void execute(QueueableContext context){
        system.debug('contactList-->'+contactList);
        system.debug('LeadList-->'+contactList.size());
        system.debug('thisTransactionContactCount-->'+thisTransactionContactCount);
        system.debug('totalContactCount-->'+totalContactCount);
        //Lead leadRec = [Select Id,Phone From Lead where id =: leadId];
        for(integer i = thisTransactionContactCount;i< totalContactCount;i++){
            
        }
        thisTransactionContactCount = thisTransactionContactCount + 10000;
        system.debug('contactListTobeUpdate-->'+contactListTobeUpdate);
        
        if(thisTransactionContactCount < totalContactCount){
            system.debug('Enqueue Job');
            System.enqueueJob(new DeleteBigObjectRecordsAsync(contactList,thisTransactionContactCount,totalContactCount));
        }
    } 
}