@isTest
private class ContentDocumentLinkHandlerTest {

    @isTest
    static void testUpdateShareTypeAsync_doesNotThrow() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Customer Community Plus Login User' LIMIT 1];
        Account a = new Account(Name = 'All Contact Files', Type = 'Customer - Direct');
        insert a;
        Contact c = new Contact(FirstName = 'AllContact', LastName = 'Files', AccountId = a.Id);
        insert c;
        User u = new User(
            Username = 'plususer@example.com',
            Alias = 'plususer',
            Email='plususer@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Files',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name='Customer Community Plus Login User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            ContactId = c.Id
        );
        insert u;

         // Create dummy ContentVersion
         ContentVersion cv = new ContentVersion(
            Title = 'Plus File',
            PathOnClient = 'plus.txt',
            VersionData = Blob.valueOf('plus')
        );
        insert cv;

        Id docId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

        // Create new ContentDocumentLink using the test user
        ContentDocumentLink link = new ContentDocumentLink(
            ContentDocumentId = docId,
            LinkedEntityId = c.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );

        insert link;

        Test.startTest();
        ContentDocumentLinkHandler.disableUpdate = true;
        ContentDocumentLinkHandler.updateShareTypeAsync(new Set<Id>{ link.Id });
        Test.stopTest();
    }

    @isTest 
    static void testUpdateShareTypeAsync_handlesEmptySet() {
        Test.startTest();
        ContentDocumentLinkHandler.disableUpdate = true;
        ContentDocumentLinkHandler.updateShareTypeAsync(new Set<Id>());
        Test.stopTest();
        // Should not throw
    }
}