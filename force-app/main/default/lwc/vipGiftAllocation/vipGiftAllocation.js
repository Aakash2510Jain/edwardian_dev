import { LightningElement, api, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import getBookingDetails from "@salesforce/apex/VipGiftAllocationController.getBookingDetails";
import getGiftsByGrade from "@salesforce/apex/VipGiftAllocationController.getGiftsByGrade";
import getExistingAlwaysAllocateGifts from "@salesforce/apex/VipGiftAllocationController.getExistingAlwaysAllocateGifts";
import getExistingGiftAllocations from "@salesforce/apex/VipGiftAllocationController.getExistingGiftAllocations";
import saveGiftAllocation from "@salesforce/apex/VipGiftAllocationController.saveGiftAllocation";
import deleteGiftAllocations from "@salesforce/apex/VipGiftAllocationController.deleteGiftAllocations";

import allocateVipGiftsHeading from "@salesforce/label/c.vipGiftAllocation_allocateVipGiftsHeading";
import cancelButton from "@salesforce/label/c.vipGiftAllocation_cancelButton";
import newButton from "@salesforce/label/c.vipGiftAllocation_newButton";
import saveButton from "@salesforce/label/c.vipGiftAllocation_saveButton";

export default class VipGiftAllocation extends LightningElement {
    label = {
        allocateVipGiftsHeading,
        cancelButton,
        newButton,
        saveButton,
    };

    @api recordId;
    @api fullView;
    @api guestName;
    @api roomNumber;
    @api arrivalDate;
    @api deliveryDate;
    @api departureDate;
    @api deliveryStatus;
    @api giftsByGrade;
    @api hotelId;
    @api guestId;
    @api totalPrice = 0;
    @api showSelectedGifts = false;
    @api selectedGifts = [];
    @api showAlwaysAllocatedGifts = false;
    @api selectedAlwaysAllocatedGifts = [];
    @api alwaysAllocatedGiftsToDelete = [];
    @api selectedGiftsToDelete = [];
    @api selectedGiftAllocationsToDelete = [];
    @api giftAllocationSelected;
    @api existingGiftAllocations = [];
    @api selectedGiftAllocation;
    @api selectedGiftAllocationId;
    isLoading = false;
    errorDetected = false;
    errorMessageDisplayed = "";

    validStatuses = ["RES", "CIN"];

    @wire(getBookingDetails, { recordId: "$recordId" })
    wiredBooking({ error, data }) {
        if (data) {
            // setting booking variables retrieved via Apex
            this.guestName = data.Guest_First_Name__c + " " + data.Guest_Last_Name__c;
            this.roomNumber = data.Room_Number__c;
            this.arrivalDate = data.Arrival_Date__c;
            this.deliveryDate = data.Arrival_Date__c;
            this.departureDate = data.Departure_Date__c;

            // if the guest has departed then we won't have a hotel reference so check first
            // and leave before we try to assign
            const hasDeparted = this.departureDate && this.departureDate < new Date();
            if (
                !data.Reservation_Status__c ||
                (data.Reservation_Status__c && !this.validStatuses.includes(data.Reservation_Status__c)) ||
                hasDeparted
            ) {
                this.errorDetected = true;
                this.errorMessageDisplayed = "This Booking is not applicable for Gift Items.";
            }

            this.hotelId = data.Hotel__r ? data.Hotel__r.Hotel_ID__c : null;
            this.guestId = data.AccountId;

            // only once we have a valid complete load here can we do retrievals of other data
            this.loadAlwaysAllocated();
        }
        if (error) {
            this.errorDetected = true;
            this.errorMessageDisplayed = reduceErrors(error);
        }
    }

    @wire(getGiftsByGrade, { hotelId: "$hotelId" })
    wiredGiftsByGrade({ error, data }) {
        if (data) {
            // setting a map of gifts by their grades retrieved via Apex
            this.giftsByGrade = [];
            for (const key in data) {
                this.giftsByGrade.push({ value: data[key], key: key });
            }
        }
    }

    connectedCallback() {
        this.loadGiftAllocations();
    }

    loadGiftAllocations() {
        this.isLoading = true;
        getExistingGiftAllocations({ recordId: this.recordId })
            .then((result) => {
                if (result.length > 0) {
                    this.existingGiftAllocations = result;
                    this.giftAllocationSelected = false;
                } else {
                    this.giftAllocationSelected = true;
                }
            })
            .catch((error) => {
                this.showToast("Warning", "Error trying to retrieve gift allocations for this booking", "warning");
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    loadAlwaysAllocated() {
        // call method to get all the existing always allocated gifts
        getExistingAlwaysAllocateGifts({ guestId: this.guestId })
            .then((result) => {
                // clear out list first so we don't get duplicates after this is called again post-save
                this.selectedAlwaysAllocatedGifts = [];

                // retrieves always allocated items related to the guest and creates list of objects
                result.forEach((element) => {
                    this.selectedAlwaysAllocatedGifts = [
                        ...this.selectedAlwaysAllocatedGifts,
                        {
                            value: {
                                gift: {
                                    Id: element.Gift_Name__c,
                                    Name: element.Gift_Name__r.Name,
                                    Price__c: element.Gift_Name__r.Price__c,
                                },
                                quantity: element.Quantity__c,
                                existingId: element.Id,
                            },
                        },
                    ];
                });

                // show always allocated gifts section - existing lag until the list is populated
                if (this.selectedAlwaysAllocatedGifts.length) {
                    this.showAlwaysAllocatedGifts = true;
                }
            })
            .catch((error) => {
                this.showToast("Warning", "Error trying to retrieve always allocated gifts", "warning");
            })
            .finally(() => {});
    }

    editGiftAllocation(event) {
        // retrieves the selected gift allocation to be edited via the event param from child component and sets relevant variables
        this.selectedGiftAllocation = event.detail;
        this.deliveryStatus = this.selectedGiftAllocation.Gift_Delivery_Status__c;
        this.selectedGiftAllocationId = this.selectedGiftAllocation.Id;

        if (
            this.selectedGiftAllocation.Gift_Allocation_Line_Items__r !== undefined &&
            this.selectedGiftAllocation.Gift_Allocation_Line_Items__r.length > 0
        ) {
            // creating objects for child line items
            this.selectedGiftAllocation.Gift_Allocation_Line_Items__r.forEach((element) => {
                this.selectedGifts = [
                    ...this.selectedGifts,
                    {
                        value: {
                            gift: {
                                Id: element.Gift_Name__c,
                                Name: element.Gift_Name__r.Name,
                                Price__c: element.Gift_Name__r.Price__c,
                            },
                            quantity: element.Quantity__c,
                            status: element.Status__c,
                            existingId: element.Id,
                        },
                    },
                ];
            });
        }

        // show selected gifts section
        if (this.selectedGifts.length) {
            this.showSelectedGifts = true;
        }

        this.giftAllocationSelected = true;

        // updates total price with new values
        this.updateTotalPrice();
    }

    createNew() {
        // progresses to screen to allocate gifts
        this.giftAllocationSelected = true;
        this.selectedGifts = [];
    }

    changeDeliveryDate(event) {
        // retrieves updated delivery date as event param from child component
        this.deliveryDate = event.detail.deliveryDate;
    }

    addGift(event) {
        // retrieves selected gifts as event param from child component and adds to selected gifts if not included already
        let giftMatchFound = false;
        this.selectedGifts.forEach((element) => {
            if (element.value.gift.Id === event.detail.gift.Id) {
                giftMatchFound = true;
            }
        });
        if (!giftMatchFound) {
            this.selectedGifts = [...this.selectedGifts, { value: event.detail }];
        }

        // retrieves selected gifts as event param from child component and adds to always allocated gifts if not included already
        if (event.detail.alwaysAllocate === true) {
            let alwaysAllocateMatchFound = false;
            this.selectedAlwaysAllocatedGifts.forEach((element) => {
                if (element.value.gift.Id === event.detail.gift.Id) {
                    alwaysAllocateMatchFound = true;
                }
            });
            if (!alwaysAllocateMatchFound) {
                this.selectedAlwaysAllocatedGifts = [...this.selectedAlwaysAllocatedGifts, { value: event.detail }];
            }
        }

        // show selected gifts section
        if (this.selectedGifts.length > 0) {
            this.showSelectedGifts = true;
        }
        // show always allocated gifts section
        if (this.selectedAlwaysAllocatedGifts.length > 0) {
            this.showAlwaysAllocatedGifts = true;
        }
        // updates total price with new values
        this.updateTotalPrice();
    }

    removeGift(event) {
        // retrieves deleted gifts as event param from child component and creates new list of selected gifts exluding the deleted one
        let remainingGifts = [];
        for (let i = 0; i < this.selectedGifts.length; i++) {
            if (this.selectedGifts[i].value.gift.Id !== event.detail.gift.Id) {
                remainingGifts.push(this.selectedGifts[i]);
            } else {
                // if gift exists as a record add to a list of Ids to be deleted
                if (this.selectedGifts[i].value.existingId != undefined) {
                    this.selectedGiftsToDelete.push(this.selectedGifts[i].value.existingId);
                }
            }
        }
        this.selectedGifts = remainingGifts;
        // hide selected gifts section if no gifts are selected
        if (this.selectedGifts.length === 0) {
            this.showSelectedGifts = false;
        }
        // updates total price with new values
        this.updateTotalPrice();
    }

    // remove gift allocation
    removeGiftAllocation(event) {
        let remainingGiftAllocations = [];

        for (let i = 0; i < this.existingGiftAllocations.length; i++) {
            if (this.existingGiftAllocations[i].Id !== event.detail.Id) {
                remainingGiftAllocations.push(this.existingGiftAllocations[i]);
            } else {
                // if gift allocation exists as a record add to a list of Ids to be deleted
                if (this.existingGiftAllocations[i].Id != undefined) {
                    this.selectedGiftAllocationsToDelete.push(this.existingGiftAllocations[i].Id);
                }
            }
        }
        this.existingGiftAllocations = remainingGiftAllocations;
        if (this.existingGiftAllocations.length === 0) {
            this.giftAllocationSelected = false;
        }

        // call Apex function to delete the gift allocation records selected
        deleteGiftAllocations({ selectedGiftAllocationsToDelete: this.selectedGiftAllocationsToDelete })
            .then((result) => {
                //success message
                this.showToast("Success", "Gift Allocation deleted.", "success");
                this.selectedGiftAllocationsToDelete = [];
            })
            .catch((error) => {
                // error message
                this.showToast("Error", "Failed to delete Gift Allocation.", "error");
            });
    }

    changeStatus(event) {
        // retrieves gifts with a change in status as an event param from the child component and updates the list of selected gifts
        this.selectedGifts.forEach((element) => {
            if (element.value.gift.Id === event.detail.gift.Id) {
                element.value.status = event.detail.status;
            }
        });
    }

    changeQuantity(event) {
        // retreives gifts with a change in quantity as an event param from the child component and updates the list of selected gifts
        this.selectedGifts.forEach((element) => {
            if (element.value.gift.Id === event.detail.gift.Id) {
                element.value.quantity = event.detail.quantity;
            }
        });
        // updates total price to account for quantity change
        this.updateTotalPrice();
    }

    changeAlwaysAllocatedQuantity(event) {
        // retrieves always allocated gifts with a change in quantity as an event param from the child component and updates the list of always allocated gifts
        this.selectedAlwaysAllocatedGifts.forEach((element) => {
            if (element.value.gift.Id === event.detail.gift.Id) {
                element.value.quantity = event.detail.quantity;
            }
        });
    }

    updateTotalPrice() {
        this.totalPrice = 0;
        // calculates total price of all selected gifts and sets to 2 decimal places
        this.selectedGifts.forEach((element) => {
            this.totalPrice = this.totalPrice + element.value.gift.Price__c * element.value.quantity;
        });
        this.totalPrice = parseFloat(this.totalPrice).toFixed(2);
    }

    removeAlwaysAllocatedGift(event) {
        // retrieves deleted always allocated gifts as event param from child component and creates new list of always allocated gifts exluding the deleted one
        let remainingGifts = [];
        for (let i = 0; i < this.selectedAlwaysAllocatedGifts.length; i++) {
            if (this.selectedAlwaysAllocatedGifts[i].value.gift.Id !== event.detail.gift.Id) {
                remainingGifts.push(this.selectedAlwaysAllocatedGifts[i]);
            } else {
                // if always allocated gift exists as a record add to a list of Ids to be deleted
                if (this.selectedAlwaysAllocatedGifts[i].value.existingId != undefined) {
                    this.alwaysAllocatedGiftsToDelete.push(this.selectedAlwaysAllocatedGifts[i].value.existingId);
                }
            }
        }
        this.selectedAlwaysAllocatedGifts = remainingGifts;
        // hide always allocated gifts section if no gifts are selected
        if (this.selectedAlwaysAllocatedGifts.length === 0) {
            this.showAlwaysAllocatedGifts = false;
        }
    }

    closeQuickAction() {
        // dispatches an event to close the quick action modal window
        if (this.fullView || this.giftAllocationSelected) {
            this.giftAllocationSelected = false;
            this.selectedGifts = [];
            this.selectedGiftsToDelete = [];
            this.alwaysAllocatedGiftsToDelete = [];
        } else {
            const close = new CustomEvent("close");
            this.dispatchEvent(close);
        }
    }

    @api
    save() {
        if (!this.selectedGifts.length) {
            this.showToast("Warning", "No gift allocated", "warning");
            return;
        }

        // conditions for delivery date deliveryDate is greater and equals to arrival date and less than departure date
        if (this.deliveryDate > this.departureDate || this.deliveryDate < this.arrivalDate) {
            this.showToast(
                "Warning",
                "Delivery Date can not be before the arrival date or after the departure date",
                "warning"
            );
            return;
        }

        // merge the two we want to check, and map to a simple array then reduce to find if any of the quantities are not
        let qtyErrors = [...this.selectedGifts, ...this.selectedAlwaysAllocatedGifts]
            .map((x) => x.value.quantity)
            .reduce((a, c) => {
                if (c <= 0) {
                    a.push(c);
                }

                return a;
            }, []);

        if (qtyErrors.length) {
            this.showToast("Warning", "Quantity field must always be at least 1", "warning");
            return;
        }

        // passes data as json string to Apex controller to handle DML operations
        this.isLoading = true;
        const giftAllocationJson = {
            recordId: this.recordId,
            totalPrice: this.totalPrice,
            deliveryDate: this.deliveryDate,
            selectedGifts: this.selectedGifts,
            selectedAlwaysAllocatedGifts: this.selectedAlwaysAllocatedGifts,
            selectedGiftAllocationId: this.selectedGiftAllocationId,
        };

        saveGiftAllocation({
            giftAllocationJson: JSON.stringify(giftAllocationJson),
            alwaysAllocatedGiftsToDelete: this.alwaysAllocatedGiftsToDelete,
            selectedGiftsToDelete: this.selectedGiftsToDelete,
        })
            .then((result) => {
                if (result === true) {
                    // budget warning message
                    this.showToast(
                        "Warning",
                        "Gift Allocation created, however the Budget has been exceeded.",
                        "warning"
                    );
                } else {
                    // success message
                    this.showToast("Success", "Gift Allocation created/updated.", "success");
                }
                this.closeQuickAction();

                // refresh list
                this.loadGiftAllocations();
                this.loadAlwaysAllocated();
            })
            .catch((error) => {
                // error message
                this.showToast("Error", "Failed to create Gift Allocation.", "error");
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    showToast(title, message, variant) {
        // dispatches event to display a toast message
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });

        this.dispatchEvent(event);
    }
}