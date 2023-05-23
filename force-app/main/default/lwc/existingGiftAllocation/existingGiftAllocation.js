import { LightningElement, api } from 'lwc';

import editButton from '@salesforce/label/c.vipGiftAllocation_editButton';

export default class ExistingGiftAllocation extends LightningElement {

    label = {
        editButton
    };

    @api existingGiftAllocation;

    editGiftAllocation() {
        // dispatches an event containing the gift allocation record to the parent component
        const editEvent = new CustomEvent("editgiftallocation", {
            detail: this.existingGiftAllocation
        });
        this.dispatchEvent(editEvent);
    }

    removeGiftAllocation() {
        // dispatches an event containing the gift allocation record to the parent component
        const removeEvent = new CustomEvent("removegiftallocation", {
            detail: this.existingGiftAllocation
        });
        this.dispatchEvent(removeEvent);
    }

}