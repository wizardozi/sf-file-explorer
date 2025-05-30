import { LightningElement, api, track } from 'lwc';

import getContactId from '@salesforce/apex/FileExplorerController.getContactId';

import getFolders from '@salesforce/apex/FileExplorerController.getFolders';

import getRecentFiles from '@salesforce/apex/FileExplorerController.getRecentFiles';

import getAllContactFiles from '@salesforce/apex/FileExplorerController.getAllContactFiles';

import createFolderFileLink from '@salesforce/apex/FileExplorerController.createFolderFileLink';

export default class FolderViewer extends LightningElement {

    @api recordId; // Unused, but required by lightningCommunity__Default target config
    @api contactId;
    @track folders = [];
    @track selectedFolderId;
    @track currentFolderId = null;
    @track currentFolderName = null;
    @track selectedFolder;
    @track files = [];
    @track folderFiles = [];
    @track recentFiles = [];
    @track selectedFile;
    @track showPreviewModal = false;
    @track modalPreviewUrl = '';
    @track downloadUrl = '';
    @track canPreview = true;
    @track fileName = '';
    @track fileExtension;

    connectedCallback() {
        this.loadFolders();
        this.loadAllFiles();
        window.addEventListener('keydown', this.handleKeyDown);
    }

    handleKeyDown = (event) => {
        if (event.key === 'Escape' && this.showPreviewModal) {
          this.closePreviewModal();
        }
    };

    loadAllFiles() {
        getContactId()
            .then(contactId => {
                console.log('Retrieved Contact Id:', contactId);
                this.contactId = contactId;
                return getAllContactFiles({ contactId });
            })
            .then(result => {
                console.log('All Contact Files:', result);
                const basePath = window.location.pathname.split('/s/')[0];
                const files = result.map(file => ({
                    ...file,
                    formattedFileSize: this.formatBytes(file.fileSize),
                    download: `${basePath}/sfc/servlet.shepherd/document/download/${file.contentDocumentId}`
                }));
                this.files = files;
                this.folderFiles = files.filter(file => this.folderId);
                this.recentFiles = [...files]
                    .sort((a, b) => new Date(b.contentModifiedDate) - new Date(a.contentModifiedDate))
                    .slice(0, 10);
            })
            .catch(error => {
                console.error('Error loading all contact files:', error);
            });
    }

    loadFolders() {
    getContactId()
        .then(contactId => {
            console.log('Retrieved Contact Id:', contactId);
            this.contactId = contactId;
            return getFolders({ contactId });
        })
        .then(result => {
            console.log('Folder data:', result);
            this.folders = result.map(folder => ({
                ...folder,
                formattedSize: this.formatBytes(folder.totalSize)
            }));
        })
        .catch(error => {
            console.error('Error fetching contact or folders:', error);
        });
    }

    formatBytes(bytes) {
      if (bytes === 0) return '0 Bytes';
      const k = 1024;
      const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
      const i = Math.floor(Math.log(bytes) / Math.log(k));
      const value = parseFloat((bytes / Math.pow(k, i)).toFixed(2));
      return `${value} ${sizes[i]}`;
    }

    handleFolderClick(event) {
        console.log('data-id:', event.currentTarget.dataset.id);
        const folderId = event.currentTarget.dataset.id;
        const folder = this.folders.find(f => f.folderId === folderId);

        this.currentFolderId = folderId;
        this.currentFolderName = folder?.folderName || 'Unknown Folder';
        this.selectedFolder = folder;
    }

    goBack(event) {
        this.currentFolderId = null;
    }

    handlePreview(event) {
        console.log('✅ SELECTED FILE ID', event.currentTarget.dataset.id);
        const fileId = event.currentTarget.dataset.id;
        this.selectedFile = this.files.find(file => file.contentDocumentId === fileId);
        const previewableExtensions = ['jpeg', 'jpg', 'png', 'pdf', 'docx'];
        if (previewableExtensions.includes((this.selectedFile.fileExtension).toLowerCase())) {
            this.canPreview = true;
            this.modalPreviewUrl = this.createPreviewUrl(this.selectedFile);
            console.log('✅ URL for preview', this.modalPreviewUrl);
        }
        else {
            this.canPreview = false;
            console.log('File cannot be preview', this.selectedFile);
        }

        this.fileName = this.selectedFile.fileName;
        this.fileExtension = this.selectedFile.fileExtension;
        this.downloadUrl = this.selectedFile.download;
        this.showPreviewModal = true;
    }

    get fileIcon() {
        const ext = this.fileExtension?.toLowerCase();
        switch (ext) {
          case 'pdf': return 'doctype:pdf';
          case 'doc':
          case 'docx': return 'doctype:word';
          case 'xls':
          case 'xlsx': return 'doctype:excel';
          case 'ppt':
          case 'pptx': return 'doctype:ppt';
          case 'png':
          case 'jpg':
          case 'jpeg': return 'doctype:image';
          case 'txt': return 'doctype:txt';
          case 'csv': return 'doctype:csv';
          case 'zip': return 'doctype:zip';
          default: return 'doctype:unknown';
        }
    }

    handleModalDownload() {
        if (!this.selectedFile || !this.selectedFile.download) {
            console.warn('⚠️ No selected file or missing download URL');
            return;
        }
    
        const link = document.createElement('a');
        link.href = this.selectedFile.download;
        link.target = '_blank';
        link.download = this.selectedFile.fileName;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    }

    handleDownload(event) {
        const fileId = event.target.dataset.id || event.target.closest('[data-id]')?.dataset.id;
        console.log('✅ ID for download', fileId);

        console.log('Clicked element:', event.target);
        
        if (!fileId) {
            console.warn('⚠️ No file ID found for download. Possibly missing contentDocumentId.');
            return;
        }
    
        const file = this.files.find(f => f.contentDocumentId === fileId);
        if (!file) {
            console.warn('⚠️ File not found in file list for ID:', fileId);
            return;
        }
        const link = document.createElement('a');
        link.href = file.download;
        link.target = '_blank';
        link.download = file.fileName;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    }

    closePreviewModal() {
        this.showPreviewModal = false;
    }

    createPreviewUrl(file) {
        console.log('FILE contentVersionId:', file.contentVersionId);
        // Get base community URL at runtime
        const basePath = window.location.pathname.split('/s/')[0];
        let url = '';
        if (file) {
            url = `${basePath}/sfc/servlet.shepherd/version/renditionDownload?rendition=ORIGINAL_Jpg&versionId=${file.contentVersionId}`;
            if (file.fileExtension === 'docx' || file.fileExtension === 'pdf') 
                url = `${basePath}/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB720BY480&versionId=${file.contentVersionId}`;
        } else if (error) {
            console.error('ERROR FETCHING FILE:', error);
            window.console.log('error ===> ' + JSON.stringify(error));
        }
        return url;
    }

    get isPdf() {
        return this.fileExtension === 'pdf';
    }

    loadRecentFiles() {
        getRecentFiles({ contactId: this.contactId })
            .then(result => {
                console.log('Recent file data:', result);
                const recent = result.map(file => ({
                    ...file,
                    formattedFileSize: this.formatBytes(file.fileSize)
                }));
                this.recentFiles = recent;

                // Merge with folderFiles and deduplicate by contentDocumentId
                const combined = [...recent, ...this.folderFiles];
                const seen = new Set();
                this.files = combined.filter(file => {
                    if (seen.has(file.contentDocumentId)) return false;
                    seen.add(file.contentDocumentId);
                    return true;
                });
            })
            .catch(error => {
                console.error('Error loading recent files:', error);
            });
    }

    handleUploadFinished(event) {
        // Get the list of uploaded files
        const uploadedFiles = event.detail.files;
        alert('No. of files uploaded : ' + uploadedFiles.length);
        console.log('Uploaded Files: ', uploadedFiles);
    
        uploadedFiles.forEach(file => {
          createFolderFileLink({
            contentDocumentId: file.documentId,
            folderId: this.currentFolderId,
            contactId: this.contactId
          })
          .then( () => {
            console.log(`File Document Id: ${file.documentId}`);
            console.log(`File ${file.name} linked to Folder successfully.`);
            this.loadAllFiles();
          })
          .catch(error => {
            console.error('Error linking file to folder: ', error);
          })
        })
    }
}