@SuppressWarnings('PMD')
public virtual class TriggerHandlerFramework {

    // static map of handlername, times run() was invoked
    private static Map<String, LoopCount> loopCountMap;
    private static Set<String> bypassedHandlers;
    @TestVisible private static Boolean globalBypass;
    @TestVisible private static Boolean showLimits;

    // the current context of the trigger, overridable in tests
    @TestVisible
    private TriggerContext context;

    // the current context of the trigger, overridable in tests
    @TestVisible
    private Boolean isTriggerExecuting;

    // static initialization
    static {
        loopCountMap = new Map<String, LoopCount>();
        bypassedHandlers = new Set<String>();
        globalBypass = false;
        showLimits = false;
    }

    // constructor
    public TriggerHandlerFramework() {
        this.setTriggerContext();
    }

    /***************************************
     * public instance methods
     ***************************************/

    // main method that will be called during execution
    public void run () {

        if (!validateRun()) {
            return;
        }
        addToLoopCount();

        // dispatch to the correct handler method
        if (this.context == TriggerContext.BEFORE_INSERT) {
            this.beforeInsert();
        } else if (this.context == TriggerContext.BEFORE_UPDATE) {
            this.beforeUpdate();
        } else if (this.context == TriggerContext.BEFORE_DELETE) {
            this.beforeDelete();
        } else if (this.context == TriggerContext.AFTER_INSERT) {
            this.afterInsert();
        } else if (this.context == TriggerContext.AFTER_UPDATE) {
            this.afterUpdate();
        } else if (this.context == TriggerContext.AFTER_DELETE) {
            this.afterDelete();
        } else if (this.context == TriggerContext.AFTER_UNDELETE) {
            this.afterUndelete();
        }

        if (showLimits) {
            System.debug(LoggingLevel.DEBUG, String.format('{0} on {1} ({2}/{3})', new List<String>{
                this.context+'',
                getHandlerName(),
                Limits.getQueries()+'',
                Limits.getLimitQueries()+''
            }));
        }
    }

    public void setMaxLoopCount (Integer max) {
        String handlerName = getHandlerName();
        if (!TriggerHandlerFramework.loopCountMap.containsKey(handlerName)) {
            TriggerHandlerFramework.loopCountMap.put(handlerName, new LoopCount(max));
        } else {
            TriggerHandlerFramework.loopCountMap.get(handlerName).setMax(max);
        }
    }

    public void clearMaxLoopCount () {
        this.setMaxLoopCount(-1);
    }

    /***************************************
     * public static methods
     ***************************************/

    public static void bypass (String handlerName) {
        bypassedHandlers.add(handlerName);
    }

    public static void bypass (List<String> handlersNames) {
        bypassedHandlers.addAll(handlersNames);
    }

    public static void bypass (Type handlerType) {
        bypass(handlerType.getName());
    }

    public static void bypassAll () {
        globalBypass = true;
    }

    public static void clearBypass (String handlerName) {
        bypassedHandlers.remove(handlerName);
    }

    public static void clearBypass (Type handlerType) {
        clearBypass(handlerType.getName());
    }

    public static void clearBypass (List<String> handlersNames) {
        bypassedHandlers.removeAll(handlersNames);
    }

    public static void clearGlobalBypass () {
        globalBypass = false;
    }

    public static Boolean isBypassed (String handlerName) {
        return bypassedHandlers.contains(handlerName);
    }

    public static Boolean isBypassed (Type handlerType) {
        return bypassedHandlers.contains(handlerType.getName());
    }

    public static void showLimits () {
        showLimits = true;
    }

    public static Integer getLoopCount (String handlerName) {
        if (TriggerHandlerFramework.loopCountMap.containsKey(handlerName)) {
            return TriggerHandlerFramework.loopCountMap.get(handlerName).getCount();
        }
        return 0;
    }

    /***************************************
     * private instancemethods
     ***************************************/

    @TestVisible
    private void setTriggerContext () {
        this.setTriggerContext(null, false);
    }

    @TestVisible
    private void setTriggerContext (String ctx, Boolean testMode) {
        if (!Trigger.isExecuting && !testMode) {
            this.isTriggerExecuting = false;
            return;
        } else {
            this.isTriggerExecuting = true;
        }

        if ((Trigger.isExecuting && Trigger.isBefore && Trigger.isInsert) ||
            (ctx != null && ctx == 'before insert')) {
            this.context = TriggerContext.BEFORE_INSERT;
        } else if ((Trigger.isExecuting && Trigger.isBefore && Trigger.isUpdate) ||
            (ctx != null && ctx == 'before update')){
            this.context = TriggerContext.BEFORE_UPDATE;
        } else if ((Trigger.isExecuting && Trigger.isBefore && Trigger.isDelete) ||
            (ctx != null && ctx == 'before delete')) {
            this.context = TriggerContext.BEFORE_DELETE;
        } else if ((Trigger.isExecuting && Trigger.isAfter && Trigger.isInsert) ||
            (ctx != null && ctx == 'after insert')) {
            this.context = TriggerContext.AFTER_INSERT;
        } else if ((Trigger.isExecuting && Trigger.isAfter && Trigger.isUpdate) ||
            (ctx != null && ctx == 'after update')) {
            this.context = TriggerContext.AFTER_UPDATE;
        } else if ((Trigger.isExecuting && Trigger.isAfter && Trigger.isDelete) ||
            (ctx != null && ctx == 'after delete')) {
            this.context = TriggerContext.AFTER_DELETE;
        } else if ((Trigger.isExecuting && Trigger.isAfter && Trigger.isUndelete) ||
            (ctx != null && ctx == 'after undelete')) {
            this.context = TriggerContext.AFTER_UNDELETE;
        }
    }

    // increment the loop count
    @TestVisible
    private void addToLoopCount () {
        String handlerName = getHandlerName();
        if (TriggerHandlerFramework.loopCountMap.containsKey(handlerName)) {
            Boolean exceeded = TriggerHandlerFramework.loopCountMap.get(handlerName).increment();
            if (exceeded) {
                Integer max = TriggerHandlerFramework.loopCountMap.get(handlerName).max;
                throw new TriggerHandlerException('Maximum loop count of ' + String.valueOf(max) + ' reached in ' + handlerName);
            }
        }
    }

    // make sure this trigger should continue to run
    @TestVisible
    private Boolean validateRun () {
        if (!this.isTriggerExecuting || this.context == null) {
            throw new TriggerHandlerException('Trigger handler called outside of Trigger execution');
        }
        if (globalBypass) {
            return false;
        }
        if (TriggerHandlerFramework.bypassedHandlers.contains(getHandlerName())) {
            return false;
        }
        return true;
    }

    @TestVisible
    private String getHandlerName () {
        return String.valueOf(this).substring(0, String.valueOf(this).indexOf(':'));
    }

    /***************************************
     * context methods
     ***************************************/

    // context-specific methods for override
    @TestVisible
    protected virtual void beforeInsert () {}
    @TestVisible
    protected virtual void beforeUpdate () {}
    @TestVisible
    protected virtual void beforeDelete () {}
    @TestVisible
    protected virtual void afterInsert () {}
    @TestVisible
    protected virtual void afterUpdate () {}
    @TestVisible
    protected virtual void afterDelete () {}
    @TestVisible
    protected virtual void afterUndelete () {}

    /***************************************
     * inner classes
     ***************************************/

    // inner class for managing the loop count per handler
    @TestVisible
    private class LoopCount {
        private Integer max;
        private Integer count;

        public LoopCount() {
            this.max = 5;
            this.count = 0;
        }

        public LoopCount(Integer max) {
            this.max = max;
            this.count = 0;
        }

        public Boolean increment() {
            this.count++;
            return this.exceeded();
        }

        public Boolean exceeded() {
            if (this.max < 0) {
                return false;
            }
            if (this.count > this.max) {
                return true;
            }
            return false;
        }

        public Integer getMax() {
            return this.max;
        }

        public Integer getCount() {
            return this.count;
        }

        public void setMax(Integer max) {
            this.max = max;
        }
    }

    // possible trigger contexts
    @TestVisible
    private enum TriggerContext {
        BEFORE_INSERT, BEFORE_UPDATE, BEFORE_DELETE,
        AFTER_INSERT, AFTER_UPDATE, AFTER_DELETE,
        AFTER_UNDELETE
    }

    // exception class
    public class TriggerHandlerException extends Exception {}
}