public class QBInvoiceSyncService implements Queueable, Database.AllowsCallouts {

    private Set<Id> invoiceIds;

    public QBInvoiceSyncService(Set<Id> invIds) {
        this.invoiceIds = invIds;
    }

    public void execute(QueueableContext qc) {

        // Check recurssive
        CheckRecurssive.isRecurssive=true;

        List<Invoice__c> invoices = [
            SELECT Id,
                   Due_Date__c,
                   Name,
                   QuickBooks_Id__c,
                   QuickBooks_Sync_Token__c,
                   Description__c,
                   Amount__c,
                   Opportunity__r.Name,
                   Opportunity__r.Account.Customer_Email__c,
                   Opportunity__r.Account.QuickBooks_Id__c,
                   Opportunity__r.Account.BillingCity,  
                   Opportunity__r.Account.BillingStreet,  
                   Opportunity__r.Account.BillingState,  
                   Opportunity__r.Account.BillingPostalCode,  
                   Opportunity__r.Account.BillingLatitude,  
                   Opportunity__r.Account.BillingLongitude,  
                   Opportunity__r.Account.BillingCountry,
                   Opportunity__r.Account.Name,
                   Opportunity__r.Account.ShippingCity, 
                   Opportunity__r.Account.ShippingStreet, 
                   Opportunity__r.Account.ShippingState, 
                   Opportunity__r.Account.ShippingPostalCode, 
                   Opportunity__r.Account.ShippingLatitude, 
                   Opportunity__r.Account.ShippingLongitude, 
                   Opportunity__r.Account.ShippingCountry
            FROM Invoice__c
            WHERE Id IN :invoiceIds
        ];

        QBCallout callout = new QBCallout();

        for (Invoice__c inv : invoices) {

            // Query QB for existing invoice
            QBInvoiceQueryJSON queryJson = callout.getInvoice(inv);

            if (queryJson != null &&
                queryJson.QueryResponse.Invoice != null &&
                queryJson.QueryResponse.Invoice.size() == 1) {

                inv.QuickBooks_Id__c = queryJson.QueryResponse.Invoice[0].Id;
                inv.QuickBooks_Sync_Token__c = queryJson.QueryResponse.Invoice[0].SyncToken;
            }

            // Create or update invoice in QB
            QBInvoiceResponseJSON res = callout.createInvoiceCall(inv);

            if (res != null) {
                inv.QuickBooks_Id__c = res.Invoice.Id;
                inv.QuickBooks_Sync_Token__c = res.Invoice.SyncToken;
                inv.Tax__c = res.Invoice.TxnTaxDetail.TotalTax;
            }

            // Update refresh token in custom setting
            callout.updateRefreshToken();
        }

        // Update Salesforce invoices
        update invoices;

        // Check recurssive
        CheckRecurssive.isRecurssive=false;
    }
}