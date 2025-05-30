global without sharing class FileExplorerController {
    
    global class FolderInfo {
        @AuraEnabled public String folderName;
        @AuraEnabled public String folderId;
        @AuraEnabled public Integer fileCount;
        @AuraEnabled public Integer totalSize;
        @AuraEnabled public String contactName;
        @AuraEnabled public List<FileInfo> files;
    }
    global class FileInfo {
        @AuraEnabled public String fileName;
        @AuraEnabled public String fileExtension;
        @AuraEnabled public Integer fileSize;
        @AuraEnabled public String contentDocumentId;
        @AuraEnabled public String contentVersionId;
        @AuraEnabled public String folderId;
        @AuraEnabled public DateTime contentModifiedDate;
    }
    
    @AuraEnabled(cacheable=true)
    global static String getContactId() {
        // Get the current user's Id
        Id userId = UserInfo.getUserId();
        System.debug('Current user Id: '+userId);
        // Query the User record to retrieve the related Contact
        User currentUser = [
            SELECT ContactId FROM User WHERE Id = :userId LIMIT 1
        ];
        System.debug('Related Contact Id: '+currentUser.ContactId);
        return currentUser.ContactId;
    }

    @AuraEnabled(cacheable=true)
    global static List<FolderInfo> getFolders(Id contactId) {
        System.debug('Incoming Contact Id: ' + contactId);
        
        List<Folder__c> folders = [SELECT Id, Name, Contact__c FROM Folder__C WHERE Contact__c = :contactId];

        List<FolderInfo> folderInfos = new List<FolderInfo>();
        if (folders == null || folders.isEmpty()) {
            System.debug('No folders associated with contact');
            FolderInfo info = new FolderInfo();
            info.folderName = 'No Folder';
            info.contactName = 'No Contact';
            info.folderId = 'No Id';
            folderInfos.add(info);
            return folderInfos; 
        }

        Contact contact = [SELECT Id, FirstName, LastName FROM Contact WHERE Id = :contactId LIMIT 1];
        
        Map<Id, List<FileInfo>> folderFileMap = mapFolderToFiles(folders);
        for (Folder__c folder : folders) {
            FolderInfo info = new FolderInfo();
            info.folderName = folder.Name;
            info.folderId = folder.Id;
            List<FileInfo> files = folderFileMap.get(folder.Id);
            if (files == null) {
                files = new List<FileInfo>();
            }
            info.fileCount = files.size();
            Integer totalSize = 0;
            for (FileInfo file : files) {
                totalSize += file.fileSize;
            }            
            info.totalSize = totalSize;
            info.files = files;
            info.totalSize = totalSize;
            info.contactName = contact.FirstName+' '+contact.LastName;
            info.files = folderFileMap.get(folder.Id);
            folderInfos.add(info);
        }
        system.debug('Folders from LWC: '+folderInfos);
        return folderInfos;
    }

    private static Map<Id, List<FileInfo>> mapFolderToFiles(List<Folder__c> folders) {

        Set<Id> folderIds = new Set<Id>();
        for (Folder__c folder : folders) {
            folderIds.add(folder.Id);
        }

        Map<Id, List<String>> folderToDocIds = new Map<Id, List<String>>();
        for (FolderFileLink__c link : [
            SELECT ContentDocumentId__c, Folder__C
            FROM FolderFileLink__c
            WHERE Folder__c = :folderIds
        ]) {
            if (!folderToDocIds.containsKey(link.Folder__C)) {
                folderToDocIds.put(link.Folder__C, new List<String>());
            }
            folderToDocIds.get(link.Folder__C).add(link.ContentDocumentId__c);
        }

        Set<String> allDocIds = new Set<String>();
        for (List<String> docList : folderToDocIds.values()) {
            allDocIds.addAll(docList);
        }
        Map<Id, FileInfo> docIdToFile = new Map<Id, FileInfo>();
        List<ContentVersion> contentVersions = [
            SELECT Id, Title, FileExtension, ContentSize, ContentModifiedDate, ContentDocumentId
            FROM ContentVersion
            WHERE ContentDocumentId IN :allDocIds
            ORDER BY VersionNumber DESC
        ];
        for (ContentVersion cv : contentVersions) {
            // Only store the first (most recent) version for each document
            if (!docIdToFile.containsKey(cv.ContentDocumentId)) {
                FileInfo file = new FileInfo();
                file.fileName = cv.Title;
                file.fileExtension = cv.FileExtension;
                file.fileSize = cv.ContentSize;
                file.contentModifiedDate = cv.ContentModifiedDate;
                file.contentDocumentId = cv.ContentDocumentId;
                file.contentVersionId = cv.Id;
                docIdToFile.put(cv.ContentDocumentId, file);
            }
        }

        Map<Id, List<FileInfo>> folderFileMap = new Map<Id, List<FileInfo>>();
        for (Id folderId : folderToDocIds.keySet()) {
            List<FileInfo> fileList = new List<FileInfo>();
            for (Id docId : folderToDocIds.get(folderId)) {
                FileInfo file = docIdToFile.get(docId);
                if (file != null) {
                    fileList.add(file);
                }
            }
            folderFileMap.put(folderId, fileList);
        }
        return folderFileMap;
    }
    
    // RECENT FILES METHOD
    @AuraEnabled(cacheable=true)
    public static List<FileInfo> getRecentFiles(Id contactId) {
        if (String.isBlank(contactId)) {
            System.debug('❗ No contactId provided');
            Id userId = UserInfo.getUserId();
            User currentUser = [SELECT ContactId FROM User WHERE Id = :userId LIMIT 1];
            contactId = currentUser.ContactId;
        }
        
        List<FolderFileLink__c> folderLinks = [
            SELECT ContentDocumentId__c
            FROM FolderFileLink__c
            WHERE Contact__c = :contactId
        ];

        Set<Id> docIds = new Set<Id>();
        for (FolderFileLink__c link : folderLinks) {
            docIds.add( (Id) link.ContentDocumentId__c);
        }
        System.debug('📦 Document Ids used in query: ' + docIds);
        List<ContentVersion> contentVersionList = [
            SELECT Id, Title, FileExtension, ContentDocumentId, ContentSize, ContentModifiedDate
            FROM ContentVersion
            WHERE ContentDocumentId IN :docIds
            ORDER BY ContentModifiedDate
            LIMIT 10
        ];
        List<FileInfo> recentFiles = new List<FileInfo>();
        for (ContentVersion cv : contentVersionList) {
            FileInfo file = new FileInfo();
            file.fileName = cv.Title;
            file.fileExtension = cv.FileExtension;
            file.fileSize = cv.ContentSize;
            file.contentDocumentId = cv.ContentDocumentId;
            file.contentVersionId = cv.Id;
            file.contentModifiedDate = cv.ContentModifiedDate;
            recentFiles.add(file);
        }
        return recentFiles;
    }

    @AuraEnabled    
    public static void createFolderFileLink(String contentDocumentId, String folderId, String contactId) {
        ContentVersion fileCV = [
            SELECT Id, Title, FileExtension, ContentDocumentId, ContentSize, ContentModifiedDate
            FROM ContentVersion
            WHERE ContentDocumentId = :contentDocumentId
            LIMIT 1
        ];
        if (contentDocumentId == '' || contentDocumentId == null ) {
            system.debug('❗️ Content Document ID Missing');
            return;
        } 
        else if (folderId == '' || folderId == null) {
            system.debug('❗️ Folder ID Missing');
            return;
        } else {

            system.debug('✅ Content Document ID From LWC: '+contentDocumentId);
            system.debug('✅ Folder ID From LWC: '+folderId);

            FolderFileLink__c link = new FolderFileLink__c(
                ContentDocumentId__c = contentDocumentId, 
                Folder__c = folderId,
                Contact__c = contactId,
                FileLabel__c = fileCV.Title != null ? fileCV.Title : 'experience_upload',
                UploadDate__c = Date.today()
            );

            try { 
                insert Link;
                system.debug('✅ Folder File Link successfully created: ' + link);
            } catch (Exception e) {
                System.debug('The following exception has occurred: ' + e.getMessage());
            }
        }            
    }

    @AuraEnabled(cacheable=true)
    public static List<FileInfo> getAllContactFiles(Id contactId) {
        List<FolderFileLink__c> allFolderFileLinks = [
            SELECT Id, Folder__c, ContentDocumentId__c 
            FROM FolderFileLink__c
            WHERE Contact__c = :contactId
        ];
        Map<Id, FolderFileLink__c> docIdToLinkMap = new Map<Id, FolderFileLink__c>();
        for (FolderFileLink__c link : allFolderFileLinks) {
            docIdToLinkMap.put(link.ContentDocumentId__c, link);
        }
        Map<Id, ContentVersion> docIdToVersion = new Map<Id, ContentVersion>();
        for (ContentVersion cv : [
            SELECT Id, Title, FileExtension, ContentDocumentId, ContentSize, ContentModifiedDate
            FROM ContentVersion
            WHERE ContentDocumentId IN :docIdToLinkMap.keySet()
            ORDER BY VersionNumber DESC
        ]) {
            if (!docIdToVersion.containsKey(cv.ContentDocumentId)) {
                docIdToVersion.put(cv.ContentDocumentId, cv);
            }
        }
        List<FileInfo> files = new List<FileInfo>();
        for (Id docId : docIdToLinkMap.keySet()) {
            ContentVersion cv = docIdToVersion.get(docId);
            if (cv == null) continue;

            FileInfo file = new FileInfo();
            file.fileName = cv.Title;
            file.fileExtension = cv.FileExtension;
            file.fileSize = cv.ContentSize;
            file.contentDocumentId = docId;
            file.contentVersionId = cv.Id;
            file.folderId = docIdToLinkMap.get(docId).Folder__C;
            file.contentModifiedDate = cv.ContentModifiedDate;
            files.add(file);
        }
        return files;
    }
}