/**
 * @author Vasile Fana <vasile.fana@cloudshiftgroup.com>
 * @date 2020-12-01
 * @group CloudShiftGroup
 * @description  This is a trigger to capture the events on the order (Booking) object.
 *
 * Date          author             Change Description
 * -----------------------------------------------------------------------------------
 * 2020-12-01    Vasile Fana       Created Class
 */
trigger OrderTrigger on Order (before insert, after insert, before update, after update) {

    new OrderTriggerHandler().run();
}