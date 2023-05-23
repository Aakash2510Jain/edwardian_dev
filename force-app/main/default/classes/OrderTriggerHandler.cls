/**
 * @author Vasile Fana <vasile.fana@cloudshiftgroup.com>
 * @date 2020-12-01
 * @group CloudShiftGroup
 * @description  This handler class is responsible for trigger actions on the 
 *               order (Booking) records
 *
 * Date          author             Change Description
 * ---------------------------------------------------------------------------------------------------------------------------------
 * 2020-12-01    Vasile Fana       Created Class
 * 2021-04-06    Andrei Budescu    Custom Notification M&E High Value extension
 * 2021-04-20    Andrei Budescu    Update After Insert. Removed logic related to Campaign from Before Insert, After and Before Update
 *                                 Added logic to calculate Gross Revenue Share on After Update processOrdersChangedGrossRevenue
 */
@SuppressWarnings('PMD')
public without sharing class OrderTriggerHandler extends TriggerHandlerFramework {

    private static final String NEWLY_ACCOUNT_NAME = 'Newly Imported Company';
    private static List<Order> ordersWithChangedGrossRevenue = new List<Order>();
    private static Map<Id, Set<Id>> orderIdToCampaignIdsMap = new Map<Id, Set<Id>>();

    private static Map<String, RecordTypeInfo> taskRTs = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName();
    private static Map<String, RecordTypeInfo> orderRTs = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName();
    private static Map<String, Id> queues {
        get {

            if (queues == null) {
                queues = new Map<String, Id>();
                for (Group g : [SELECT Id, developerName FROM Group]) {
                    queues.put(g.developerName, g.Id);
                }
            }
            return queues;
        }
        set;
    }

    private static Map<String, Id> collaborationGroups {
        get {
            if (collaborationGroups == null) {
                collaborationGroups = new Map<String, Id>();
                for (CollaborationGroup g : [SELECT Id, name FROM CollaborationGroup]) {
                    collaborationGroups.put(g.name, g.id);
                }
            }
            return collaborationGroups;
        }
        set;
    }

    private static Map<Id, Property__c> properties {
        get {
            if (properties == null) {
                properties = new Map<Id, Property__c>();
                for (Property__c p : [SELECT Id, Name FROM Property__c]) {
                    properties.put(p.id, p);
                }
            }
            return properties;
        }
        set;
    }
    
    private static Map<String, Id> notificationIds {
        get {
            if (notificationIds == null) {
                notificationIds = new Map<String, Id>();
                for (CustomNotificationType type : [SELECT id, developerName FROM CustomNotificationType]) {
                    notificationIds.put(type.developerName, type.id);
                }
            }
            return notificationIds;
        }
        set;
    }

    private static boolean runPreInsertOnceOnly = false;
    private static boolean runPostInsertOnceOnly = false;

    private static boolean runPreUpdateOnceOnly = false;
    private static boolean runPostUpdateOnceOnly = false;

    public override void beforeInsert() {
    
        if (!runPreInsertOnceOnly) {

            doPreInsertProcessBuilderReplacementTasks((List<Order>)Trigger.new);
            //runPreInsertOnceOnly = true;
        }
    }

    public override void afterInsert() {
        if (!runPostInsertOnceOnly) {
            doPostInsertProcessBuilderReplacementTasks((Map<Id, Order>)Trigger.newMap);

        }

        // Populate orderIdToCampaignIdsMap with Order ID and linked Set of Campaign IDs
        OrderToCampaignMatcher orderMatchCampaign = new OrderToCampaignMatcher();
        orderIdToCampaignIdsMap = orderMatchCampaign.findMatchingCampaigns(
            (List<Order>) Trigger.new
        );

        // Create Influence Room Booking Records using the Map of Order and Campaign IDs
        if (!orderIdToCampaignIdsMap.isEmpty()) {
            OrderToCampaignMatchingServices orderToCampaingServices = new OrderToCampaignMatchingServices();
            orderToCampaingServices.createOrderToCampaignInfluencingRecords(
                orderIdToCampaignIdsMap,
                (Map<Id, Order>) Trigger.newMap
            );
        }
    }

    @testVisible
    private static void doPreInsertProcessBuilderReplacementTasks(List<Order> newOrders) {

        Map<Id, Account> accounts = getAccounts(newOrders);
        for (Order o : newOrders) {
            Account acc = accounts.get(o.accountId);
            if (acc != null && acc.isPersonAccount) {
                o.Contact_Name__c = acc.PersonContactId;
            }
        }
    }

    @testVisible
    private static Map<Id, Account> getAccounts(List<Order> newOrders) {

        Set<Id> accountIds = new Set<Id>();
        for (Order o : newOrders) {
            accountIds.add(o.AccountId);
        }

        Map<Id, Account> accounts = new Map<Id, Account>([
            SELECT Id, PMS_Profile_Id__c, isPersonAccount, personContactId, Market_Segment__c, Name, Owner.FirstName, ParentId
           		 FROM Account
             	    WHERE Id IN :accountIds]);

        return accounts;
    }
    
    //Map of Contacts to be used in the createNotificationText method
    private static Map<Id, Contact> contacts {
        get {

            if (contacts == null) {
                contacts = new Map<Id, Contact>();
                for (Contact ct : [SELECT Id, FirstName, LastName FROM Contact]) {
                    contacts.put(ct.id, ct);
                }
            }
            return contacts;
        }
        set;
    }
    
    //Map of Accounts to be used in the creation of notification
    private static Map<Id, Account> accountsMap {
        get {

            if (accountsMap == null) {
                accountsMap = new Map<Id, Account>();
                for (Account acc : [SELECT Id, FirstName, LastName, ParentId, OwnerId FROM Account]) {
                    accountsMap.put(acc.id, acc);
                }
            }
            return accountsMap;
        }
        set;
    }
    
    private static Map<String, Group> getSalesLeadsQueuesMap(){
        String salesLeadGroupNames = '%Sales Leads%';
        Map<String, Group> queuesMap = new Map<String, Group>();
        
        for (Group queue : [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name LIKE :salesLeadGroupNames]){
            queuesMap.put(queue.Name, queue);
        }
        
        return queuesMap;
    }

    @testVisible
    private static void doPostInsertProcessBuilderReplacementTasks(Map<Id, Order> newOrders) {
        
        Map<Id, Account> accounts = getAccounts(newOrders.values());
        Set<String> hotels = new Set<String> { 'May Fair', 'Heathrow', 'Manchester' };
        Set<String> hotelsNameForNotification = new Set<String> {'Londoner', 'May Fair', 'Heathrow', 'Manchester' };
        Set<String> hotels2 = new Set<String> { 'Grafton', 'Bloomsbury St', 'New Providence Wharf', 'Hampshire', 'Mercer St', 'Vanderbilt', 'Berkshire', 'Kenilworth' };
        Set<String> roomTypes = new Set<String> { 'KNED', 'KNXT', 'KNE1', 'KNEN', 'KNE2' };
        Set<String> vipSegments = new Set<String> { 'Corporate', 'LRA Corporate', 'Non LRA Corporate', 'Consortia' };

        List<Task> tasksToCreate = new List<Task>();
        List<FeedItem> chatterPostsToCreate = new List<FeedItem>();
        List<Messaging.CustomNotification> customNotificationsToCreate = new List<Messaging.CustomNotification>();
        Map<String, Group> salesLeadQueuesMap = getSalesLeadsQueuesMap();
        for (Order o : newOrders.values()) {
            Account parent = accounts.get(o.AccountId);

            // Post-reservation call task
            if (o.Reservation_Stage__c == 'Pre-Arrival' && String.isNotBlank(o.Contact_Name__c) && parent != null && parent.isPersonAccount) {
                tasksToCreate.add(createTask(o.CreatedDate.addDays(1), queues.get('Central_Guest_Services'), 'Central_Guest_Services', o.Id, 'Not Started', 'Post Reservation Call: ' + o.Guest_First_Name__c + ' ' + o.Guest_Last_Name__c, o.id, parent.personContactId, false, null, 'Normal', null));
            }

            // M&E high value
            Property__c pt = properties.get(o.Hotel__c);
            if(
                (pt != null && o.Gross_Revenue__c != null && o.RecordTypeId == orderRTs.get('M_E').getRecordTypeId()) 
                    && (
                       (hotelContainsInProperty(pt.Name, hotels) && o.Gross_Revenue__c >= 20000) || 
                       (pt.Name.contains('Londoner') && o.Gross_Revenue__c >= 50000)|| 
                       (hotelContainsInProperty(pt.Name, hotels2) && o.Gross_Revenue__c >= 10000) || 
                       (pt.Name.contains('Sussex') && o.Gross_Revenue__c >= 5000)
                    ) 
              )
            {

                List<Account> parentAccCompany = new List<Account>{accountsMap.get(parent.ParentId)};
                List<Account> parentAccPms = new List<Account>{accountsMap.get(o.PMS_Agent__c)};
                Set<String> recipients = new Set<String>();
                System.debug('Parent: '+parentAccCompany);
                //Notification to Owner of Parent Account of Company
                if(parent != null && parent.Name != NEWLY_ACCOUNT_NAME && parentAccCompany[0] != null){
                    recipients.add(parentAccCompany[0].OwnerId);
                }
                //Notification to Owner of Parent Account of PMS Agent
                if(o.PMS_Agent__c != null && parentAccPms[0] != null){
                    recipients.add(parentAccPms[0].OwnerId);
                }
                System.debug('recipients: '+recipients);
                //Send notification to Queue Sales Leads if Company is Newly Account Name and Notification for the Rest of Queues
                String groupName = '';
                for (String item : hotelsNameForNotification) {
                    if (pt.Name.contains(item)) {
                        groupName = item;
                    }
                }
                if(String.isBlank(groupName)){
                    groupName = 'Sales Leads (Central)';
                }
                Boolean isHotelQueue = false;
                for(String queueName : salesLeadQueuesMap.keySet()){
                    if(queueName.contains(groupName)){
                        recipients.add(salesLeadQueuesMap.get(queueName).Id);
                        isHotelQueue = true;
                    }
                }
                if(!isHotelQueue){
                    recipients.add(salesLeadQueuesMap.get('Sales Leads (Central)').Id);
                    System.debug('salesLeadQueues: '+salesLeadQueuesMap.get('Sales Leads (Central)').Id);
                }
                
                if(parent != null && parent.Name == NEWLY_ACCOUNT_NAME){
                    if(!recipients.contains(salesLeadQueuesMap.get('Sales Leads (Central)').Id)){
                        recipients.add(salesLeadQueuesMap.get('Sales Leads (Central)').Id);
                    }
                } 
                
            //Send M&E High Value Notifications
                if (!recipients.isEmpty()) {
                    System.debug('Final List Of Recipients to be notified: '+recipients);
                    Messaging.CustomNotification notification = createNotification(notificationIds.get('Account_Owner'), 'High Value Booking for M&E for ' + parent.Name, createNotificationText(o, 'M&E'), o.id);
                    notification.send(recipients);
                }
            }
            
            // VIP reservation
            if (o.Length_of_stay__c >= 4 && vipSegments.contains(parent.Market_Segment__c) && parent != null && parent.Name != NEWLY_ACCOUNT_NAME) {

                tasksToCreate.add(createTask(o.Check_In_Date_Time__c, o.ownerId, 'Sales', null, 'Not Started', 'Long Stay Reservation follow up', o.id, null, true, null, 'Normal', null));
                chatterPostsToCreate.add(createChatterPost(o.id, createChatterBodyText(o, parent)));

                // can't bulk send these???
                Messaging.CustomNotification notification = createNotification(notificationIds.get('Account_Owner'), parent.Name + ' has made a booking!', createNotificationText(o, 'LongStay'), o.id);
                notification.send(new Set<String> { parent.ownerId });
            }

            // VIP room check - HK
            if (roomTypes.contains(o.Room_Type_Booked__c) && o.Check_in_Date_Time__c != null) {


                tasksToCreate.add(createTask(null, queues.get('Housekeeping_The_Mayfair_Hotel'), 'Housekeeping', o.id, 'Not Started', 'VIP Guest Introduction - Housekeeping', o.id, parent.personContactId, false, null, 'High', 'Introduce yourself to the guest and arrange a Turndown time'));

                String cGrpName = 'Maintenance Heads - The May Fair Hotel';
                String bodyText = 'Hi ' + cGrpName +',\nA task has been assigned for:\nName: ' + parent.Name + '\nCheck in Date/Time: ' + o.Check_In_Date_Time__c + '\nReservation: ' + o.Id + '\n\nPlease assign a Housekeeping team member to arrange a Turndown Time.\n\nSystem Admin';
                chatterPostsToCreate.add(createChatterPost(collaborationGroups.get(cGrpName), bodyText));     
            }

            // housekeeping assistance
            if (o.Housekeeping_Departure_Assistance__c) {

                tasksToCreate.add(createTask(o.Time_of_Assistance__c, queues.get('Housekeeping_The_Mayfair_Hotel'), 'Housekeeping', o.id, 'Not Started', 'Housekeeping Departure Assistance', o.id, parent.personContactId, true, o.Time_of_Assistance__c, 'Normal', o.Guest_First_Name__c + ' ' + o.Guest_Last_Name__c + ' requires assistance with their departure.'));
            }
        }

        Database.insert(tasksToCreate, false);
        Database.insert(chatterPostsToCreate, false);
    }

    private static Boolean hotelContainsInProperty(String propertyName, Set<String> listOfHotels) {
        
        Boolean hotelContainsInProperty = false; 
        for (String p : listOfHotels) {

            hotelContainsInProperty = propertyName.contains(p);
            break;
        }

        return hotelContainsInProperty;
    }

    @testVisible
    private static void doPostUpdateProcessBuilderReplacementTasks(Map<Id, Order> newOrders, Map<Id, Order> oldOrders) {

        Map<Id, Date> changedOrders = new Map<Id, Date>();
        List<Task> tasksToChange = new List<Task>();
        List<Task> tasksToCreate = new List<Task>();
        List<FeedItem> chatterPostsToCreate = new List<FeedItem>();

        Set<Id> parentOrders = new Set<Id>();

        for (Id orderId : newOrders.keySet()) {

            Order chgdOrder = newOrders.get(orderId);
            Order oldOrder = oldOrders.get(orderId);

            if (chgdOrder.Arrival_Date__c != oldOrder.Arrival_Date__c) {
                changedOrders.put(orderId, chgdOrder.Arrival_Date__c);
            }
            
            if (chgdOrder.fireScheduler__c != oldOrder.fireScheduler__c) {

                if (chgdOrder.fireScheduler__c == 'Pre-Arrival' && chgdOrder.Account != null && chgdOrder.Account.personContactId != null) {
                    tasksToCreate.add(createTask(date.today(), queues.get('Central_Guest_Services'), 'Central_Guest_Services', chgdOrder.Id, 'Not Started', 'Pre-Arrival Call Task with: ' + chgdOrder.Guest_First_Name__c + ' ' + chgdOrder.Guest_Last_Name__c, chgdOrder.id, chgdOrder.Account.personContactId, false, null, 'Normal', null));
                }

                if (chgdOrder.fireScheduler__c == 'VIP Guest' && chgdOrder.Hotel__c != null && chgdOrder.Hotel__r.General_Manager__c != null) {
                    chatterPostsToCreate.add(createChatterPost(chgdOrder.Hotel__r.General_Manager__c, 'A VIP Guest is arriving in 15 minutes.\nGuest: ' + chgdOrder.Guest_First_Name__c + ' ' + chgdOrder.Guest_Last_Name__c));
                }

                if (chgdOrder.fireScheduler__c == 'Guest Departure' && chgdOrder.Account != null && chgdOrder.Account.personContactId != null) {
                    tasksToCreate.add(createTask(chgdOrder.Departure_Date__c, queues.get('Housekeeping_The_Mayfair_Hotel'), 'Housekeeping', chgdOrder.Id, 'Not Started', 'Please get in touch with the Guest to see if they need assistance', chgdOrder.id, chgdOrder.Account.personContactId, false, null, 'High', null));
                    tasksToCreate.add(createTask(chgdOrder.Departure_Date__c, queues.get('Lobby_Team_The_Mayfair_Hotel'), 'Lobby_Team', chgdOrder.Id, 'Not Started', 'Please get in touch with the Guest to see if they need assistance', chgdOrder.id, chgdOrder.Account.personContactId, false, null, 'High', null));
                }
            }

            // if the hotel lookup was cleaned up in the pre-update phase
            // then wipe out the orderItem in this post-update phase
            if (chgdOrder.Hotel__c == null && oldOrder.Hotel__c != null 
                    && chgdOrder.Archived_Hotel_Id__c != null && oldOrder.Archived_Hotel_Id__c == null) {

                parentOrders.add(chgdOrder.id);
            }
        }

        // clean out any orderItems as needed
        if (parentOrders.size() > 0) {

            List<OrderItem> items = [SELECT Id, Hotel__c FROM OrderItem WHERE Hotel__c != null AND OrderId IN :parentOrders];
            for (OrderItem item : items) {
                item.Hotel__c = null;
            }
            update items;
        }

        List<Task> affectedTasks = [SELECT
                                        Id, ActivityDate, reservation__c
                                    FROM
                                        Task
                                    WHERE
                                        reservation__c IN :changedOrders.keySet()
                                        AND subject LIKE 'Pre-Arrival Call%'];

        for (Task t : affectedTasks) {

            t.ActivityDate = changedOrders.get(t.reservation__c).addDays(-1);
        }

        // TODO - turn into combined list and merge
        Database.insert(tasksToCreate, false);
        Database.update(affectedTasks, false);
    }

    @testVisible
    private static String createChatterBodyText(Order o, Account a) {

        return 'Hi ' + a.Owner.FirstName + '\n'
                   + 'Your Key Account has booked a long stay, please see Booking details below:\n'
                   + 'Name: ' + a.Name + '\n'
                   + 'Check In Date: ' + o.Check_In_Date_Time__c + '\n'
                   + 'Hotel: ' + o.Hotel__c + '\n'
                   + 'Guest Name: ' + o.Guest_First_Name__c + ' ' + o.Guest_Last_Name__c + '\n'
                   + 'Length of Stay: ' + o.Length_of_Stay__c;
    }

    @testVisible
    private static FeedItem createChatterPost(Id parentRecordId, String bodyText) {

        return new FeedItem(
            ParentId = parentRecordId,
            Body = bodyText
        );
    }

    @testVisible
    private static String createNotificationText(Order o, String notificationType) {

        Property__c pt = properties.get(o.Hotel__c);
        Contact ct = contacts.get(o.Contact_Name__c);

        if (pt != null && ct != null) {
            
            if (notificationType == 'LongStay') {
    
                return 'Booking details:\n' 
                            + 'Name: ' + ((o.Account.Name == null) ? '' : o.Account.Name) + '\n'
                            + 'Arrival Date: ' + ((o.Arrival_Date__c == null) ? '' : '' + String.valueOf(Date.newInstance(o.Arrival_Date__c.year(), o.Arrival_Date__c.month(), o.Arrival_Date__c.day()))) + '\n'
                            + 'Hotel: ' + ((o.Hotel__c == null) ? '' : '' + o.Hotel__c) + '\n'
                            + 'Guest Name: ' + ((o.Guest_First_Name__c == null) ? '' : o.Guest_First_Name__c) + ' ' + ((o.Guest_Last_Name__c == null) ? '' : o.Guest_Last_Name__c) + '\n'
                            + 'Length of Stay: ' + ((o.Length_of_Stay__c == null) ? '' : '' + o.Length_of_Stay__c);
            }
    
            if (notificationType == 'M&E') {
                return 'Contact: ' + ((ct.FirstName == null) ? '' : ct.FirstName)  + ' ' + ((ct.LastName == null) ? '' : ct.LastName) + '\n'
                            + '\n'
                            + 'Hotel: ' + ((pt.Name == null) ? '' : pt.Name) + '\n'
                            + 'Booking Type: ' + ((o.Type == null) ? '' : o.Type) + '\n'
                            + 'Arrival Date: ' + ((o.Arrival_Date__c == null) ? '' : '' + String.valueOf(Date.newInstance(o.Arrival_Date__c.year(), o.Arrival_Date__c.month(), o.Arrival_Date__c.day()))) + '\n'
                            + 'Event Days: ' + ((o.Length_of_Stay__c == null) ? '' : '' + o.Length_of_Stay__c) + '\n'
                            + '\n'
                            + 'Estimated Event Revenue: ' + ((o.Event_Revenue__c == null) ? '' : '' + '£' + o.Event_Revenue__c.format()) + '\n'
                            + 'Estimated Rooms Revenue: ' + ((o.Room_Revenue__c == null) ? '' : '' + '£' + o.Room_Revenue__c.format());
            }
        }

        return '';
    }

    @testVisible
    private static Task createTask(Datetime dueDate, Id owner, String recordTypeName, Id reservation, String sts, String subj, Id relatedToId, Id nameId, Boolean setReminder, Datetime reminderDate, String priorityLevel, String description) {

        return new Task(
            ActivityDate = dueDate != null ? Date.newInstance(dueDate.year(), dueDate.month(), dueDate.day()) : null,
            OwnerId = owner,
            recordTypeId = recordTypeName != null ? taskRTs.get(recordTypeName).getRecordTypeId() : null,
            Reservation__c = reservation,
            Status = sts,
            Subject = subj,
            WhatId = relatedToId,
            WhoId = nameId,
            IsReminderSet = setReminder,
            ReminderDateTime = reminderDate,
            Priority = priorityLevel
        );
    }

    @testVisible
    private static Messaging.CustomNotification createNotification(Id notificationId, String title, String body, Id recordId ) {
        return new Messaging.CustomNotification(
            notificationId, null, title, body, recordId, null
        );
    }

    public override void beforeUpdate() {
        doPreUpdateProcessBuilderReplacementTasks((Map<Id, Order>)Trigger.newMap, (Map<Id, Order>)Trigger.oldMap);
    }

    @testVisible
    private static void doPreUpdateProcessBuilderReplacementTasks(Map<Id, Order> chgdOrders, Map<Id, Order> oldOrders) {

        Set<String> keepHotelStatus = new Set<String> { 'CIN', 'RES' };

        for (Id orderId : chgdOrders.keySet()) {

            Order newOrder = chgdOrders.get(orderId);
            Order oldOrder = oldOrders.get(orderId);

            if (newOrder.Reservation_Status__c != oldOrder.Reservation_Status__c
                    && !String.isBlank(newOrder.Hotel__c)
                    && !keepHotelStatus.contains(newOrder.Reservation_Status__c)) {

                newOrder.Archived_Hotel_Id__c = newOrder.Hotel__c;
                newOrder.Hotel__c = null;
                newOrder.Room__c = null;
            }
        }
    }

    public override void afterUpdate() {

        if (!runPostUpdateOnceOnly) {
            doPostUpdateProcessBuilderReplacementTasks((Map<Id, Order>)Trigger.newMap, (Map<Id, Order>)Trigger.oldMap);
        }

        // Process Updated Orders with the Field Gross Revenue updated
        processOrdersChangedGrossRevenue((List<Order>) Trigger.new, (Map<Id, Order>) Trigger.oldMap);

        // Call function calculateGrossRevenueShare to recalculate the Gross Revenue on the IBR records
        List<Order> dedupedOrders = new List<Order>(new Set<Order>(ordersWithChangedGrossRevenue));
        InfluencedRoomBookingServices influenceRBServices = new InfluencedRoomBookingServices();
        influenceRBServices.calculateGrossRevenueShare(
            dedupedOrders
        );
    }

    /**
     * Function to populate the global Lists ordersWithChangedGrossRevenue with the Orders records
     * when the Gross Revenue field is updated
     *
     * @param List<Order> ordersToProcess - The list of updated Orders
     * @param Map<Id,Order> oldOrders     - Map of Order ID and Order record before update
     *
     * @return void
     */
    private void processOrdersChangedGrossRevenue(List<Order> ordersToProcess,  Map<Id, Order> oldOrders ) {
        
        //need to clean out between batch runs
        ordersWithChangedGrossRevenue = new List<Order>();

        for (Order order : ordersToProcess) {
            Order oldOrder = oldOrders.get(order.Id);
            if(order.Gross_Revenue__c != oldOrder.Gross_Revenue__c && order.Gross_Revenue__c != null){
                ordersWithChangedGrossRevenue.add(order);
            }
        }
    }

    private void addOrderToMap(String matchingId, Order order, Map<String, List<Order>> ordersToIdMap) {
        List<Order> orders = new List<Order>();
        if(ordersToIdMap.containsKey(matchingId)) {
            orders = ordersToIdMap.get(matchingId);
        }
        orders.add(order);
        ordersToIdMap.put(matchingId, orders);
    }
}