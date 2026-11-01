public class QBPaymentSyncService implements Queueable, Database.AllowsCallouts {

    private Set<Id> invoiceIds;

    public QBPaymentSyncService(Set<Id> ids) {
        this.invoiceIds = ids;
    }

    public void execute(QueueableContext context) {

        // Fetch invoices with QuickBooks ID
        List<Invoice__c> invoices = [ SELECT Id, QuickBooks_Id__c, Opportunity__r.Account.QuickBooks_Id__c FROM Invoice__c WHERE Id IN :invoiceIds ];

        // Map QuickBooks Id -> Invoice__c
        Map<String, Invoice__c> qbIdToInvoiceMap = new Map<String, Invoice__c>();
        for (Invoice__c inv : invoices) {
            if (inv.QuickBooks_Id__c != null) {
                qbIdToInvoiceMap.put(inv.QuickBooks_Id__c, inv);
            }
        }

        QBCallout api = new QBCallout();
        List<Invoice__c> invoiceUpdates = new List<Invoice__c>();

        for (Invoice__c inv : invoices) {

            QBPaymentQueryJson response = api.getPaymentStatus(inv);

            if (response == null || response.QueryResponse == null || response.QueryResponse.Payment == null || response.QueryResponse.Payment.isEmpty()) {
                continue;
            }

            // Iterate all payments
            for (QBPaymentQueryJson.PaymentRecord pay : response.QueryResponse.Payment) {

                if (pay.Line == null || pay.Line.isEmpty()) { continue; }

                // Iterate all lines in the payment
                for (QBPaymentQueryJson.PaymentLine line : pay.Line) {

                    if (line.LinkedTxn == null || line.LinkedTxn.isEmpty()) { continue; }

                    // Iterate linked transactions
                    for (QBPaymentQueryJson.LinkedTxn txn : line.LinkedTxn) {

                        if (txn.TxnType == 'Invoice' && qbIdToInvoiceMap.containsKey(txn.TxnId)) {

                            Invoice__c matchedInvoice = qbIdToInvoiceMap.get(txn.TxnId);

                            // Update invoice fields
                            matchedInvoice.QB_Payment_Id__c = pay.Id;
                            matchedInvoice.Payment_Status__c = 'Paid';
                            matchedInvoice.Paid_Amount__c = line.Amount;
                            matchedInvoice.Last_Payment_Date__c = Date.valueOf(pay.TxnDate);
                            matchedInvoice.QB_Sync_Payment__c = false;

                            // Getting payment methods
                            QBPaymentMethodQueryJson payMeth = api.getPaymentMethod(pay.PaymentMethodRef.value);
                            matchedInvoice.Payment_Type__c = String.valueOf(payMeth.QueryResponse.PaymentMethod[0].type);
                            matchedInvoice.Payment_Name__c = String.valueOf(payMeth.QueryResponse.PaymentMethod[0].name);
                            invoiceUpdates.add(matchedInvoice);
                        }
                    }
                }
            }
        }

        if (!invoiceUpdates.isEmpty()) {
            try {
                CheckRecurssive.isRecurssive = true;
                update invoiceUpdates;
            } finally {
                CheckRecurssive.isRecurssive = false;
            }
        }
    }
}