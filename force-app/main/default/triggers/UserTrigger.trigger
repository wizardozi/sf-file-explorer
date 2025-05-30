trigger UserTrigger on User (after insert) {    
    Map<String, Id> targetProfiles = new Map<String, Id>();
    for (Profile p : [SELECT Id, Name FROM Profile WHERE Name IN ('Customer Community Plus Login User', 'Customer Community Login User')]) {
        targetProfiles.put(p.Name, p.Id);
    }
    List<User> usersToInitialize = new List<User>();
    for (User u : Trigger.new) {
        if (targetProfiles.values().contains(u.ProfileId)) {
            usersToInitialize.add(u);
        }
    }
    FolderInitializer.createDefaultFoldersForUser(usersToInitialize);
}
