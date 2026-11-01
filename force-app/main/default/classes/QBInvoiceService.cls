public with sharing class QBInvoiceService {

    public static void createInvoice(Id oppId) {
        Opportunity p = [ SELECT Id, Name, Amount, Account.Customer_Email__c FROM Opportunity WHERE Id = :oppId ];

        // 1. Create/Find Customer in QuickBooks
        String customerId = QBCustomerService.getOrCreateCustomer(p);

        // 2. Prepare Invoice JSON 
        Map<String, Object> invoiceBody = new Map<String, Object>{
            'CustomerRef' => new Map<String, String>{ 'value' => customerId },
            'Line' => new List<Object>{
                new Map<String, Object>{
                    'Amount' => p.Amount,
                    'DetailType' => 'SalesItemLineDetail',
                    'SalesItemLineDetail' => new Map<String, Object>{
                        'ItemRef' => new Map<String, String>{ 'value' => '1' } // default QB item
                    }
                }
            }
        };

        String jsonBody = JSON.serialize(invoiceBody);
        QuickBooksAuth__mdt record = QuickBooksAuth__mdt.getInstance('Default_Auth');
        String realmId = record.Realm_Id__c;

        // 3. Call QuickBooks API using Named Credential
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:QuickBooksNCLegacy/v3/company/' + realmId + '/invoice');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(jsonBody);

        Http h = new Http();
        HttpResponse res = h.send(req);

        // 4. Handle response
        if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
            Map<String,Object> result = (Map<String,Object>) JSON.deserializeUntyped(res.getBody());
            String qbInvoiceId = (String)((Map<String,Object>)result.get('Invoice')).get('Id');

            p.Quickbooks_Invoice_Id__c = qbInvoiceId;
            update p;
        } else {
            throw new AuraHandledException('QuickBooks Error: ' + res.getBody());
        }
    }
}