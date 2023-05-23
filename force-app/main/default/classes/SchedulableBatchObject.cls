/**
 * @author [Dinesh Baddawar]
 * @email dinesh.b@utilitarianLab.com
 * @create date 2023-04-18 18:19:29
 * @modify date 2023-04-18 18:19:29
 * @desc [description]
 */

public with sharing class SchedulableBatchObject implements Schedulable {
    
    public void execute(SchedulableContext bc){
        BatchOnIndividualEmailResult batch = new BatchOnIndividualEmailResult();
        Database.executeBatch(batch);
    }

}