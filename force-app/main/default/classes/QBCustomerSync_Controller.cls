public with sharing class QBCustomerSync_Controller {

    public Id accId{get;set;}
    public Account acc {get;set;}

    public QBCustomerSync_Controller(ApexPages.StandardController stdController) {
        accId = ApexPages.currentPage().getParameters().get('id');
        acc = [SELECT Id,
                      Name, 
                      QuickBooks_Id__c, 
                      QuickBooks_Sync_Token__c,
                      ShippingCity,
                      ShippingStreet,
                      ShippingState,
                      ShippingCountry,
                      ShippingPostalCode,
                      Phone,
                      BillingCity,
                      BillingStreet,
                      BillingCountry,
                      BillingPostalCode,
                      BillingState,
                      BillingLatitude,
                      BillingLongitude
              FROM Account 
              WHERE Id =: accId];
    }

    public Pagereference syncQB(){
        QBCallout callout = new QBCallout();
        QBCustomerJSON accountData = callout.getCustomer(acc);

        //Check if a customer was found
        if(accountData.QueryResponse.Customer != null){
            
            //Check if only 1 customer was found
            if(accountData.QueryResponse.Customer.size() == 1){
                for(QBCustomerJSON.Customer c : accountData.QueryResponse.Customer){
                    acc.QuickBooks_Id__c = c.id;
                    System.debug('QB Id: ' + acc.QuickBooks_Id__c);
                    acc.QuickBooks_Sync_Token__c = c.SyncToken;
                    System.debug('QB Synctoken: ' + acc.QuickBooks_Sync_Token__c );
                }
            }else{
                //Multiple Customer Error Handling
               throw new ListException(); 
            }
        }

        QBCustomerResponseJSON accountPushData = callout.createCustomerCall(acc);
        System.debug(accountPushData);

        if(accountPushData.Customer.Id != null){
            acc.QuickBooks_Id__c = accountPushData.Customer.Id;
        }
        if(accountPushData.Customer.SyncToken != null){
            acc.QuickBooks_Sync_Token__c = accountPushData.Customer.SyncToken;
        }
        
        callout.updateRefreshToken();
        //DML After Callouts
        update acc;

        return new PageReference('/'+accId);
    }
    
}