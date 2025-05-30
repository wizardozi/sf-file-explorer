// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents

string tempvar = 'Enter_your_name_here';
System.debug('Hello World!');
System.debug('My name is ' + tempvar);

List<User> usersToInit = [SELECT Id, ContactId FROM User WHERE Id = '005gL000002mKuYQAU'];
FolderInitializer.createDefaultFoldersForUser(usersToInit);



List<ContentDocumentLink> linksToUpdate = new List<ContentDocumentLink>();
        for (ContentDocumentLink l : [ SELECT Id, ContentDocumentId, ShareType, Visibility 
                                       FROM ContentDocumentLink 
                                       WHERE ContentDocumentId = '069gL000001cjhtQAA']) 
        {
            l.ShareType = 'I';
            linksToUpdate.add(l);
        }

update linksToUpdate;

insert new ContentDocumentLink(
    ContentDocumentId = '069gL000001cY9lQAE',  
    LinkedEntityId = '005gL000002HMuGQAW',   
    ShareType = 'I',
    Visibility = 'AllUsers'
);


List<ContentRendition> renditions = [
    SELECT Id, ContentDocumentId, Type, Status
    FROM ContentRendition
    WHERE ContentDocumentId = '069gL000001V34HQAS' 

for (ContentRendition cr : renditions) {
    System.debug('Type: ' + cr.Type + ', Status: ' + cr.Status);
}

ContentDocumentUtility.updateShareType('069gL000001kk7JQAQ');