WITH order_summary AS (
    SELECT
        merchant_id,
        payment_gateway AS "PaymentGateway",
        currency,
        SUM(CASE WHEN card_type = 'ALIPAY' THEN net_amount ELSE 0 END) AS "Total Transaction Amount - ALIPAY",
        COUNT(CASE WHEN card_type = 'ALIPAY'  AND net_amount > 0 THEN 1 END) AS "No of Transaction - ALIPAY",
        SUM(CASE WHEN card_type = 'WECHAT' THEN net_amount ELSE 0 END) AS "Total Transaction Amount - WECHAT",
        COUNT(CASE WHEN card_type = 'WECHAT' AND net_amount > 0 THEN 1 END) AS "No of Transaction - WECHAT",
        SUM(CASE WHEN card_type = 'VISA' THEN net_amount ELSE 0 END) AS "Total Transaction Amount - VISA",
        COUNT(CASE WHEN card_type = 'VISA' AND net_amount > 0 THEN 1 END) AS "No of Transaction - VISA",
        SUM(CASE WHEN card_type = 'MASTER' THEN net_amount ELSE 0 END) AS "Total Transaction Amount - MASTER",
        COUNT(CASE WHEN card_type = 'MASTER' AND net_amount > 0 THEN 1 END) AS "No of Transaction - MASTER",
        SUM(CASE WHEN card_type = 'UNIONPAY' THEN net_amount ELSE 0 END) AS "Total Transaction Amount - UNIONPAY",
        COUNT(CASE WHEN card_type = 'UNIONPAY' AND net_amount > 0 THEN 1 END) AS "No of Transaction - UNIONPAY"
    FROM 
        datalake_etl_online.online_order ot
    WHERE
        order_category = 'SALE'
        AND status IN ('SUCCESS', 'REFUNDED', 'SETTLED')    
        AND DATE_ADD('HOUR', 8, ot.created_at) BETWEEN TIMESTAMP '2024-07-30 00:00:00' AND TIMESTAMP '2024-07-30 23:59:59'
    GROUP BY 
        merchant_id, payment_gateway, currency
)

SELECT
    DATE_ADD('HOUR', 8, m.created_at) AS "Create Date",
    t.PaymentGateway,
    m.merchant_id AS "Merchant ID",
    m.legal_name AS "Legal Name",
    m.mcc AS "MCC",
    m.status AS "Status",
    t.currency,
    NULL AS "Installation Date",
    COALESCE(t."Total Transaction Amount - ALIPAY", 0) AS "Total Transaction Amount - ALIPAY",
    COALESCE(t."No of Transaction - ALIPAY", 0) AS "No of Transaction - ALIPAY",
    COALESCE(t."Total Transaction Amount - WECHAT", 0) AS "Total Transaction Amount - WECHAT",
    COALESCE(t."No of Transaction - WECHAT", 0) AS "No of Transaction - WECHAT",
    COALESCE(t."Total Transaction Amount - VISA", 0) AS "Total Transaction Amount - VISA",
    COALESCE(t."No of Transaction - VISA", 0) AS "No of Transaction - VISA",
    COALESCE(t."Total Transaction Amount - MASTER", 0) AS "Total Transaction Amount - MASTER",
    COALESCE(t."No of Transaction - MASTER", 0) AS "No of Transaction - MASTER",
    COALESCE(t."Total Transaction Amount - UNIONPAY", 0) AS "Total Transaction Amount - UNIONPAY",
    COALESCE(t."No of Transaction - UNIONPAY", 0) AS "No of Transaction - UNIONPAY"
FROM 
    datalake_etl_online.online_merchant m
LEFT JOIN
    order_summary t ON m.merchant_id = t.merchant_id
ORDER BY 
    m.merchant_id ASC;


    