public class QBInvoiceQueue implements Queueable, Database.AllowsCallouts {

    private List<Id> oppIds;

    public QBInvoiceQueue(List<Id> oppIds) {
        this.oppIds = oppIds;
    }

    public void execute(QueueableContext context) {

        List<Opportunity> oppList = [
            SELECT Id, Name, Amount, AccountId, Signed_Status__c 
            FROM Opportunity 
            WHERE Id IN :oppIds
        ];

        for (Opportunity opp : oppList) {
            QBInvoiceService.createInvoice(opp.Id);
        }
    }
}