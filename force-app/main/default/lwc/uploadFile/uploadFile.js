import { LightningElement } from 'lwc';


export default class UploadFile extends LightningElement {
    handleUploadFinished(event) {
        // Get the list of uploaded files
        const uploadedFiles = event.detail.files;
        alert('No. of files uploaded : ' + uploadedFiles.length);
    }
}