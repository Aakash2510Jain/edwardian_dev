import { LightningElement, api } from 'lwc';

import alwaysAllocatedGiftsHeading from '@salesforce/label/c.vipGiftAllocation_alwaysAllocatedGiftsHeading';
import nameHeading from '@salesforce/label/c.vipGiftAllocation_nameHeading';
import priceHeading from '@salesforce/label/c.vipGiftAllocation_priceHeading';
import quantityHeading from '@salesforce/label/c.vipGiftAllocation_quantityHeading';
import removeHeading from '@salesforce/label/c.vipGiftAllocation_removeHeading';

export default class AlwaysAllocatedGifts extends LightningElement {

    label = {
        alwaysAllocatedGiftsHeading,
        nameHeading,
        priceHeading,
        quantityHeading,
        removeHeading
    };

    @api selectedAlwaysAllocatedGifts;
    @api showAlwaysAllocatedGifts;

    changeAlwaysAllocatedQuantity(event) {
        // dispatches an event containing the updated quantity from the child component to the parent component
        const quantityEvent = new CustomEvent("changealwaysallocatedquantity", {
            detail: event.detail
        });
        this.dispatchEvent(quantityEvent);
    }

    removeAlwaysAllocatedGift(event) {
        // dispatches an event containing the removed gift from the child component to the parent component
        const removeEvent = new CustomEvent("removealwaysallocatedgift", {
            detail: event.detail
        });
        this.dispatchEvent(removeEvent);
    }

}