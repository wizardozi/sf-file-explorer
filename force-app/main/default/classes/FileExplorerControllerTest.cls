@isTest
private class FileExplorerControllerTest {
    
    @isTest 
    static void testGetContactId() {
        ContentDocumentLinkHandler.disableUpdate = true;

        Account a = new Account(Name = 'Test Account', Type = 'Customer - Direct');
        insert a;
        Contact c = new Contact(FirstName = 'Test', LastName = 'User', AccountId = a.Id);
        insert c;
        User u = new User(
            Username = 'fileexplorertest@example.com',
            Alias = 'tuser',
            Email = 'fileexplorertest@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name='Customer Community Login User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            ContactId = c.Id
        );
        insert u;
        Test.startTest();
        System.runAs(u) {
            Id contactId = FileExplorerController.getContactId();
            System.assertEquals(c.Id, contactId);
        }
        Test.stopTest();
    }

    @isTest 
    static void testCreateFolderFileLink() {
        ContentDocumentLinkHandler.disableUpdate = true;
        
        Contact c = new Contact(FirstName = 'Link', LastName = 'Test');
        insert c;

        Folder__c folder = new Folder__c(Name = 'Test Folder', Contact__c = c.Id);
        insert folder;

        ContentVersion cv = new ContentVersion(
            Title = 'TestDoc',
            PathOnClient = 'TestDoc.txt',
            VersionData = Blob.valueOf('Hello world')
        );
        insert cv;

        Id docId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1].ContentDocumentId;
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        User u = new User(
            Username = 'folderadmin@example.com',
            Alias = 'adminu',
            Email = 'folderadmin@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            ProfileId = adminProfile.Id
        );
        insert u;

        Test.startTest();
        System.runAs(u) {

            FileExplorerController.createFolderFileLink(docId, folder.Id, c.Id);
        }
        Test.stopTest();

        List<FolderFileLink__c> links = [SELECT Id FROM FolderFileLink__c WHERE Folder__c = :folder.Id];
        System.assertEquals(1, links.size());
    }

    @isTest 
    static void testGetFoldersAndFiles() {
        ContentDocumentLinkHandler.disableUpdate = true;
        
        Contact c = new Contact(FirstName = 'Folder', LastName = 'Test');
        insert c;

        Folder__c folder = new Folder__c(Name = 'Test Folder', Contact__c = c.Id);
        insert folder;

        ContentVersion cv = new ContentVersion(
            Title = 'File1',
            PathOnClient = 'file1.txt',
            VersionData = Blob.valueOf('File Content')
        );
        insert cv;

        Id docId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1].ContentDocumentId;

        FileExplorerController.createFolderFileLink(docId, folder.Id, c.Id);

        Test.startTest();
        List<Object> folders = FileExplorerController.getFolders(c.Id);
        Test.stopTest();

        System.assert(!folders.isEmpty());
    }

    @isTest 
    static void testGetRecentFiles() {
        ContentDocumentLinkHandler.disableUpdate = true;
        
        Account a = new Account(Name = 'Recent Files', Type = 'Customer - Direct');
        insert a;        
        Contact c = new Contact(FirstName = 'Recent', LastName = 'Test', AccountId = a.Id);
        insert c;

        User u = new User(
            Username = 'recentfiles@example.com',
            Alias = 'arf',
            Email = 'recentfiles@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Files',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name='Customer Community Login User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            ContactId = c.Id
        );
        insert u;
        

        ContentVersion cv = new ContentVersion(
            Title = 'RecentFile',
            PathOnClient = 'recent.pdf',
            VersionData = Blob.valueOf('PDF content')
        );
        insert cv;
        
        Id docId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1].ContentDocumentId;

        ContentDocumentLink link = new ContentDocumentLink(
            ContentDocumentId = docId,
            LinkedEntityId = c.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert link;
        Folder__c folder = new Folder__c(Name = 'Test Folder', Contact__c = c.Id);
        insert folder;

        FolderFileLink__c folderLink = new FolderFileLink__c(
            Folder__c = folder.Id, 
            ContentDocumentId__c = docId,
            FileLabel__c = cv.Title, 
            UploadDate__c = Date.today(),
            Contact__c = c.Id
        );
        insert folderLink;
        System.runAs(u) {
            Test.startTest();
            List<Object> files = FileExplorerController.getRecentFiles(c.Id);
            System.assert(!files.isEmpty());
            Test.stopTest();
        }

    }

    @isTest 
    static void testGetAllContactFiles() {
        ContentDocumentLinkHandler.disableUpdate = true;
        
        Account a = new Account(Name = 'All Contact Files', Type = 'Customer - Direct');
        insert a;
        Contact c = new Contact(FirstName = 'AllContact', LastName = 'Files', AccountId = a.Id);
        insert c;
        User u = new User(
            Username = 'allcontactfiles@example.com',
            Alias = 'auf',
            Email = 'allcontactfiles@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Files',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name='Customer Community Login User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            ContactId = c.Id
        );
        insert u;
        ContentVersion cv = new ContentVersion(
            Title = 'AllContactFile',
            PathOnClient = 'allContactfile.txt',
            VersionData = Blob.valueOf('Some content')
        );
        insert cv;
    
        Id docId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        
        ContentDocumentLink link = new ContentDocumentLink(
            ContentDocumentId = docId,
            LinkedEntityId = c.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );

        system.debug('Link to insert: '+link);
        insert link;

        Folder__c folder = new Folder__c(Name = 'Test Folder', Contact__c = c.Id);
        insert folder;
        FolderFileLink__c folderLink = new FolderFileLink__c(
            Folder__c = folder.Id, 
            ContentDocumentId__c = docId,
            FileLabel__c = cv.Title, 
            UploadDate__c = Date.today(),
            Contact__c = c.Id
        );
        insert folderLink;
        
        System.runAs(u) {
            Test.startTest();
            List<Object> files = FileExplorerController.getAllContactFiles(c.Id);
            system.debug('Files from controller: '+files);
            System.assert(!files.isEmpty());
            Test.stopTest();
        }
    }
}
