import { LightningElement, api } from 'lwc';

import giftsHeading from '@salesforce/label/c.vipGiftAllocation_giftsHeading';

export default class AvailableGifts extends LightningElement {

    label = {
        giftsHeading
    };

    @api giftsByGrade;

    addGift(event) {
        // dispatches an event containing the selected gift from the child component to the parent component
        const addEvent = new CustomEvent("selectedgift", {
            detail: event.detail
        });
        this.dispatchEvent(addEvent);
    }
}