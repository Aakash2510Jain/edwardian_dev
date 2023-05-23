import { LightningElement, api } from 'lwc';

import guestNameHeading from '@salesforce/label/c.vipGiftAllocation_guestNameHeading';
import roomNumberHeading from '@salesforce/label/c.vipGiftAllocation_roomNumberHeading';
import arrivalDateHeading from '@salesforce/label/c.vipGiftAllocation_arrivalDateHeading';
import statusHeading from '@salesforce/label/c.vipGiftAllocation_statusHeading';
import deliveryDateHeading from '@salesforce/label/c.vipGiftAllocation_deliveryDateHeading';
import totalPriceHeading from '@salesforce/label/c.vipGiftAllocation_totalPriceHeading';

export default class BookingDetails extends LightningElement {

    label = {
        guestNameHeading,
        roomNumberHeading,
        arrivalDateHeading,
        statusHeading,
        deliveryDateHeading,
        totalPriceHeading
    };

    @api recordId;
    @api guestName;
    @api roomNumber;
    @api arrivalDate;
    @api status;
    @api totalPrice;
    @api deliveryDate;
    @api departureDate

    changeDeliveryDate(event) {
        // dispatches an event containing the updated delivery date to the parent component
        this.deliveryDate = event.target.value;
        const deliveryDateEvent = new CustomEvent("changedeliverydate", {
            detail: {
                deliveryDate: this.deliveryDate
            }
        });
        this.dispatchEvent(deliveryDateEvent);
    }

}