/**
 * @Name:        BookingGiftAllocationSchedule
 * @Description: Schedule Class used to run the batch class 
 *
 * @author:      Andrei Budescu
 * @version:     1.0
 * Change Log
 *
 * Date         author              Change Description
 * -----------------------------------------------------------------------------------
 * 13/07/2021   Andrei Budescu      Created Class
 */
public without sharing class BookingGiftAllocationSchedule implements Schedulable{

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new BookingGiftAllocationBatch());
    }

}