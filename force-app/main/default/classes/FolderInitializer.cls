public class FolderInitializer {
    public static void createDefaultFoldersForUser(List<User> usersToInit) {        
        Set<Id> contactIds = new Set<Id>();
        for (User u : usersToInit) {
            contactIds.add(u.ContactId);
        }
        if (contactIds.isEmpty()) return;

        List<Folder__c> newFolders = new List<Folder__c>();
        List<String> folderNames = new List<String>{'Documents', 'Statements', 'Agreements', 'Reports', 'Other'};

        for (Id contactId : contactIds) {
            for (String folderName : folderNames) {
                newFolders.add(new Folder__c(
                    Name = folderName,
                    contact__c = contactId
                ));
            }
        }
        insert newFolders;
    }
}