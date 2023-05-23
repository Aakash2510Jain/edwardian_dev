import { LightningElement, api } from 'lwc';

import removeButton from '@salesforce/label/c.vipGiftAllocation_removeButton';

export default class VipGiftAllocationLineItem extends LightningElement {

    label = {
        removeButton
    };

    @api selectedGift;
    @api quantity;
    @api status;

    get options() {
        return [
            { label: 'Pending', value: 'Pending' },
            { label: 'Delivered', value: 'Delivered' },
            { label: 'DND', value: 'DND' },
        ];
    }

    changeStatus(event) {
        // dispatches an event containing the updated status to the parent component
        this.status = event.target.value;
        const statusEvent = new CustomEvent("changestatus", {
            detail: {
                gift: this.selectedGift.gift,
                status: this.status
            }
        });
        this.dispatchEvent(statusEvent);
    }

    changeQuantity(event) {
        // dispatches an event containing the updated quantity to the parent component
        this.quantity = event.target.value;
        const quantityEvent = new CustomEvent("changequantity", {
            detail: {
                gift: this.selectedGift.gift,
                quantity: this.quantity
            }
        });
        this.dispatchEvent(quantityEvent);
    }

    removeGift() {
        // dispatches an event containing the removed gift to the parent component
        const removeEvent = new CustomEvent("removegift", {
            detail: this.selectedGift
        });
        this.dispatchEvent(removeEvent);
    }
}