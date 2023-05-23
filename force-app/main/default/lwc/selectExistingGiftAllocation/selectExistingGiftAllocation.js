import { LightningElement, api } from 'lwc';

import selectGiftAllocationHeading from '@salesforce/label/c.vipGiftAllocation_selectGiftAllocationHeading';
import nameHeading from '@salesforce/label/c.vipGiftAllocation_nameHeading';
import deliveryStatusHeading from '@salesforce/label/c.vipGiftAllocation_deliveryStatusHeading';
import totalItemsHeading from '@salesforce/label/c.vipGiftAllocation_totalItemsHeading';
import deliveryDateHeading from '@salesforce/label/c.vipGiftAllocation_deliveryDateHeading';
import totalPriceHeading from '@salesforce/label/c.vipGiftAllocation_totalPriceHeading';

export default class SelectExistingGiftAllocation extends LightningElement {

    label = {
        selectGiftAllocationHeading,
        nameHeading,
        deliveryStatusHeading,
        totalItemsHeading,
        deliveryDateHeading,
        totalPriceHeading
    };

    @api existingGiftAllocations;

    editGiftAllocation(event) {
        // dispatches an event containing selected gift allocation record from the child component to the parent component
        const editEvent = new CustomEvent("editgiftallocation", {
            detail: event.detail
        });
        this.dispatchEvent(editEvent);
    }

    removeGiftAllocation(event) {
        // dispatches an event containing the gift allocation record to the parent component
        const removeEvent = new CustomEvent("removegiftallocation", {
            detail: event.detail
        });
        this.dispatchEvent(removeEvent);
    }
}