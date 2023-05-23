import { LightningElement, api } from 'lwc';

import addButton from '@salesforce/label/c.vipGiftAllocation_addButton';

export default class GiftDetail extends LightningElement {

    label = {
        addButton
    };

    @api gift;
    @api quantity = "1";
    @api alwaysAllocate = false;

    changeQuantity(event) {
        // updates the quantity value
        this.quantity = event.target.value;
    }

    changeAlwaysAllocate(event) {
        // updates the always allocate boolean value
        this.alwaysAllocate = event.target.checked;
    }

    addGift() {
        // dispatches an event containing the selected gift to the parent component
        const addEvent = new CustomEvent("selectedgift", {
            detail: {
                gift: this.gift,
                quantity: this.quantity,
                alwaysAllocate: this.alwaysAllocate,
                status: 'Pending'
            }
        });
        this.dispatchEvent(addEvent);
    }
}