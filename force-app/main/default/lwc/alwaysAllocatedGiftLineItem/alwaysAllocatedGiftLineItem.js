import { LightningElement, api } from 'lwc';

import removeButton from '@salesforce/label/c.vipGiftAllocation_removeButton';

export default class AlwaysAllocatedGiftLineItem extends LightningElement {

    label = {
        removeButton
    };

    @api selectedAlwaysAllocatedGift;
    @api quantity;

    changeQuantity(event) {
        // dispatches an event containing the updated quantity to the parent component
        this.quantity = event.target.value;
        const quantityEvent = new CustomEvent("changealwaysallocatedquantity", {
            detail: {
                gift: this.selectedAlwaysAllocatedGift.gift,
                quantity: this.quantity
            }
        });
        this.dispatchEvent(quantityEvent);
    }

    removeAlwaysAllocatedGift() {
        // dispatches an event containing the removed always allocated gift to the parent component
        const removeEvent = new CustomEvent("removealwaysallocatedgift", {
            detail: this.selectedAlwaysAllocatedGift
        });
        this.dispatchEvent(removeEvent);
    }
}