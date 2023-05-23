/**
 * @Name:        BookingGiftAllocationBatch
 * @Description: Batch Class used to create Gift Allocate linked to the Booking records
 *
 * @author:      Andrei Budescu
 * @version:     1.0
 * Change Log
 *
 * Date         author              Change Description
 * -----------------------------------------------------------------------------------
 * 13/07/2021   Andrei Budescu      Created Class
 */
public without sharing class BookingGiftAllocationBatch implements Database.Batchable<Order>, Database.Stateful{

    // Set of Account Ids
    private Set<Id> guestIds = new Set<Id>();
    // Set of Property Ids
    private Set<Id> hotelIds = new Set<Id>();
    
    // Map of Order Id and Order record queried for today
    private Map<Id, Order> ordersQueriedMap = new Map<Id, Order>();
    
    // Map of Hotel Id and Budget for today
    private Map<Id, Budget__c> hotelIdBudgetMap = new Map<Id, Budget__c>();
    // List of Errors when trying to create Gift Allocation
    private List<String> errorGiftAllocationInsertList = new List<String>();
    // List of Errors when trying to create Gift Allocation Line Items
    private List<String> errorGiftAllocationLineItemInsertList = new List<String>();
    // Map Hotel Id and Budget Wrapper
    private Map<Id, BudgetWrapper> hotelIdBudgetWrapperMap = new Map<Id, BudgetWrapper>();
    // Map Hotel Id and List of String errors when Insert
    private Map<Id, List<String>> hotelIdErrorListMap = new Map<Id, List<String>>();

    // Booking Gift Allocation Batch Helper instance
    BookingGiftAllocationBatchHelper batchHelper = new BookingGiftAllocationBatchHelper();



    /**
     * Method for retrieve all existing Order records where the Arrival Date is Today
     * 
     * @param  bc                           - Batchable Context
     * 
     * @return List of Order Records
    */
    public Iterable<Order> start(Database.BatchableContext bc) {
        
        // Date when the Batch Class runs
        Date todaysDate = System.now().date().addDays(1);
        
        // Populate ordersQueriedMap with Today's Orders
        ordersQueriedMap = batchHelper.getOrdersToday(todaysDate);

        // Store Set of Guest Ids and Hotel Ids
        for (Order order : ordersQueriedMap.values()) {
            guestIds.add(order.AccountId);
            hotelIds.add(order.Hotel__c);
        }

        // Return List of Orders queried foor the execute context
        return ordersQueriedMap.values();
    }


    /**
     * Method to execute the logic of the Batch records returned on start
     * 
     * @param  bc                               - Batchable Context
     * @param List<Order> ordersQueried         - Orders queried on start()
     * 
     * @return void
    */
    public void execute (Database.BatchableContext bc, List<Order> ordersQueried) {

        // Query Budgets based on the Hotel Ids and Arrival Date of the Booking record
        Map<Id, Budget__c> budgetsQueriedMap = batchHelper.getBudgetsTodaysOrders(System.now().date(), hotelIds);
        // Query Map of GuestId and Guest(contains the related list of Always Allocated Items)
        Map<Id, Account> guestIdGuestMap = batchHelper.getTodaysGuests(guestIds);

        // Create BudgetWrapper using the budget records queried
        if (!budgetsQueriedMap.values().isEmpty()) {

            for (Budget__c budget : budgetsQueriedMap.values()) {
                
                //Map of Hotel Id and Budget Record
                hotelIdBudgetMap.put(budget.Hotel__c, budget);
    
                // Map of Hotel Id and Budget Wrapper
                List<GuestWrapper> guestWrapperList = new List<GuestWrapper>();
                BudgetWrapper budgetWrapperRecord = new BudgetWrapper();
                budgetWrapperRecord.balance = budget.Balance__c;
                budgetWrapperRecord.totalGiftCost = budget.Total_Gifts_Cost__c;
                budgetWrapperRecord.newGiftsCost = 0.0;
                budgetWrapperRecord.hotelEmailAddress = budget.Hotel__r.VIP_Email_Address__c;
                budgetWrapperRecord.hotelName = budget.Hotel__r.Name;
                budgetWrapperRecord.guests = guestWrapperList;

                hotelIdBudgetWrapperMap.put(budget.Hotel__c, budgetWrapperRecord);
            }

            // Create Gift Allocation for Bookings
            List<Gift_Allocation__c> newGiftAllocationBookingRecords = new List<Gift_Allocation__c>();
            for (Order order : ordersQueried) {
                // Calculate Total Price Gifts of the Guest
                Double totalPriceGiftsAlwaysAllocated = populateBudgetWrapperMap(order, guestIdGuestMap.get(order.AccountId).Always_Allocated_Gift_Items__r);

                // Create Gift Allocation for the Booking
                Gift_Allocation__c giftAllocationBooking = new Gift_Allocation__c(
                    Booking__c = order.Id,
                    Budget__c = hotelIdBudgetMap.get(order.Hotel__c).Id,
                    Guest_Name__c = order.AccountId,
                    CurrencyIsoCode = order.CurrencyIsoCode,
                    Delivery_Date__c = order.Arrival_Date__c,
                    Reservation_Stage__c = order.Reservation_Status__c,
                    Total_Price__c = totalPriceGiftsAlwaysAllocated
                );
                
                newGiftAllocationBookingRecords.add(giftAllocationBooking);

            }

            // Insert newly created Gift Allocation Records
            insertGiftAllocationList(newGiftAllocationBookingRecords);

            // Create Gift Allocation Line Items
            List<Gift_Allocation_Line_Item__c> giftAllocationBookingLineItems = new List<Gift_Allocation_Line_Item__c>();
            
            // Query Gift Allocation records after created
            newGiftAllocationBookingRecords = batchHelper.getGiftAllocationCreated(ordersQueriedMap.keySet());

            if (!newGiftAllocationBookingRecords.isEmpty()) {

                for (Gift_Allocation__c allocationRecord : newGiftAllocationBookingRecords) {
                
                    for (Always_Allocate_Gift_Item__c alwaysAllocatedRecord : guestIdGuestMap.get(ordersQueriedMap.get(allocationRecord.Booking__c).AccountId).Always_Allocated_Gift_Items__r) {
                        Gift_Allocation_Line_Item__c giftAllocationLineItem = new Gift_Allocation_Line_Item__c(
                            Gift_Allocation__c = allocationRecord.Id,
                            CurrencyIsoCode = allocationRecord.Booking__r.CurrencyIsoCode,
                            Quantity__c = alwaysAllocatedRecord.Quantity__c,
                            Status__c = 'Pending', 
                            Gift_Name__c = alwaysAllocatedRecord.Gift_Name__c
                        );

                        giftAllocationBookingLineItems.add(giftAllocationLineItem);
                    }
                
                }
                
                // Insert Gift Allocation Line Items
                insertGiftAllocationLineItemList(giftAllocationBookingLineItems);
                

            }
            
        }

    }


    /**
     * Method to send emails if budget has been exceeded or there have been errors on inserting records
     * 
     * @param  bc                               - Batchable Context
     * 
     * @return void
    */
    public void finish (Database.BatchableContext bc) {

        // Prepare Email for each Hotel where the Budget has been exceeded
        for (BudgetWrapper budgetWrapperRecord : hotelIdBudgetWrapperMap.values()) {

            if (budgetWrapperRecord.newGiftsCost > budgetWrapperRecord.balance) {
                
                sendBudgetEmails(budgetWrapperRecord);
            
            }
        }

        // Send Email With Errors
        for (String hotelId : hotelIdErrorListMap.keySet()) {
            
            // Prepare email to send if there were errors on DML
            if (!hotelIdErrorListMap.get(hotelId).isEmpty()) {
                
                //Send Email with Errors
                sendErrorEmails(hotelId, hotelIdErrorListMap.get(hotelId));

            }
        }
    }


    


    /**
     * Function to populate the map of Hotel Id and BudgetWrapper
     *
     * @param Order order                                                 - Order record where the budget is used
     * @param List<Always_Allocate_Gift_Item__c> alwaysAllocatedGiftList  - Always Allocated Gift Item List for the Guest
     *
     * @return totalPriceGiftsAlwaysAllocated
    */
    private Double populateBudgetWrapperMap(Order order, List<Always_Allocate_Gift_Item__c> alwaysAllocatedGiftList) {
        // Calculate Total Price Gifts of the Guest
        Double totalPriceGiftsAlwaysAllocated = 0;

        // List of GiftItemWrapper
        List<GiftItemWrapper> giftItemWrapperList = new List<GiftItemWrapper>();

        for (Always_Allocate_Gift_Item__c alwaysAllocatedGift : alwaysAllocatedGiftList) {
            //totalPriceGiftsAlwaysAllocated += alwaysAllocatedGift.Price__c;
            totalPriceGiftsAlwaysAllocated += alwaysAllocatedGift.Quantity__c * alwaysAllocatedGift.Price__c;
            // Add GiftItemWrapper records to the BudgetWrapper Map
            GiftItemWrapper giftItemWrapperRecord = new GiftItemWrapper();
            giftItemWrapperRecord.name = alwaysAllocatedGift.Gift_Name__r.Name;
            giftItemWrapperRecord.quantity = alwaysAllocatedGift.Quantity__c;
            giftItemWrapperRecord.price = alwaysAllocatedGift.Price__c;
            giftItemWrapperRecord.totalCost = (alwaysAllocatedGift.Quantity__c * alwaysAllocatedGift.Price__c);

            giftItemWrapperList.add(giftItemWrapperRecord);
        }

        GuestWrapper guestWrapperRecord = new GuestWrapper();
        guestWrapperRecord.name = order.Account.Name;
        guestWrapperRecord.vipCode = order.Account.VIP_Code__c;
        guestWrapperRecord.totalPriceGifts = totalPriceGiftsAlwaysAllocated;
        guestWrapperRecord.giftItems = giftItemWrapperList;
        // Add Items to the List of Guests linked to the BudgetWrapper
        hotelIdBudgetWrapperMap.get(order.Hotel__c).guests.add(guestWrapperRecord);
        hotelIdBudgetWrapperMap.get(order.Hotel__c).newGiftsCost += totalPriceGiftsAlwaysAllocated;

        return totalPriceGiftsAlwaysAllocated;
    }

    
    /**
     * Function to insert Gift Allocation of the Booking Records
     *
     * @param List<Gift_Allocation__c> newGiftAllocationBookingRecords      - List of Gift Allocation to be inserted
     *
     * @return void
    */
    public void insertGiftAllocationList(List<Gift_Allocation__c> newGiftAllocationBookingRecords) {

        Database.SaveResult[] srList = Database.insert(newGiftAllocationBookingRecords, false);
            
        Integer indexRecord = 0;
        
        // Iterate through each returned result
        for (Database.SaveResult sr : srList) {
            
            if (sr.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                System.debug('Successfully inserted Gift Allocation. Gift Allocation ID: ' + sr.getId());
            }
            else {
                // Get Record details of the failed record
                Gift_Allocation__c giftAllocationErrorRecord = newGiftAllocationBookingRecords[indexRecord];
                System.debug(giftAllocationErrorRecord);
                String hotelId = ordersQueriedMap.get(giftAllocationErrorRecord.Booking__c).Hotel__c;
                String guestName = ordersQueriedMap.get(giftAllocationErrorRecord.Booking__c).Account.Name;
                String orderNumber = ordersQueriedMap.get(giftAllocationErrorRecord.Booking__c).OrderNumber;

                // Get Error Message from the failed record
                Database.Error error = srList[indexRecord].getErrors().get(0);
                String errorMessage = error.getMessage();
                String errorItem = '<li> ' + guestName + ' - ' + 'Order No. ' + orderNumber + '<ul> <li>' + errorMessage + '</li> </ul> </li>';
                
                // Add Errors to the Map of Errors
                List<String> errors = hotelIdErrorListMap.get(hotelId);
                if (errors != null) {
                    errors.add(errorItem);
                } else {
                    hotelIdErrorListMap.put(hotelId, new List<String> {errorItem});
                }

            }
            // Increase index record
            indexRecord++;
        }

    }


    /**
     * Function to insert Gift Allocation of the Booking Records
     *
     * @param List<Gift_Allocation_Line_Item__c> giftAllocationBookingLineItems      - List of Gift Allocation Line Items to be inserted
     *
     * @return void
    */
    private void insertGiftAllocationLineItemList(List<Gift_Allocation_Line_Item__c> giftAllocationBookingLineItems) {

        Database.SaveResult[] srLineItemsList = Database.insert(giftAllocationBookingLineItems, false);

        Integer indexRecord = 0;

        // Iterate through each returned result
        for (Database.SaveResult sr : srLineItemsList) {
            if (sr.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                System.debug('Successfully inserted Gift Allocation Line Item. Gift Allocation Line Item ID: ' + sr.getId());
            }
            else {
                // Get Record details of the failed record
                Gift_Allocation_Line_Item__c giftAllocationLineItemErrorRecord = giftAllocationBookingLineItems[indexRecord];
                String hotelId = ordersQueriedMap.get(giftAllocationLineItemErrorRecord.Gift_Allocation__r.Booking__c).Hotel__c;
                String guestName = ordersQueriedMap.get(giftAllocationLineItemErrorRecord.Gift_Allocation__r.Booking__c).Account.Name;
                String orderNumber = ordersQueriedMap.get(giftAllocationLineItemErrorRecord.Gift_Allocation__r.Booking__c).OrderNumber;

                // Get Error Message from the failed record
                Database.Error error = srLineItemsList[indexRecord].getErrors().get(0);
                String errorMessage = error.getMessage();
                String errorItem = '<li> ' + guestName + ' - ' + 'Order No. ' + orderNumber + '<ul> <li>' + errorMessage + '</li> </ul> </li>';
                
                // Add Errors to the Map of Errors
                List<String> errors = hotelIdErrorListMap.get(hotelId);
                if (errors != null) {
                    errors.add(errorItem);
                } else {
                    hotelIdErrorListMap.put(hotelId, new List<String> {errorItem});
                }
            }
            // Increase index record
            indexRecord++;
        }
    }


    /**
     * Function to send email to the Hotels where the Budget has been exceeded
     *
     * @param BudgetWrapper budgetWrapperRecord - Wrapper record stores details
     *
     * @return void
    */
    private void sendBudgetEmails(BudgetWrapper budgetWrapperRecord) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        // Strings to hold the email addresses to which you are sending the email.
        String[] toAddresses = new String[] {budgetWrapperRecord.hotelEmailAddress}; 

        // Assign the addresses for the To and CC lists to the mail object.
        mail.setToAddresses(toAddresses);

        // Specify the address used when the recipients reply to the email. 
        mail.setReplyTo('support@salesforce.com');

        // Specify the name used as the display name.
        mail.setSenderDisplayName('Salesforce Support');

        // Specify the subject line for your email address.
        mail.setSubject('Budget Exceeded For Hotel: ' + budgetWrapperRecord.hotelName);

        // Set to True if you want to BCC yourself on the email.
        mail.setBccSender(false);
        
        // Optionally append the salesforce.com email signature to the email.
        // The email address of the user executing the Apex Code will be used.
        mail.setUseSignature(false);

        String htmlBody = generateBudgetEmailBody(budgetWrapperRecord);
        // Specify the text content of the email.
        mail.setHtmlBody(htmlBody);

        if (!Test.isRunningTest()) {
            // First, reserve email capacity for the current Apex transaction to ensure
            // that we won't exceed our daily email limits when sending email after
            // the current transaction is committed.
            Messaging.reserveSingleEmailCapacity(hotelIdBudgetWrapperMap.values().size());
            // Send the email created.
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }


    /**
     * Function to create email body
     *
     * @param BudgetWrapper budgetWrapperRecord - Wrapper record stores details
     *
     * @return Email HTML Body created dynamically
    */
    private String generateBudgetEmailBody(BudgetWrapper budgetWrapperRecord) {
        // Dyncamic HTML Body
        String htmlBody = '<h3>Dear ' + budgetWrapperRecord.hotelName + ',</h3> <h4>These are the budget issued for Hotel: ' + budgetWrapperRecord.hotelName + '</h4> <h4>Available Balance: ' + budgetWrapperRecord.balance + '</h4> <h4>Amount to cover gifts: ' + budgetWrapperRecord.newGiftsCost.setScale(2) + '</h4> <table style="width: 80%; border-collapse: collapse;" border="1">';

        //Dynamic HTML Body Summary Total Cost
        String htmlBodySummaryTotalCost = '<h3>Summary Table of Total Cost</h3> <table style="width: 80%; border-collapse: collapse;" border="1">';
        Map<String, Decimal> nameGiftWrapperPriceMap = new Map<String, Decimal>();
        Map<String, Decimal> nameGiftWrapperQuantityMap = new Map<String, Decimal>();

        // Sort list of GuestWrapper records in the Budget Wrapper
        budgetWrapperRecord.guests.sort();

        for (GuestWrapper guestWrapperRecord : budgetWrapperRecord.guests)  {
            // Dynamically populate the HTML Body of the Email - Gift Records
            Integer numberOfGiftItems = guestWrapperRecord.giftItems.size();

            // Dynamically populate the HTML Body of the email - Guest Records
            htmlBody += '<tr bgcolor="#E8E8E8"> <th>Guest Name</th> <th style="text-align: right">VIP Code</th> <th colspan="2"></th> <th style="text-align: right">Total Price Gifts</th> </tr>';
            htmlBody += '<tr bgcolor="#A9A9A9"> <td rowspan="' + (numberOfGiftItems + 2) + '" style="text-align: center">' + guestWrapperRecord.name + '</td> <td style="text-align: right">' + guestWrapperRecord.vipCode + '</td> <td colspan="2"></td> <td style="text-align: right">' + guestWrapperRecord.totalPriceGifts.setScale(2) + '</td> </tr>';

            
            htmlBody += '<tr bgcolor="#E8E8E8"> <th style="text-align: right">Gift Item</th> <th style="text-align: right">Price</th> <th style="text-align: right">Quantity</th> <th style="text-align: right">Total Cost</th> </tr>';
            for (GiftItemWrapper giftItemWrapperRecord : guestWrapperRecord.giftItems) {
                htmlBody += '<tr bgcolor="#A9A9A9"> <td style="text-align: right">' + giftItemWrapperRecord.name + '</td> <td style="text-align: right">' + giftItemWrapperRecord.price + '</td> <td style="text-align: right">' + giftItemWrapperRecord.quantity + '</td> <td style="text-align: right">' + giftItemWrapperRecord.totalCost + '</td> </tr>';
                
                if (nameGiftWrapperQuantityMap.keySet().contains(giftItemWrapperRecord.name)) {
                    nameGiftWrapperQuantityMap.put(giftItemWrapperRecord.name, nameGiftWrapperQuantityMap.get(giftItemWrapperRecord.name) + giftItemWrapperRecord.quantity);
                } else {
                    nameGiftWrapperQuantityMap.put(giftItemWrapperRecord.name, giftItemWrapperRecord.quantity);
                    nameGiftWrapperPriceMap.put(giftItemWrapperRecord.name, giftItemWrapperRecord.price);
                }
        
            }
        }

        // summary table of total cost
        htmlBodySummaryTotalCost += '<tr bgcolor="#E8E8E8"> <th style="text-align: right">Gift Item</th> <th style="text-align: right">Price</th> <th style="text-align: right">Quantity</th> <th style="text-align: right">Total Cost</th> </tr>';
        for (String nameOfGiftItem : nameGiftWrapperPriceMap.keySet()) {
            htmlBodySummaryTotalCost += '<tr bgcolor="#A9A9A9"> <td style="text-align: right">' + nameOfGiftItem + '</td> <td style="text-align: right">' + nameGiftWrapperPriceMap.get(nameOfGiftItem) + '</td> <td style="text-align: right">' + nameGiftWrapperQuantityMap.get(nameOfGiftItem) + '</td> <td style="text-align: right">' + (nameGiftWrapperPriceMap.get(nameOfGiftItem) * nameGiftWrapperQuantityMap.get(nameOfGiftItem)) + '</td> </tr>';
        }
        // Total cost summary row
        htmlBodySummaryTotalCost += '<tr bgcolor="#E8E8E8"> <td colspan="3"></td> <td style="text-align: right">' + budgetWrapperRecord.newGiftsCost.setScale(2) + '</td> </tr>';

        // Close HTML Summary Total Cost table
        htmlBodySummaryTotalCost += '</table>';

        // Close HTML table
        htmlBody += '</table>';

        htmlBody += htmlBodySummaryTotalCost;

        return htmlBody;
    }


    /**
     * Function to send email to the Hotels where there were failures on insert
     *
     * @param String        hotelId            - Hotel to receive the List of Errors
     * @param List<String>  errorsList         - List of Errors
     *
     * @return void
    */
    private void sendErrorEmails(String hotelId, List<String> errorsList) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        // Hotel to receive the email
        Budget__c budgetHotel = hotelIdBudgetMap.get(hotelId);
        String hotelName = budgetHotel.Hotel__r.Name;
        String hotelEmailAddress = budgetHotel.Hotel__r.VIP_Email_Address__c;
        
        // Strings to hold the email addresses to which you are sending the email.
        String[] toAddresses = new String[] {hotelEmailAddress}; 

        // Assign the addresses for the To and CC lists to the mail object.
        mail.setToAddresses(toAddresses);

        // Specify the address used when the recipients reply to the email. 
        mail.setReplyTo('support@salesforce.com');

        // Specify the name used as the display name.
        mail.setSenderDisplayName('Salesforce Support');

        // Specify the subject line for your email address.
        mail.setSubject('Batch Gift Allocation Errors: ' + hotelName);

        // Set to True if you want to BCC yourself on the email.
        mail.setBccSender(false);
        
        // Optionally append the salesforce.com email signature to the email.
        // The email address of the user executing the Apex Code will be used.
        mail.setUseSignature(false);

        // Dyncamic HTML Body
        String htmlBody = '<h3>Dear ' + hotelName + ',</h3> <h4>These are the errors on gift allocation for Hotel ' + hotelName + ':</h4>';
        htmlBody += '<ul>' + String.join(errorsList, '') + '</ul>';

        // Specify the text content of the email.
        mail.setHtmlBody(htmlBody);

        if (!Test.isRunningTest()) {
            Messaging.reserveSingleEmailCapacity(hotelIdErrorListMap.keySet().size());
            // Send the email you have created.
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }

    }

    
    // Wrapper Classes
    // Gift Item Wrapper Class
    private class GiftItemWrapper {
        private String name {get; set;}
        private Decimal quantity {get; set;}
        private Decimal price {get; set;}
        private Decimal totalCost {get; set;}

        private GiftItemWrapper() {
            this.name = name;
            this.quantity = quantity;
            this.price = price;
            this.totalCost = totalCost;
        }
        
    }

    // Guest Wrapper Class
    private class GuestWrapper implements Comparable {
        private String name {get; set;}
        private String vipCode {get; set;}
        private Decimal totalPriceGifts {get; set;}
        private List<GiftItemWrapper> giftItems {get; set;}

        private GuestWrapper() {
            this.name = name;
            this.vipCode = vipCode;
            this.totalPriceGifts = totalPriceGifts;
            this.giftItems = giftItems;
        }

        // Compare GuestWrapper records based on the Total Price Gifts
        public Integer compareTo(Object compareTo) {
            GuestWrapper compareToGuestWrapperRecord = (GuestWrapper) compareTo;
            if (totalPriceGifts == compareToGuestWrapperRecord.totalPriceGifts) {
                return 0;
            }
            else if (totalPriceGifts < compareToGuestWrapperRecord.totalPriceGifts) { 
                return 1;
            } else {
                return -1;
            }
        }
    }

    // Budget Wrapper Class
    private class BudgetWrapper {
        private Decimal balance {get; set;}
        private Decimal totalGiftCost {get; set;}
        private Decimal newGiftsCost {get; set;}
        private String hotelEmailAddress {get; set;}
        private String hotelName {get; set;}
        private List<GuestWrapper> guests {get; set;}

        private BudgetWrapper() {
            this.balance = balance;
            this.totalGiftCost = totalGiftCost;
            this.newGiftsCost = newGiftsCost;
            this.hotelEmailAddress = hotelEmailAddress;
            this.hotelName = hotelName;
            this.guests = guests;
        }
    }

    
}