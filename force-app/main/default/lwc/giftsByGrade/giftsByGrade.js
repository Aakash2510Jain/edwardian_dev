import { LightningElement, api } from 'lwc';

import nameHeading from '@salesforce/label/c.vipGiftAllocation_nameHeading';
import priceHeading from '@salesforce/label/c.vipGiftAllocation_priceHeading';
import quantityHeading from '@salesforce/label/c.vipGiftAllocation_quantityHeading';
import alwaysAllocateHeading from '@salesforce/label/c.vipGiftAllocation_alwaysAllocateHeading';
import addHeading from '@salesforce/label/c.vipGiftAllocation_addHeading';

export default class GiftsByGrade extends LightningElement {

    label = {
        nameHeading,
        priceHeading,
        quantityHeading,
        alwaysAllocateHeading,
        addHeading
    };

    @api gradeName;
    @api gifts;

    addGift(event) {
        // dispatches an event containing the selected gift from the child component to the parent component
        const addEvent = new CustomEvent("selectedgift", {
            detail: event.detail
        });
        this.dispatchEvent(addEvent);
    }
}