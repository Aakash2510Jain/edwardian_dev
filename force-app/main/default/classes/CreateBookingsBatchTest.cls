@isTest
public with sharing class CreateBookingsBatchTest {
    @TestSetup
    static void createData() {
        Configuration__c config = new Configuration__c(
            Are_Processes_Off__c  = true
        );
        insert config;
        SObjectRecordTypes recordTypes = new SObjectRecordTypes('Case');
        Account acc = new Account(Name = 'test acc');
        insert acc;
        Case cs = new Case(
                Status = 'New', Agent_Booked_By__c = UserInfo.getUserId(),
                OwnerId = UserInfo.getUserId(), Booking_Confirmation_Number_s__c = '222,333',
                Booking_Confirmation_Flag__c = true
        );
        insert cs;
        Case cs1 = new Case(
                Status = 'New', Agent_Booked_By__c = UserInfo.getUserId(),
                OwnerId = UserInfo.getUserId(), Block_code__c = '555',
                Block_Code_Flag__c = true
        );
        insert cs1;
        Order ord = new Order(AccountId = acc.Id, Status = 'Draft', Confirmation_Number__c = '222', EffectiveDate = Date.today());
        insert ord;
        Order ord1 = new Order(AccountId = acc.Id, Status = 'Draft', Confirmation_Number__c = '333', EffectiveDate = Date.today());
        insert ord1;
        Order ord2 = new Order(AccountId = acc.Id, Status = 'Draft', Block_code__c = '555', EffectiveDate = Date.today());
        insert ord2;
        Spa_Booking__c spa = new Spa_Booking__c(Name = 'test', Confirmation_Number__c = 333);
        insert spa;   
    }


    @isTest
    public static void batchExecutInsertJobsTest() {
        Datetime nextScheduleTime = System.now().addMinutes(1);
        String hour = String.valueOf(nextScheduleTime.hour());
        String minutes = String.valueOf(nextScheduleTime.minute());
        String cronExpression = '0 ' + minutes + ' ' + hour + ' * * ?' ;
        Test.startTest();
        CreateBookingsSched sched = new CreateBookingsSched();
        String jobId = System.schedule('myJobTestJobName', cronExpression, sched);
        CreateBookingsBatch createBookingsBatch = new CreateBookingsBatch(jobId); 
        Database.executeBatch(createBookingsBatch);
        Test.stopTest();
        Case_Reservation__c[] relatedBookings = [
            SELECT Case__c, F_B_Booking__c, Agent_Booked_By__c, RecordType.Name
            FROM Case_Reservation__c
        ];
        System.assertEquals(4, relatedBookings.size());
    }

    @isTest
    public static void batchExecutUpdateJobsTest() {
        Datetime nextScheduleTime = System.now().addMinutes(1);
        String hour = String.valueOf(nextScheduleTime.hour());
        String minutes = String.valueOf(nextScheduleTime.minute());
        String cronExpression = '0 ' + minutes + ' ' + hour + ' * * ?' ;
        List<Case> cs = [
            SELECT Booking_Confirmation_Number_s__c, Booking_Confirmation_Flag__c, Block_Code_Flag__c
            FROM Case
            WHERE Block_code__c != NULL
            LIMIT 1
        ];
        List<Case> cs1 = [
            SELECT Booking_Confirmation_Number_s__c, Booking_Confirmation_Flag__c, Block_Code_Flag__c
            FROM Case
            WHERE Booking_Confirmation_Number_s__c != NULL
            LIMIT 1
        ];
        cs[0].Block_Code__c = '555,123123';
        cs1[0].Booking_Confirmation_Number_s__c = '222,333';
        update cs;
        update cs1;
        Test.startTest();
        CreateBookingsSched sched = new CreateBookingsSched();
        String jobId = System.schedule('myJobTestJobName', cronExpression, sched);
        CreateBookingsBatch createBookingsBatch = new CreateBookingsBatch(jobId); 
        Database.executeBatch(createBookingsBatch);
        Test.stopTest();
        Case_Reservation__c[] relatedBookings = [
            SELECT Case__c, F_B_Booking__c, Agent_Booked_By__c, RecordType.Name
            FROM Case_Reservation__c
        ];
        System.assertEquals(4, relatedBookings.size());
    }

}