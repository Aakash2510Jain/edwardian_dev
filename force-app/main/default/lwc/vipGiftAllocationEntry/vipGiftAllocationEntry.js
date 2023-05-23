import { LightningElement, api } from 'lwc';

import selectedGiftsHeading from '@salesforce/label/c.vipGiftAllocation_selectedGiftsHeading';
import nameHeading from '@salesforce/label/c.vipGiftAllocation_nameHeading';
import priceHeading from '@salesforce/label/c.vipGiftAllocation_priceHeading';
import quantityHeading from '@salesforce/label/c.vipGiftAllocation_quantityHeading';
import statusHeading from '@salesforce/label/c.vipGiftAllocation_statusHeading';
import removeHeading from '@salesforce/label/c.vipGiftAllocation_removeHeading';

export default class VipGiftAllocationEntry extends LightningElement {

    label = {
        selectedGiftsHeading,
        nameHeading,
        priceHeading,
        quantityHeading,
        statusHeading,
        removeHeading
    };

    @api selectedGifts;
    @api showSelectedGifts;

    changeStatus(event) {
        // dispatches an event containing the updated status from the child component to the parent component
        const statusEvent = new CustomEvent("changestatus", {
            detail: event.detail
        });
        this.dispatchEvent(statusEvent);
    }

    changeQuantity(event) {
        // dispatches an event containing the updated quantity from the child component to the parent component
        const quantityEvent = new CustomEvent("changequantity", {
            detail: event.detail
        });
        this.dispatchEvent(quantityEvent);
    }

    removeGift(event) {
        // dispatches an event containing the deleted gift from the child component to the parent component
        const removeEvent = new CustomEvent("removegift", {
            detail: event.detail
        });
        this.dispatchEvent(removeEvent);
    }
}