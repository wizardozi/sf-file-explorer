public class ContentDocumentLinkHandler {

    public static Boolean disableUpdate = false;

    public static void updateShareTypeAsync(Set<Id> linkIds) {
        if (linkIds == null || linkIds.isEmpty()) return;
        updateCDLInFuture(new List<Id>(linkIds));
    }

    @future
    public static void updateCDLInFuture(List<Id> linkIds) {

        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        links = [
            SELECT Id, ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE Id IN :linkIds
        ];
        for (ContentDocumentLink link : links) {
            link.ShareType = 'V';
            link.Visibility = 'AllUsers';
        }
        if (!disableUpdate) {
            update links;
        }
    }
    
}

// OLD CODE DONT DELETE 
// public class ContentDocumentLinkHandler {
//     public static void updateShareTypeAsync(Set<Id> linkIds) {
//         updateCDLInFuture(new List<Id>(linkIds));
//     }

//     @future
//     public static void updateCDLInFuture(List<Id> linkIds) {
//         List<ContentDocumentLink> updates = new List<ContentDocumentLink>();
//         for (ContentDocumentLink link : [
//             SELECT Id, ContentDocumentId, LinkedEntityId
//             FROM ContentDocumentLink
//             WHERE Id IN :linkIds
//         ]) {
//             updates.add(new ContentDocumentLink(
//                 Id = link.Id,
//                 ShareType = 'V',
//                 Visibility = 'AllUsers'
//             ));
//         }
//         if (!updates.isEmpty()) {
//             update updates;
//         }
//     }
// }
