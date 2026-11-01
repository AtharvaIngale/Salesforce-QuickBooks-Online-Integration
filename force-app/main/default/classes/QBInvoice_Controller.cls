public with sharing class QBInvoice_Controller {

    public Id invId{get;set;}
    public Invoice__c inv {get;set;}

    public QBInvoice_Controller(ApexPages.StandardController controller) {
        invId = controller.getRecord().Id;
        inv = [SELECT Id,
                     Due_Date__c,
                       Name, 
                       QuickBooks_Id__c, 
                       QuickBooks_Sync_Token__c,
                    //    Terms__c,
                       Description__c,
                       Amount__c,
                       Invoice__c.Opportunity__r.Name,
                       Invoice__c.Opportunity__r.Account.Customer_Email__c,
                       Invoice__c.Opportunity__r.Account.QuickBooks_Id__c,
                       Invoice__c.opportunity__r.account.BillingCity,  
                       Invoice__c.opportunity__r.account.BillingStreet,  
                       Invoice__c.opportunity__r.account.BillingState,  
                       Invoice__c.opportunity__r.account.BillingPostalCode,  
                       Invoice__c.opportunity__r.account.BillingLatitude,  
                       Invoice__c.opportunity__r.account.BillingLongitude,  
                       Invoice__c.opportunity__r.account.BillingCountry,
                       Invoice__c.opportunity__r.account.name,
                    //    Invoice__c.opportunity__r.account.contact__r.Name,
                    //    Invoice__c.opportunity__r.account.contact__r.Phone,
                       Invoice__c.opportunity__r.account.ShippingCity, 
                       Invoice__c.opportunity__r.account.ShippingStreet, 
                       Invoice__c.opportunity__r.account.ShippingState, 
                       Invoice__c.opportunity__r.account.ShippingPostalCode, 
                       Invoice__c.opportunity__r.account.ShippingLatitude, 
                       Invoice__c.opportunity__r.account.ShippingLongitude, 
                       Invoice__c.opportunity__r.account.ShippingCountry
                    FROM Invoice__c 
                    WHERE Id =: invId];
    }

    public Pagereference syncQB(){
        QBCallout callout = new QBCallout();
        QBInvoiceQueryJSON queryJson = callout.getInvoice(inv);

        //Check if an invoice was found
        if(queryJson != null){
            if(queryJson.QueryResponse.Invoice.size() == 1){
                inv.QuickBooks_Id__c = queryJson.QueryResponse.Invoice[0].Id;
                inv.QuickBooks_Sync_Token__c = queryJson.QueryResponse.Invoice[0].SyncToken;
            }else{
                //Multiple Customer Error Handling
               throw new ListException(); 
            }
        }
        QBInvoiceResponseJSON res = callout.createInvoiceCall(inv);

        callout.updateRefreshToken();

        
        inv.QuickBooks_Id__c = res.Invoice.Id;
        inv.QuickBooks_Sync_Token__c = res.Invoice.SyncToken;
        inv.tax__c = res.Invoice.TxnTaxDetail.TotalTax;
        //inv.total__c = res.Invoice.TotalAmt;
        //inv.Balance_Due__c = res.Invoice.Balance;
        //DML After Callouts

        update inv;
        return new PageReference('/'+ invId);
    }
    
}