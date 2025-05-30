trigger UpdateCDLShareType on ContentDocumentLink (after insert) {
    Set<Id> linkIds = new Set<Id>();
    for (ContentDocumentLink cdl : Trigger.new) {
        linkIds.add(cdl.Id);
    }
    ContentDocumentLinkHandler.updateShareTypeAsync(linkIds);
}