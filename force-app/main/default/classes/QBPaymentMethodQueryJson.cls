public with sharing class QBPaymentMethodQueryJson {
    public QueryResponse queryResponse;
    public String time2;
    
    public class PaymentMethodRecord {
        public String name;
        public String type;
        public String sparse;
        public String id;
    }

    public class QueryResponse {
        public List<PaymentMethodRecord> paymentMethod;
        public Integer startPosition;
        public Integer maxResults;
    }

    //Parser
    public static QBPaymentMethodQueryJson parse(String json) {
        return (QBPaymentMethodQueryJson) System.JSON.deserialize(json, QBPaymentMethodQueryJson.class);
    }

}