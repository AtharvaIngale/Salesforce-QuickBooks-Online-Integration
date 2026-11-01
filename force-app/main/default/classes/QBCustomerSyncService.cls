public class QBCustomerSyncService implements Queueable, Database.AllowsCallouts {

    private Set<Id> accountIds;

    public QBCustomerSyncService(Set<Id> accIds) {
        this.accountIds = accIds;
    }

    public void execute(QueueableContext qc) {

        // Check recurssive
        CheckRecurssive.isRecurssive=true;

        List<Account> accounts = [ SELECT Id, Name, Customer_Email__c, QuickBooks_Id__c, QuickBooks_Sync_Token__c,
                   ShippingCity, ShippingStreet, ShippingState, ShippingCountry,
                   ShippingPostalCode, Phone, BillingCity, BillingStreet,
                   BillingCountry, BillingPostalCode, BillingState,
                   BillingLatitude, BillingLongitude, QB_Sync__c
            FROM Account
            WHERE Id IN :accountIds
        ];

        QBCallout callout = new QBCallout();

        for (Account acc : accounts) {

            // Query existing customer in QB
            QBCustomerJSON remoteCustomer = callout.getCustomer(acc);

            if (remoteCustomer != null &&
                remoteCustomer.QueryResponse != null &&
                remoteCustomer.QueryResponse.Customer != null &&
                remoteCustomer.QueryResponse.Customer.size() == 1) {

                QBCustomerJSON.Customer c = remoteCustomer.QueryResponse.Customer[0];
                acc.QuickBooks_Id__c = c.Id;
                acc.QuickBooks_Sync_Token__c = c.SyncToken;
            }

            // Push/update in QB
            QBCustomerResponseJSON result = callout.createCustomerCall(acc);

            if (result != null && result.Customer != null) {
                acc.QuickBooks_Id__c = result.Customer.Id;
                acc.QuickBooks_Sync_Token__c = result.Customer.SyncToken;
            }

            acc.QB_Sync__c = false; //Uncheck the QB Sync checkbox
            
            callout.updateRefreshToken();
        }

        update accounts;

        // Check recurssive
        CheckRecurssive.isRecurssive=false;
    }
}