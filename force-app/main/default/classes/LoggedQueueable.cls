/**
* @author Gavin Palmer (gavinhughpalmer@gmail.com)
* @version 1.0
* @description This class wraps the queueable interface with the logging framework so that developers do not 
* have to worry about writing the logs after the Logger methods are called. 
*
* 2019-02-06 : Gavin Palmer - Original
**/
public abstract inherited sharing class LoggedQueueable implements Queueable {

    protected QueueableContext context;
    // the logger adapter is called as an instance method as the static singleton variable isnt maintained in the Queueable transaction
    private final BulkLogObjectAdapter loggerAdapter = BulkLogObjectAdapter.getInstance('Logged Queueable');
    protected final Logger log = new Logger(loggerAdapter);

    public void execute(QueueableContext context) {
        BulkLogObjectAdapter.setInstance(loggerAdapter);
        this.context = context;
        try {
            execute();
        } catch (Exception exceptionToHandle) {
            log.error(exceptionToHandle);
        }
        BulkLogObjectAdapter.writeLogs();
    }

    protected abstract void execute();

    public Id enqueue() {
        return System.enqueueJob(this);
    }
}