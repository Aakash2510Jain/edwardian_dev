@SuppressWarnings('PMD.CyclomaticComplexity')
public with sharing class CreateBookingsSched implements Schedulable{

    // final static string ROOM_BOOKING_RT = 'Room_Bookings';
    // final static string SPA_BOOKING_RT = 'Spa_Bookings';
    // List<Case> bookingCases = new List<Case>();
    // List<Case> blockCodeCases = new List<Case>();
    // Set<String> existingRelatedRecords = new Set<String>();
    // Map<String, Schema.RecordTypeInfo> recordTypes;
    // Map<String, Case> idToCase = new Map<String, Case>();
    // List<Case_Reservation__c> newReservations = new List<Case_Reservation__c>();
    // List<Case_Reservation__c> reservationsToDelete = new List<Case_Reservation__c>();

    // public CreateBookingsSched() {
    //     recordTypes = Schema.SObjectType.Case_Reservation__c.getRecordTypeInfosByDeveloperName();
    // }

    public void execute(SchedulableContext sc) {
        CreateBookingsBatch createBookingsBatch = new CreateBookingsBatch(sc.getTriggerId()); 
        Database.executeBatch(createBookingsBatch);
        // getCases();
        // if (!bookingCases.isEmpty()) {
        //     deleteNotRelevantRelatedBookings();
        //     parseCases();
        //     if (!idToCase.isEmpty()) {
        //         createRoomBookings();
        //         createSpaBookings();
        //     }
        // }
        // createBlockCodesReservations();
        // if (!newReservations.isEmpty()) {
        //     insert newReservations;
        // }
    }

    // private void createRoomBookings() {
    //     Order[] orders = [
    //         SELECT Confirmation_Number__c
    //         FROM Order
    //         WHERE Confirmation_Number__c IN :idToCase.keySet()
    //         AND Id NOT IN :existingRelatedRecords
    //     ];
    //     if (!orders.isEmpty()) {
    //         for (Order ordr : orders) {
    //             Case c = idToCase.get(ordr.Confirmation_Number__c);
    //             newReservations.add(new Case_Reservation__c(
    //                 RecordTypeId = recordTypes.get(ROOM_BOOKING_RT).getRecordTypeId(),
    //                 Agent_Booked_By__c = c.Agent_Booked_By__c,
    //                 Case__c = c.Id, Reservation__c = ordr.Id
    //             ));
    //         }
    //     }
    // }

    // private void createSpaBookings() {
    //     Map<Decimal, Case> confirmNums = new Map<Decimal, Case>();
    //     for (String id : idToCase.keySet()) {
    //         confirmNums.put(Decimal.valueOf(id), idToCase.get(id));
    //     }
    //     Spa_Booking__c[] spaBookings = [
    //         SELECT Confirmation_Number__c
    //         FROM Spa_Booking__c
    //         WHERE Confirmation_Number__c IN :confirmNums.keySet()
    //         AND Id NOT IN :existingRelatedRecords
    //     ];
    //     if (!spaBookings.isEmpty()) {
    //         for (Spa_Booking__c spaBooking : spaBookings) {
    //             Case c = confirmNums.get(spaBooking.Confirmation_Number__c);
    //             newReservations.add(new Case_Reservation__c(
    //                 RecordTypeId = recordTypes.get(SPA_BOOKING_RT).getRecordTypeId(),
    //                 Agent_Booked_By__c = c.Agent_Booked_By__c,
    //                 Case__c = c.Id, Spa_Booking__c = spaBooking.Id
    //             ));
    //         }
    //     }
    // }

    // private void getCases() {
    //     bookingCases = [
    //         SELECT Booking_Confirmation_Number_s__c, Agent_Booked_By__c,
    //             (SELECT Reservation__r.Confirmation_Number__c,
    //                     Spa_Booking__c, Reservation__c,
    //                     Spa_Booking__r.Confirmation_Number__c, Case__c
    //              FROM Case_Reservations__r
    //              WHERE Spa_Booking__r.Confirmation_Number__c != NULL
    //              OR Reservation__r.Confirmation_Number__c != NULL
    //              )
    //         FROM Case
    //         WHERE Booking_Confirmation_Flag__c != NULL
    //     ];
    // }

    // private void parseCases() {
    //     for (Case flaggedCase : bookingCases) {
    //         if (!flaggedCase.Case_Reservations__r.isEmpty()){
    //             for (Case_Reservation__c exCaseRes : flaggedCase.Case_Reservations__r) {
    //                 existingRelatedRecords.add(exCaseRes.Spa_Booking__c);
    //                 existingRelatedRecords.add(exCaseRes.Reservation__c);
    //             }
    //         }
    //         if (flaggedCase.Booking_Confirmation_Number_s__c != null) {
    //             String[] splittedIds = flaggedCase.Booking_Confirmation_Number_s__c.remove(' ').split(',');
    //             for (String splitId : splittedIds) {
    //                 idToCase.put(splitId, flaggedCase);
    //             }
    //         }
    //     }
    // }

    // private void handleExistingReservations(Case thisCase, Set<String> newBlockCodes, List<Case> casesToAddNewReservation) {
    //     String blockCode = thisCase.Block_Code__c;
    //     for (Case_Reservation__c caseRes : thisCase.Case_Reservations__r) {
    //         if (caseRes.Reservation__r.Block_Code__c != blockCode) {
    //             newBlockCodes.add(blockCode);
    //             reservationsToDelete.addAll(thisCase.Case_Reservations__r);
    //             casesToAddNewReservation.add(thisCase);
    //             break;
    //         } 
    //     }
    // }

    // private void checkExistingReservations(Case thisCase, Set<String> newBlockCodes, List<Case> casesToAddNewReservation) {
    //     if (!thisCase.Case_Reservations__r.isEmpty()) {
    //         handleExistingReservations(thisCase, newBlockCodes, casesToAddNewReservation);
    //     } else {
    //         newBlockCodes.add(thisCase.Block_Code__c);
    //         casesToAddNewReservation.add(thisCase);
    //     }
    // }

    // private void createBlockCodesReservations() {
    //     Set<String> newBlockCodes = new Set<String>();
    //     List<Case> casesToAddNewReservation = new List<Case>();
    //     blockCodeCases = [
    //             SELECT Agent_Booked_By__c, Block_Code__c,
    //                 (SELECT Reservation__c, Reservation__r.Block_Code__c, Case__c
    //                 FROM Case_Reservations__r
    //                 WHERE Reservation__r.Block_Code__c != NULL)
    //             FROM Case
    //             WHERE Block_Code_Flag__c != NULL
    //     ];
    //     for (Case thisCase : blockCodeCases) {
    //         String blockCode = thisCase.Block_Code__c;
    //         addAllIfNull(blockCode, thisCase.Case_Reservations__r);
    //         if (blockCode != null) {
    //             checkExistingReservations(thisCase, newBlockCodes, casesToAddNewReservation);
    //         }
    //     }
    //     if (!casesToAddNewReservation.isEmpty()) {
    //         Map<String, List<Order>> blockCodeToOrder = new Map<String, List<Order>>();
    //         fillBlockCodeMap(newBlockCodes, blockCodeToOrder);
    //         if (!blockCodeToOrder.isEmpty()) {
    //             for (Case thisCase : casesToAddNewReservation) {
    //                 createNewReservation(blockCodeToOrder, thisCase);
    //             }
    //         }
    //     }
    //     deleteReservations();
    // }

    // private void createNewReservation(Map<String, List<Order>> blockCodeToOrder, Case thisCase) {
    //     if (blockCodeToOrder.containsKey(thisCase.Block_Code__c)) {
    //         for (Order thisOrder : blockCodeToOrder.get(thisCase.Block_Code__c)) {
    //             newReservations.add(new Case_Reservation__c(
    //                 RecordTypeId = recordTypes.get(ROOM_BOOKING_RT).getRecordTypeId(),
    //                 Agent_Booked_By__c = thisCase.Agent_Booked_By__c,
    //                 Case__c = thisCase.Id, Reservation__c = thisOrder.Id
    //             ));
    //         }
    //     }
    // }

    // private void fillBlockCodeMap(Set<String> newBlockCodes, Map<String, List<Order>> blockCodeToOrder) {
    //     Order[] orders = [
    //         SELECT Block_Code__c
    //         FROM Order
    //         WHERE Block_Code__c IN :newBlockCodes
    //     ];
    //     for (Order anOrder : orders) {
    //         if (blockCodeToOrder.containsKey(anOrder.Block_Code__c)) {
    //             blockCodeToOrder.get(anOrder.Block_Code__c).add(anOrder);
    //         } else {
    //             blockCodeToOrder.put(anOrder.Block_Code__c, new List<Order>{anOrder});
    //         }
    //     }
    // }

    // private void addAllIfNull(String num, List<Case_Reservation__c> reservations) {
    //     if (num == null && !reservations.isEmpty()) {
    //         reservationsToDelete.addAll(reservations);
    //     }
    // }

    // private void deleteReservations() {
    //     if (!reservationsToDelete.isEmpty()) {
    //         delete reservationsToDelete;
    //     }
    // }

    // private void deleteNotRelevantRelatedBookings() {
    //     for (Case thisCase : bookingCases) {
    //         String bookingNum = thisCase.Booking_Confirmation_Number_s__c;
    //         addAllIfNull(bookingNum, thisCase.Case_Reservations__r);
    //         if (bookingNum != null && !thisCase.Case_Reservations__r.isEmpty()) {
    //             checkExpiredReservations(thisCase, bookingNum);
    //         }
    //     }
    //     deleteReservations();
    // }

    // private void checkExpiredReservations(Case thisCase, String bookingNum) {
    //     for (Case_Reservation__c caseRes : thisCase.Case_Reservations__r) {
    //         Integer indexOf = thisCase.Case_Reservations__r.indexOf(caseRes);
    //         if (caseRes.Reservation__r.Confirmation_Number__c != null) {
    //             if (!bookingNum.contains(caseRes.Reservation__r.Confirmation_Number__c)) {
    //                 reservationsToDelete.add(caseRes);
    //                 thisCase.Case_Reservations__r.remove(indexOf);
    //                 continue;
    //             }
    //         }
    //         if (caseRes.Spa_Booking__r.Confirmation_Number__c != null) {
    //             if (!bookingNum.contains(String.valueOf(caseRes.Spa_Booking__r.Confirmation_Number__c))) {
    //                 reservationsToDelete.add(caseRes);
    //                 thisCase.Case_Reservations__r.remove(indexOf);
    //             }
    //         }
    //     }
    // }
}