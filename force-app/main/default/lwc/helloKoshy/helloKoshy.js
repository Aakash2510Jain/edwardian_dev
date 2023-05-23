import { LightningElement } from 'lwc';

export default class HelloKoshy extends LightningElement {
    greeting = 'World';
    changeHandler(event) {
      this.greeting = event.target.value;
    }  
}