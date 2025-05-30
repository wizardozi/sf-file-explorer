@isTest
private class FolderInitializerTest {
    @isTest
    static void testCreateDefaultFoldersForUser() {
        ContentDocumentLinkHandler.disableUpdate = true;
        
        Account a = new Account(Name = 'Test Folder Account', Type = 'Customer - Direct');
        insert a;
        Contact c = new Contact(FirstName = 'Test', LastName = 'Folder', AccountId = a.Id);
        insert c;
        User u = new User(
            Username = 'test.folderuser@example.com',
            Alias = 'tfu',
            Email = 'test.folderuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            ProfileId = [SELECT Id FROM Profile WHERE Name='Customer Community Login User' LIMIT 1].Id,
            ContactId = c.Id
        );
        // Run method
        Test.startTest();
        insert u;        
        Test.stopTest();

        // Assert that 5 folders were created
        List<Folder__c> folders = [
            SELECT Id, Name FROM Folder__c WHERE Contact__c = :c.Id
        ];
        System.assertEquals(5, folders.size(), 'Five default folders should be created');
    }
}