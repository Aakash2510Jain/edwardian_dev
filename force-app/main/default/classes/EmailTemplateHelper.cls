public class EmailTemplateHelper {
    
    public static void SendEmailTemplateWithTemplate() {
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        EmailTemplate emailTemp = [Select id,HtmlValue,Subject, Body From EmailTemplate Where DeveloperName = 'TEM_Chase_Payment_1'];
        nihrm__Booking__c con = [Select Id, nihrm__BookingContact__c,nihrm__BookingContact__r.Name,nihrm__ArrivalDate__c,nisc_Booking_Reference__c from nihrm__Booking__c where id = 'a0G3z00001BjyslEAB'][0];
        
        
        List<nihrm__Transaction__c> transactionList = [Select id , nihrm__TransactionDate__c ,nihrm__Amount__c, nihrm__ChargeTypeName__c ,nihrm__TransactionType__c	, name from nihrm__Transaction__c where nihrm__Booking__c = 'a0G3z00001BjyslEAB'];
        
        String EmailBody = emailTemp.HtmlValue;
        EmailBody = EmailBody.replace('{!nihrm__Booking__c.nihrm__BookingContact__c}', con.nihrm__BookingContact__r.Name);
        EmailBody = EmailBody.replace('{!nihrm__Booking__c.nihrm__ArrivalDate__c}', String.valueOf(con.nihrm__ArrivalDate__c));
        String htmlBody = '<table border="3" cellpadding="1" cellspacing="1" class="pd-table" style="height:10px;width:100%;"><caption></caption><tr><th>Transaction Type</th><th>Charge Type	</th><th>Date</th><th>Amount</th></tr>';
        
        for(nihrm__Transaction__c trans : transactionList){
            String tType = String.valueOf(trans.nihrm__TransactionType__c); 
            String cType = String.valueOf(trans.nihrm__ChargeTypeName__c);
            String tDate = String.valueOf(trans.nihrm__TransactionDate__c);
            String tAmount = String.valueOf(trans.nihrm__Amount__c);
            htmlBody += '<tr><td style="width: 186px; text-align: justify;">' + tType + '</td><td style="width: 186px; text-align: justify;">' + cType + '</td><td style="width: 186px; text-align: justify;">' + tDate + '</td><td style="width: 186px; text-align: justify;">' + tAmount + '</td></tr>';
        }
        htmlBody = htmlBody + '</table>';
        //mlBody = htmlBody + '';
        system.debug('htmlBody'+htmlBody);
        EmailBody = EmailBody.replace('TransactionTable', htmlBody);
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTemplateId(emailTemp.Id);
        mail.setSubject('Booking reference number '+con.nisc_Booking_Reference__c+' : Initial deposit due');
        mail.setHtmlBody(EmailBody);
        mail.setTargetObjectId(con.nihrm__BookingContact__c);
        mail.setWhatId(con.Id);
        emailList.add(mail);
        
        if(!emailList.isEmpty()){
            Messaging.sendEmail(emailList);
        }    
    }
    
}