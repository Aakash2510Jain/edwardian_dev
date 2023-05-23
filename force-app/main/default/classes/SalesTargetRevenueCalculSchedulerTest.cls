/**
 * @author Khin Hou (khin.hou@cloudshfitgroup.com)
 * @date 2021-01-26
 * @description Test class for SalesTargetRevenueCalculScheduler
 *
 * Date          author             Change Description
 * -----------------------------------------------------------------------------------
 * 2021-01-26    Khin Hou           Created Class
 */
@IsTest
public with sharing class SalesTargetRevenueCalculSchedulerTest {

    private static final String CRON_EXP = '0 0 2 * * ?';

    @IsTest
    private static void executeTest() {
        Test.startTest();

        String jobId = System.schedule(
            'ScheduleApexClassTest',
            CRON_EXP,
            new SalesTargetRevenueCalculationsScheduler()
        );

        CronTrigger cronTrigger = [
            SELECT
                Id, CronExpression, TimesTriggered, NextFireTime
            FROM CronTrigger
            WHERE Id = :jobId
        ];

        System.assert(
            cronTrigger != null,
            'There should be a scheduled Job'
        );

        System.assertEquals(
            CRON_EXP,
            cronTrigger.CronExpression,
            'The Cron expressions should be the same'
        );

        Test.stopTest();
    }
}