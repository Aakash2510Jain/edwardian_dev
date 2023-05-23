@SuppressWarnings('PMD.CyclomaticComplexity')
public with sharing class CreateBookingsBatch implements Database.Batchable<sObject>, Database.Stateful{

    private static final String CREATE_BOOKING_JOB_NAME = 'Create Booking For Case Scheduled Job';
    private Id contextId;
    final static string ROOM_BOOKING_RT = 'Room_Bookings';
    final static string SPA_BOOKING_RT = 'Spa_Bookings';
    List<Case> bookingCases;
    List<Case> blockCodeCases;
    Set<String> existingRelatedRecords;
    transient Map<String, Schema.RecordTypeInfo> recordTypes;
    Map<String, Case> idToCase;
    List<Case_Reservation__c> newReservations;
    List<Case_Reservation__c> reservationsToDelete;

    /**
    *
    * Custom constructor
    * @param  contextId - existing scheduled job id for abort current job and create new one
    */
    public CreateBookingsBatch(Id contextId) {
        this.contextId = contextId;
    }

    /**
    *
    * Method for retrieve all existing Case records with related Case Reservation records where Booking Confirmations or Block Codes was changed or filled
    * @param  bc - Batchable Context
    * @return Database.QueryLocator
    */
    public Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'SELECT Booking_Confirmation_Number_s__c, Agent_Booked_By__c, Booking_Confirmation_Flag__c, '   +
            + ' ( SELECT Reservation__r.Confirmation_Number__c, ' +
            +  ' Spa_Booking__c, Reservation__c, Spa_Booking__r.Confirmation_Number__c, Case__c' +  
            + ' FROM Case_Reservations__r' +
            + ' WHERE Spa_Booking__r.Confirmation_Number__c != NULL OR Reservation__r.Confirmation_Number__c != NULL )'  + 
            + ' FROM Case  ' + 
            + ' WHERE Booking_Confirmation_Flag__c = TRUE OR Block_Code_Flag__c = TRUE';
        return Database.getQueryLocator(query);
     }
   
    /**
    *
    * Method that calls for processing all records from "start" method
    * @param  bc - Batchable Context
    * @param  cases - list of case record for processing
    */
     public void execute(Database.BatchableContext bc, List<Case> cases){

        recordTypes = Schema.SObjectType.Case_Reservation__c.getRecordTypeInfosByDeveloperName();
        bookingCases = cases;
        blockCodeCases = new List<Case>();
        existingRelatedRecords = new Set<String>();
        idToCase = new Map<String, Case>();
        newReservations = new List<Case_Reservation__c>();
        reservationsToDelete = new List<Case_Reservation__c>();

        if (!bookingCases.isEmpty()) {
            deleteNotRelevantRelatedBookings();
            parseCases();
            if (!idToCase.isEmpty()) {
                createRoomBookings();
                createSpaBookings();
            }
        }

        createBlockCodesReservations();

        if (!newReservations.isEmpty()) {
            insert newReservations;
        }

        List<Id> caseIds = new List<Id>();
        for (Case item : bookingCases) {
            caseIds.add(item.Id);
        }

        updateFlagsForRelatedCases(caseIds);
    }

    /**
    *
    * Method that calls for update Case records where count of block codes or booking confirmation numbers equals count of exesting Case Reservtion records
    * @param  caseIds - list of case Ids that was processed 
    */
    private static void updateFlagsForRelatedCases(List<Id> caseIds) {
        List<Case> cases = [
            SELECT Id, Booking_Confirmation_Number_s__c, Block_Code__c, Booking_Confirmation_Flag__c, Block_Code_Flag__c,
                (SELECT Id FROM Case_Reservations__r) 
            FROM Case 
            WHERE Id 
            IN :caseIds
        ];

        Set<Case> caseToUpdate = new Set<Case>();
        for (Case item : cases) {

            Boolean valueChanged = false;

            // fix - add in a check to ensure the flag is actually true or ignore it
            if (item.Booking_Confirmation_Flag__c
                    && (item.Booking_Confirmation_Number_s__c != null && item.Booking_Confirmation_Number_s__c.remove(' ').split(',').size() == item.Case_Reservations__r.size())) {

                item.Booking_Confirmation_Flag__c = false;
                valueChanged = true;
            }

            // fix - add in a check to ensure the flag is actually true or ignore it
            if (item.Block_Code_Flag__c
                    && (item.Block_Code__c != null && item.Block_Code__c.remove(' ').split(',').size() == item.Case_Reservations__r.size())) {

                item.Block_Code_Flag__c = false;
                valueChanged = true;
            }

            // fix - only add the case to be updated if we actually changed something
            if (valueChanged) {
            
                caseToUpdate.add(item);
            }
        }

        update new List<Case>(caseToUpdate);
    }

    /**
    *
    * Method that calls for create Case Reservation records between Case and Order existing records
    */
    private void createRoomBookings() {
        Order[] orders = [
            SELECT Confirmation_Number__c
            FROM Order
            WHERE Confirmation_Number__c IN :idToCase.keySet()
            AND Id NOT IN :existingRelatedRecords
        ];

        if (!orders.isEmpty()) {
            for (Order ordr : orders) {
                Case c = idToCase.get(ordr.Confirmation_Number__c);
                newReservations.add(new Case_Reservation__c(
                    RecordTypeId = recordTypes.get(ROOM_BOOKING_RT).getRecordTypeId(),
                    Agent_Booked_By__c = c.Agent_Booked_By__c,
                    Case__c = c.Id, Reservation__c = ordr.Id
                ));
            }
        }
    }

    /**
    *
    * Method that calls for create Case Reservation records between Case and Spa Booking existing records
    */
    private void createSpaBookings() {
        Map<Decimal, Case> confirmNums = new Map<Decimal, Case>();
        for (String id : idToCase.keySet()) {
            confirmNums.put(Decimal.valueOf(id), idToCase.get(id));
        }

        Spa_Booking__c[] spaBookings = [
            SELECT Confirmation_Number__c
            FROM Spa_Booking__c
            WHERE Confirmation_Number__c IN :confirmNums.keySet()
            AND Id NOT IN :existingRelatedRecords
        ];

        if (!spaBookings.isEmpty()) {
            for (Spa_Booking__c spaBooking : spaBookings) {
                Case c = confirmNums.get(spaBooking.Confirmation_Number__c);
                newReservations.add(new Case_Reservation__c(
                    RecordTypeId = recordTypes.get(SPA_BOOKING_RT).getRecordTypeId(),
                    Agent_Booked_By__c = c.Agent_Booked_By__c,
                    Case__c = c.Id, Spa_Booking__c = spaBooking.Id
                ));
            }
        }
    }

    /**
    *
    * Method that calls for parse existing Case Reservation for Case records for store existing Spa Booking or Order(parents) records
    */
    private void parseCases() {
        for (Case flaggedCase : bookingCases) {
            if (!flaggedCase.Case_Reservations__r.isEmpty()) {
                for (Case_Reservation__c exCaseRes : flaggedCase.Case_Reservations__r) {
                    existingRelatedRecords.add(exCaseRes.Spa_Booking__c);
                    existingRelatedRecords.add(exCaseRes.Reservation__c);
                }
            }

            if (flaggedCase.Booking_Confirmation_Number_s__c != null) {
                String[] splittedIds = flaggedCase.Booking_Confirmation_Number_s__c.remove(' ').split(',');
                for (String splitId : splittedIds) {
                    idToCase.put(splitId, flaggedCase);
                }
            }
        }
    }

    /**
    *
    * Method that calls for sort existing records, and found records that needed to be deleted and store only codes that needed to be processed
    * @param  thisCase - current case for get Case Reservation records 
    * @param  newBlockCodes - set of codes for processing 
    * @param  casesToAddNewReservation - list of existing cases for processing
    */
    private void handleExistingReservations(Case thisCase, Set<String> newBlockCodes, List<Case> casesToAddNewReservation) {
        Set<String> blockCodes = new Set<String>(thisCase.Block_Code__c.remove(' ').split(','));
        List<String> existBlockCodes = new List<String>();
        
        for (Case_Reservation__c caseRes : thisCase.Case_Reservations__r) {
            if (!blockCodes.contains(caseRes.Reservation__r.Block_Code__c)) {
                Integer indexOf = thisCase.Case_Reservations__r.indexOf(caseRes);
                reservationsToDelete.add(caseRes);
                thisCase.Case_Reservations__r.remove(indexOf);
            } else {
                existBlockCodes.add(caseRes.Reservation__r.Block_Code__c);
            }
        }

        if (thisCase.Case_Reservations__r.size() != 0) {
            casesToAddNewReservation.add(thisCase);
        }

        if (!existBlockCodes.isEmpty()) {
            blockCodes.removeAll(existBlockCodes);
            newBlockCodes.addAll(blockCodes);
        }
    }

    /**
    *
    * Method that calls for send Case record for handing existing case reservation records or for add all codes to processing
    * @param  thisCase - current case for get Case Reservation records 
    * @param  newBlockCodes - set of codes for processing 
    * @param  casesToAddNewReservation - list of existing cases for processing
    */
    private void checkExistingReservations(Case thisCase, Set<String> newBlockCodes, List<Case> casesToAddNewReservation) {
        if (!thisCase.Case_Reservations__r.isEmpty()) {
            handleExistingReservations(thisCase, newBlockCodes, casesToAddNewReservation);
        } else {
            newBlockCodes.addAll(thisCase.Block_Code__c.remove(' ').split(','));
            casesToAddNewReservation.add(thisCase);
        }
    }

    /**
    *
    * Method that calls for sort Case reservation to create new records and delete not relevant Case reservation records by Block Code values
    */
    private void createBlockCodesReservations() {
        Set<String> newBlockCodes = new Set<String>();
        List<Case> casesToAddNewReservation = new List<Case>();
        reservationsToDelete = new List<Case_Reservation__c>();
        blockCodeCases = [
                SELECT Agent_Booked_By__c, Block_Code__c,
                    (SELECT Reservation__c, Reservation__r.Block_Code__c, Case__c
                    FROM Case_Reservations__r 
                    WHERE Reservation__r.Block_Code__c != NULL)
                FROM Case
                WHERE Block_Code_Flag__c = TRUE
        ];

        for (Case thisCase : blockCodeCases) {
            String blockCode = thisCase.Block_Code__c;
            addAllIfNull(blockCode, thisCase.Case_Reservations__r);
            if (blockCode != null) {
                checkExistingReservations(thisCase, newBlockCodes, casesToAddNewReservation);
            }
        }

        if (!casesToAddNewReservation.isEmpty()) {
            Map<String, List<Order>> blockCodeToOrder = new Map<String, List<Order>>();
            fillBlockCodeMap(newBlockCodes, blockCodeToOrder);
            if (!blockCodeToOrder.isEmpty()) {
                for (Case thisCase : casesToAddNewReservation) {
                    createNewReservation(blockCodeToOrder, thisCase);
                }
            }
        }

        deleteReservations();
    }

    /**
    *
    * Method that calls for create Case reservation from Block Code values
    * @param blockCodeToOrder map for store block code as key and list of orders as values for creation 
    * @param thisCase current case for processing 
    */
    private void createNewReservation(Map<String, List<Order>> blockCodeToOrder, Case thisCase) {
        for (String item : thisCase.Block_Code__c.remove(' ').split(',')) {
            if (blockCodeToOrder.containsKey(item)) {
                for (Order thisOrder : blockCodeToOrder.get(item)) {
                    newReservations.add(new Case_Reservation__c(
                        RecordTypeId = recordTypes.get(ROOM_BOOKING_RT).getRecordTypeId(),
                        Agent_Booked_By__c = thisCase.Agent_Booked_By__c,
                        Case__c = thisCase.Id, Reservation__c = thisOrder.Id
                    ));
                }
            }
        }
    }

    /**
    *
    * Method that calls for fill block code to order list map
    * @param newBlockCodes set of block codes for map creation 
    * @param blockCodeToOrder map as a result of fill 
    */
    private void fillBlockCodeMap(Set<String> newBlockCodes, Map<String, List<Order>> blockCodeToOrder) {
        Order[] orders = [
            SELECT Block_Code__c
            FROM Order
            WHERE Block_Code__c IN :newBlockCodes
        ];

        for (Order anOrder : orders) {
            if (blockCodeToOrder.containsKey(anOrder.Block_Code__c)) {
                blockCodeToOrder.get(anOrder.Block_Code__c).add(anOrder);
            } else {
                blockCodeToOrder.put(anOrder.Block_Code__c, new List<Order>{anOrder});
            }
        }
    }

    /**
    *
    * Method that calls for add all Case reservation records to delete
    * @param num Block Codes or Booking Confirmation values
    * @param reservations records to delete 
    */
    private void addAllIfNull(String num, List<Case_Reservation__c> reservations) {
        if (num == null && !reservations.isEmpty()) {
            reservationsToDelete.addAll(reservations);
        }
    }

    /**
    *
    * Method that calls for delete not relevant Case reservation records
    */
    private void deleteReservations() {
        if (!reservationsToDelete.isEmpty()) {
            delete reservationsToDelete;
        }
    }

    /**
    *
    * Method that calls for sort Case reservation records for delete
    */
    private void deleteNotRelevantRelatedBookings() {
        for (Case thisCase : bookingCases) {
            if (thisCase.Booking_Confirmation_Flag__c) {
                String bookingNum = thisCase.Booking_Confirmation_Number_s__c;
                addAllIfNull(bookingNum, thisCase.Case_Reservations__r);
                if (bookingNum != null && !thisCase.Case_Reservations__r.isEmpty()) {
                    checkExpiredReservations(thisCase, bookingNum);
                }
            }
        }
        deleteReservations();
    }

    /**
    *
    * Method that calls for sort Case reservation to create new records and delete not relevant Case reservation records by Booking Confirmation values
    * @param thisCase current case for processing 
    * @param bookingNum current Booking Confirmation values
    */
    private void checkExpiredReservations(Case thisCase, String bookingNum) {
        List<String> bookingNums = bookingNum.remove(' ').split(',');
        for (Case_Reservation__c caseRes : thisCase.Case_Reservations__r) {
            Integer indexOf = thisCase.Case_Reservations__r.indexOf(caseRes);
            if (caseRes.Reservation__r.Confirmation_Number__c != null) {
                if (!bookingNums.contains(caseRes.Reservation__r.Confirmation_Number__c)) {
                    reservationsToDelete.add(caseRes);
                    thisCase.Case_Reservations__r.remove(indexOf);
                    continue;
                }
            }

            if (caseRes.Spa_Booking__r.Confirmation_Number__c != null) {
                if (!bookingNums.contains(String.valueOf(caseRes.Spa_Booking__r.Confirmation_Number__c))) {
                    reservationsToDelete.add(caseRes);
                    thisCase.Case_Reservations__r.remove(indexOf);
                }
            }
        }
    }
   
    /**
    *
    * Method that calls in the end of batch and aborting current scheduled job and create new one
    * @param bc Batchable Context 
    */
    public void finish(Database.BatchableContext bc){
        Datetime nextScheduleTime = System.now().addMinutes(1);
        String hour = String.valueOf(nextScheduleTime.hour());
        String minutes = String.valueOf(nextScheduleTime.minute());
        String cronExpression = '0 ' + minutes + ' ' + hour + ' * * ?' ;
        CreateBookingsSched container = new CreateBookingsSched();
        System.abortJob(contextId);
        CreateBookingsSched sched = new CreateBookingsSched();
        Id jobId = System.schedule(CREATE_BOOKING_JOB_NAME + DateTime.now().getTime(), cronExpression, sched);  
     }
}