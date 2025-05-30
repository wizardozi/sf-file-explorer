# Salesforce File Explorer (Experience Cloud)

This Lightning Web Component (LWC) + Apex project provides a custom file management system for Experience Cloud users. It mimics a standard folder/file system interface (like Dropbox or Google Drive), allowing Community Users to upload, preview, and manage files linked to their Contact records.

## Features

- **Folder Tree** — Auto-generates folders (A, B, C...) per Contact based on User profile.
- **User-Specific File Views** — Each user sees the same folder structure but only their own files.
- **File Upload** — Upload files into specific folders with support for multiple file types.
- **File-to-Folder Linking** — Files are linked to folders using a custom junction object (`FolderFileLink__c`).
- **Preview Modal** — Inline preview of uploaded files with options to download or close.
- **Test Coverage** — Apex classes are test-covered to support packaging and deployment.

## Tech Stack

- **Frontend:** Lightning Web Components (LWC)
- **Backend:** Apex (Triggers, Classes, Future Methods)
- **Data Model:** `ContentDocument`, `ContentDocumentLink`, `ContentVersion`, `Folder__c`, `FolderFileLink__c`, `Contact`, `User`
- **Experience Cloud:** Designed for logged-in community users

---

## Setup Instructions

### 1. Deploy Metadata

Ensure the following components are deployed:

- LWC Components:
  - `fileExplorer`
- Apex Classes:
  - `FileExplorerController`
  - `FolderInitializer`
  - `ContentDocumentLinkHandler`
- Triggers:
  - `UserTrigger` (for auto-folder creation)
  - `UpdateCDLShareType` (for linking logic)

### 2. Custom Objects

- `Folder__c`: Stores the folder structure
- `FolderFileLink__c`: Custom junction object linking folders to files

Ensure both objects and their fields are deployed or created.

### 3. File Upload Permissions

- Use the **Community User Plus Login** license or equivalent
- Ensure users have access to:
  - Apex classes via profile or permission sets
  - Static Resources (if using PDF.js, etc.)

### 4. Optional: PDF Previewer

To support multipage PDF preview:
- Upload `pdf.js` as a Static Resource
- Integrate viewer inside your modal component

---

## Packaging and Deployment

This project is designed to be packaged and installed in other orgs.

Before creating a package:
- Run all test classes to ensure ≥75% coverage
- Confirm trigger and handler logic works in the target environment
- Add metadata dependencies as needed in `package.xml`

---

## Test Classes

- `FileExplorerControllerTest`
- `ContentDocumentLinkHandlerTest`
- `FolderInitializerTest`

All test classes use mock data.

---

## Known Limitations

- File size limits may affect upload success
- PDF preview is static and may not support advanced interactivity
- No drag-and-drop (yet)

---

## License

MIT or custom license depending on client use.

---

## Contact

Project by Alexandre Denommee  
For questions or consulting, contact via [GitHub](https://github.com/wizardozi) or internal project channels.
