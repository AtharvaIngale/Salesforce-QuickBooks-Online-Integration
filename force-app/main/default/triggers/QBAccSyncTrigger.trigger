trigger QBAccSyncTrigger on Account (after insert, after update) {

    // Check for recurssive call
    if (CheckRecurssive.isRecurssive) {
        return;   // Prevent recursion when Queueable updates record
    }

    Set<Id> toSync = new Set<Id>();

    for (Account acc : Trigger.new) {

        if (acc.QB_Sync__c == true) {
            toSync.add(acc.Id);
        }
    }

    if (!toSync.isEmpty()) {
        System.enqueueJob(new QBCustomerSyncService(toSync));
    }
}