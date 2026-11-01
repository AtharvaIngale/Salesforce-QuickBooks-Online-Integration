trigger QBInvSyncTrigger on Invoice__c (after insert, after update) {

    // Check for recurssive call
    if (CheckRecurssive.isRecurssive) {
        return;   // Prevent recursion when Queueable updates record
    }

    Set<Id> toSync = new Set<Id>();

    for (Invoice__c inv : Trigger.new) {
        // Sync only if Opportunity.Account Email exists (required for customer)
        if (inv.Signed_Status__c == 'Signed') {
            toSync.add(inv.Id);
        }
    }

    if (!toSync.isEmpty()) {
        System.enqueueJob(new QBInvoiceSyncService(toSync));
    }
}