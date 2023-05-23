@SuppressWarnings('PMD.CyclomaticComplexity')
public with sharing class CaseTriggerHandler {

    private static final String CREATE_BOOKING_JOB_NAME = 'Create Booking For Case Scheduled Job';

	List<Case> newCases;
	Map<Id, Case> oldCases;

    public CaseTriggerHandler() {
        oldCases = Trigger.oldMap != null ? (Map<Id, Case>) Trigger.oldMap : new Map<Id, Case>();
        newCases = Trigger.new != null ? (List<Case>) Trigger.new : new List<Case>();
    }

    public void dispatch() {
        if (Trigger.isBefore) {
            if (Trigger.isUpdate) {
                CaseTriggerHandler.setGroupMeetingCheckboxes(newCases, oldCases);
                CaseTriggerHandler.setRTandDepartment(newCases, oldCases);
                CaseTriggerHandler.checkBookings(newCases, oldCases);
            }
            if (Trigger.isInsert) {
                CaseTriggerHandler.checkBookings(newCases, oldCases);
            }       
        }
    }
    
    public static void checkBookings(List<Case> newCases, Map<Id, Case> oldCases) {
        if (oldCases == null || oldCases.isEmpty()) {
            handleBookingsOnInsert(newCases);
        } else {
            for (Case newCase : newCases) {
                Case oldCase = oldCases.get(newCase.Id);
                handleBookingsOnUpdate(newCase, oldCase);
            }
        }
        String createBookingJobName = '%' + CREATE_BOOKING_JOB_NAME + '%';
        List<CronJobDetail> cronJobDetails = [SELECT Id, Name, JobType FROM CronJobDetail WHERE Name LIKE :createBookingJobName LIMIT 1];
        if (cronJobDetails.isEmpty()) {
            Datetime nextScheduleTime = System.now().addMinutes(1);
            String hour = String.valueOf(nextScheduleTime.hour());
            String minutes = String.valueOf(nextScheduleTime.minute());
            String seconds = String.valueOf(nextScheduleTime.second());
            String cronExpression = '0 ' + minutes + ' ' + hour + ' * * ?' ;
            CreateBookingsSched sched = new CreateBookingsSched();
            Id jobId = System.schedule(CREATE_BOOKING_JOB_NAME + DateTime.now().getTime(), cronExpression, sched);       
        }
    }

    public static void handleBookingsOnInsert(List<Case> newCases) {
        for (Case newCase : newCases) {
            if (newCase.Booking_Confirmation_Number_s__c != null) {
                newCase.Booking_Confirmation_Flag__c = true;
            }
            if (newCase.Block_Code__c != null) {
                newCase.Block_Code_Flag__c = true;
            }
        }
    }

    public static void handleBookingsOnUpdate(Case newCase, Case oldCase) {
        if (newCase.Booking_Confirmation_Number_s__c != oldCase.Booking_Confirmation_Number_s__c) {
            if (newCase.Booking_Confirmation_Flag__c == false) {
                newCase.Booking_Confirmation_Flag__c = true;
            }
        }
        if (newCase.Block_Code__c != oldCase.Block_Code__c) {
            if (newCase.Block_Code_Flag__c == false) {
                newCase.Block_Code_Flag__c = true;
            }
        }
    }
    
    public static void setGroupMeetingCheckboxes(List<Case> newCases, Map<Id, Case> oldCases) {
        Set<String> groupBookings = new Set<String>{'GROUPS', 'Heath_G', 'Manch_G'};
        Set<String> londonMeets = new Set<String>{'Bsh_Keni', 'Graft_ME', 'Hamp_ME', 'Heath_ME', 'LONMEET', 'Manch_ME', 'Mayf_ME', 'Mercer_ME', 'NPW_ME', 'Susse_ME', 'Vand_ME', 'WEDDINGS'};
        Set<String> foodBeverage = new Set<String>{'FandB'};

        for (Case newCase : newCases) {
            if (newCase.Group_Id__c != oldCases.get(newCase.Id).Group_Id__c) {
                if (groupBookings.contains(newCase.Group_Id__c)) {
                    newCase.Group_Bookings__c = true;
                } else 
                    if (londonMeets.contains(newCase.Group_Id__c)) {
                        newCase.London_Meetings__c = true;
                    } else 
                        if (foodBeverage.contains(newCase.Group_Id__c)) {
                            newCase.Food_And_Beverage__c = true;
                        }
            }
        }
        System.debug('fill check method  Group_Bookings__c ' + newCases[0].Group_Bookings__c);
        System.debug('fill check method  London_Meetings__c ' + newCases[0].London_Meetings__c);
        System.debug('fill check method  London_Meetings__c ' + newCases[0].Food_And_Beverage__c);
        System.debug('fill check method  Department__c ' + newCases[0].Department__c);
    }

    public static void setRTandDepartment(List<Case> newCases, Map<Id, Case> oldCases) {
        List<Case> changedCategoryCases = new List<Case>();
        for (Case aCase : newCases) {
            String oldCaseCategory = oldCases.get(aCase.Id).Category__c;
            if (aCase.Category__c != oldCaseCategory && String.isNotBlank(aCase.Category__c)) {
                changedCategoryCases.add(aCase);
            }
        }
        if (!changedCategoryCases.isEmpty()) {
            Map<String, Set<Case_Record_Type_Mapping__mdt>> categoryToMap = new Map<String, Set<Case_Record_Type_Mapping__mdt>>();
            fillCategoryMapping(categoryToMap);
            for (Case newCase : changedCategoryCases) {
                if (categoryToMap.containsKey(newCase.Category__c)) {
                    changeCaseRT(newCase, categoryToMap);
                }
            }
        }
    }

    public static void changeCaseRT(Case newCase, Map<String, Set<Case_Record_Type_Mapping__mdt>> categoryToMap) {
        Map<String, Schema.RecordTypeInfo> nameToRecordType = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName();
        Map<Id, Schema.RecordTypeInfo> idToRecordType = Schema.SObjectType.Case.getRecordTypeInfosById();        
        Case_Record_Type_Mapping__mdt recToMap;
        String thisCaseRtName = idToRecordType.get(newCase.RecordTypeId).Name;
        // String depName = 'Guest Experience Team';
        // if (newCase.Group_Bookings__c) {

        // }
        for (Case_Record_Type_Mapping__mdt mapping : categoryToMap.get(newCase.Category__c)) {
            if (mapping.Record_Type__c != thisCaseRtName) {

                if ((mapping.Department__c == 'Groups' && newCase.Group_Bookings__c)
                    || (mapping.Department__c == 'Events' && newCase.London_Meetings__c) 
                    || (mapping.Department__c == 'Food & Beverage' && newCase.Food_And_Beverage__c) 
                    || (mapping.Department__c == 'Guest Experience Team' && !newCase.Group_Bookings__c && !newCase.London_Meetings__c && !newCase.Food_And_Beverage__c)) {
                        recToMap = mapping;
                        break;
                }
            } 
        }
        if (recToMap != null && nameToRecordType.containsKey(recToMap.Record_Type__c)) {
            System.debug('Assign record type runs = ' + nameToRecordType);
            newCase.RecordTypeId = nameToRecordType.get(recToMap.Record_Type__c).getRecordTypeId();
            if (recToMap.Department__c == 'Guest Experience Team') {
                newCase.Department__c = 'Central Guest Services';
            } else {
                newCase.Department__c = recToMap.Department__c;
            }
            
            newCase.EntitlementId = recToMap.Entitlement_Id__c;
        }
    }

    public static void fillCategoryMapping(Map<String, Set<Case_Record_Type_Mapping__mdt>> categoryToMap) {
        Case_Record_Type_Mapping__mdt[] mappings = [
            SELECT Category__c, Department__c, Record_Type__c, Entitlement_Id__c, MasterLabel
            FROM Case_Record_Type_Mapping__mdt
        ];
        for (Case_Record_Type_Mapping__mdt mapping : mappings) {
            if (categoryToMap.containsKey(mapping.Category__c)) {
                categoryToMap.get(mapping.Category__c).add(mapping);
            } else {
                categoryToMap.put(mapping.Category__c, new Set<Case_Record_Type_Mapping__mdt>{mapping});
            }
        }
    }
}