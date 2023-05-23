@IsTest
public with sharing class CreateBookingSchedTest {

    @IsTest
    public static void sheduledJobsTest() {
        Test.startTest();
        Datetime nextScheduleTime = System.now().addMinutes(1);
        String hour = String.valueOf(nextScheduleTime.hour());
        String minutes = String.valueOf(nextScheduleTime.minute());
        String cronExpression = '0 ' + minutes + ' ' + hour + ' * * ?' ;
        CreateBookingsSched sched = new CreateBookingsSched();
        String jobId = System.schedule('myJobTestJobName', cronExpression, sched);
        Test.stopTest();       
        System.assertEquals(1, [SELECT count() FROM CronTrigger WHERE Id = :jobId]);
    }

}