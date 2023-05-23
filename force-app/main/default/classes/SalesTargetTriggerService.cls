@SuppressWarnings('PMD.CyclomaticComplexity') 
public without sharing class SalesTargetTriggerService {

    public static void autocompleteStartAndEndDate(List<Sales_Target__c> newList) {
        List<Periods__mdt> periods = [
                SELECT End_Date__c, Period__c, Quarter__c, Start_Date__c, Year__c
                FROM Periods__mdt
        ];

        Map<String, QuarterToTimeWrapper> quarterToTimeWrapperMap = new Map<String, QuarterToTimeWrapper>();

        for (Periods__mdt period : periods) {
            if (!quarterToTimeWrapperMap.containsKey(period.Quarter__c + period.Year__c)) {
                quarterToTimeWrapperMap.put(period.Quarter__c + period.Year__c, new QuarterToTimeWrapper(period.Start_Date__c, period.End_Date__c));
                continue;
            }

            QuarterToTimeWrapper timeWrap = quarterToTimeWrapperMap.get(period.Quarter__c + period.Year__c);

            setStartEndTime(period, timeWrap);
        }

        for (Sales_Target__c salesTargetItem : newList) {
            for (Periods__mdt periodItem : periods) {
                if (salesTargetItem.Year__c == null || salesTargetItem.Target_Period__c == null) {
                    continue;
                }

                if (salesTargetItem.Period__c == null) {
                    salesTargetItem.Target_Start_Date__c = Date.newInstance(Integer.valueOf(salesTargetItem.Year__c), 1, 1);
                    salesTargetItem.Target_End_Date__c = Date.newInstance(Integer.valueOf(salesTargetItem.Year__c), 12, 31);

                    break;
                }

                if (salesTargetItem.Year__c == periodItem.Year__c && salesTargetItem.Period__c == periodItem.Period__c) {
                    salesTargetItem.Target_Start_Date__c = periodItem.Start_Date__c;
                    salesTargetItem.Target_End_Date__c = periodItem.End_Date__c;

                    break;
                } else if (salesTargetItem.Year__c == periodItem.Year__c && quarterToTimeWrapperMap.keySet().contains(salesTargetItem.Period__c + salesTargetItem.Year__c)) {
                    salesTargetItem.Target_Start_Date__c = quarterToTimeWrapperMap.get(salesTargetItem.Period__c + salesTargetItem.Year__c).startDate;
                    salesTargetItem.Target_End_Date__c = quarterToTimeWrapperMap.get(salesTargetItem.Period__c + salesTargetItem.Year__c).endDate;

                    break;
                }
            }
        }
    }

    private static void setStartEndTime(Periods__mdt period, QuarterToTimeWrapper timeWrap) {
        if (period.Start_Date__c < timeWrap.startDate) {
            timeWrap.startDate = period.Start_Date__c;
        }

        if (period.End_Date__c > timeWrap.endDate) {
            timeWrap.endDate = period.End_Date__c;
        }
    }

    private class QuarterToTimeWrapper {
        public Date startDate;
        public Date endDate;

        public QuarterToTimeWrapper(Date startDate, Date endDate) {
            this.startDate = startDate;
            this.endDate = endDate;
        }
    }
}