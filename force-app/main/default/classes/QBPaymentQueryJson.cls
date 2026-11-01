public class QBPaymentQueryJson {

    public QueryResponse QueryResponse;
    public String time1;

    public class QueryResponse {
        public List<PaymentRecord> Payment;
        public Integer startPosition;
        public Integer maxResults;
    }

    public class PaymentRecord {
        public Ref CustomerRef;
        public Ref DepositToAccountRef;
        public Ref PaymentMethodRef;
        public Decimal TotalAmt;
        public Decimal UnappliedAmt;
        public Boolean ProcessPayment;
        public String domain;
        public Boolean sparse;
        public String Id;
        public String SyncToken;
        public MetaData MetaData;
        public String TxnDate;
        public Ref CurrencyRef;
        public List<PaymentLine> Line;
    }

    public class Ref {
        public String value;
        public String name;
    }

    public class MetaData {
        public String CreateTime;
        public String LastUpdatedTime;
    }

    public class PaymentLine {
        public Decimal Amount;
        public List<LinkedTxn> LinkedTxn;
        public LineEx LineEx;
    }

    public class LinkedTxn {
        public String TxnId;
        public String TxnType;
    }

    public class LineEx {
        public List<NameValueWrapper> any1;
    }

    public class NameValueWrapper {
        public String name;
        public String declaredType;
        public String scope;
        public NameValue value;
        public Boolean nil;
        public Boolean globalScope;
        public Boolean typeSubstituted;
    }

    public class NameValue {
        public String Name;
        public String Value;
    }

    // Parser
    public static QBPaymentQueryJson parse(String json) {
        return (QBPaymentQueryJson) System.JSON.deserialize(json, QBPaymentQueryJson.class);
    }
}