public class QBCustomerService {

    public static String getOrCreateCustomer(Opportunity p) {

        QuickBooksAuth__mdt record = QuickBooksAuth__mdt.getInstance('Default_Auth');
        String realmId = record.Realm_Id__c;

        String rawQuery = 'select Id from Customer where PrimaryEmailAddr = \'' + p.Account.Customer_Email__c + '\'';
        String finalEndpoint ='https://sandbox-quickbooks.api.intuit.com/v3/company/' + realmId + '/query?query=' + rawQuery;

        System.debug('finalEndpoint => ' + finalEndpoint);

        HttpRequest req = new HttpRequest();
        req.setEndpoint(finalEndpoint);
        req.setMethod('GET');
        req.setHeader('Content-Type', 'text/plain');

        Http h = new Http();
        HttpResponse res = h.send(req);
        System.debug('RESPONSE: ' + res.getBody());

        Map<String,Object> result = (Map<String,Object>) JSON.deserializeUntyped(res.getBody());

        List<Object> customers = (List<Object>)((Map<String,Object>)result.get('QueryResponse')).get('Customer');

        if (customers != null && !customers.isEmpty()) {
            return (String)((Map<String,Object>)customers[0]).get('Id');
        }

        // Otherwise create customer
        Map<String,Object> custJson = new Map<String,Object>{
            'DisplayName' => p.Name,
            'PrimaryEmailAddr' => new Map<String,String>{ 'Address' => p.Account.Customer_Email__c }
        };

        HttpRequest createReq = new HttpRequest();
        createReq.setEndpoint('https://sandbox-quickbooks.api.intuit.com/v3/company/' + realmId + '/customer');
        createReq.setMethod('POST');
        createReq.setHeader('Content-Type', 'application/json');
        createReq.setBody(JSON.serialize(custJson));

        HttpResponse createRes = h.send(createReq);

        Map<String,Object> custResult =
            (Map<String,Object>) JSON.deserializeUntyped(createRes.getBody());

        return (String)((Map<String,Object>)custResult.get('Customer')).get('Id');
    }
}