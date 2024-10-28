WITH terminal_data AS (
    SELECT
        merchant_id,
        MIN(date_add('hour', 8, terminal_installed_at)) AS "Installation Date"
    FROM 
        datalake_etl_offline.offline_terminal
    GROUP BY 
        merchant_id
),
payment_summary AS (
    SELECT
        merchant_id,
        SUM(CASE WHEN card_type = 'ALIPAY' THEN net_amount ELSE 0 END) AS "Total Transaction Amount - ALIPAY",
        COUNT(CASE WHEN card_type = 'ALIPAY' AND net_amount > 0 THEN 1 END) AS "No of Transaction - ALIPAY",
        SUM(CASE WHEN card_type = 'WECHAT' THEN net_amount ELSE 0 END) AS "Total Transaction Amount - WECHAT",
        COUNT(CASE WHEN card_type = 'WECHAT' AND net_amount > 0 THEN 1 END) AS "No of Transaction - WECHAT",
        SUM(CASE WHEN card_type = 'VISA' THEN net_amount ELSE 0 END) AS "Total Transaction Amount - VISA",
        COUNT(CASE WHEN card_type = 'VISA' AND net_amount > 0 THEN 1 END) AS "No of Transaction - VISA",
        SUM(CASE WHEN card_type = 'MASTER' THEN net_amount ELSE 0 END) AS "Total Transaction Amount - MASTER",
        COUNT(CASE WHEN card_type = 'MASTER' AND net_amount > 0 THEN 1  END) AS "No of Transaction - MASTER",
        SUM(CASE WHEN card_type = 'UNIONPAY' THEN net_amount ELSE 0 END) AS "Total Transaction Amount - UNIONPAY",
        COUNT(CASE WHEN card_type = 'UNIONPAY' AND net_amount > 0 THEN 1 END) AS "No of Transaction - UNIONPAY",
        SUM(CASE WHEN card_type = 'AMEX' THEN net_amount ELSE 0 END) AS "Total Transaction Amount - AMEX",
        COUNT(CASE WHEN card_type = 'AMEX' AND net_amount > 0 THEN 1 END) AS "No of Transaction - AMEX",
        SUM(CASE WHEN card_type = 'JCB' THEN net_amount ELSE 0 END) AS "Total Transaction Amount - JCB",
        COUNT(CASE WHEN card_type = 'JCB' AND net_amount > 0 THEN 1 END) AS "No of Transaction - JCB",
        SUM(CASE WHEN card_type = 'OCTOPUS' THEN net_amount ELSE 0 END) AS "Total Transaction Amount - OCTOPUS",
        COUNT(CASE WHEN card_type = 'OCTOPUS' AND net_amount > 0 THEN 1 END) AS "No of Transaction - OCTOPUS"
    FROM 
        datalake_etl_offline.offline_payment op
    WHERE
        transaction_category = 'SALE'
        AND status IN ('SUCCESS', 'REFUNDED')    
        AND DATE_ADD('HOUR', 8, op.created_at) BETWEEN TIMESTAMP '2024-07-30 00:00:00' AND TIMESTAMP '2024-07-30 23:59:59'
    GROUP BY 
        merchant_id
)

SELECT
    date_add('hour', 8, m.created_at) AS "Create Date",
    m.merchant_id AS "Merchant ID",
    m.agent_id AS "Agent ID",
    m.legal_name AS "Legal Name",
    m.dba_or_store_name AS "Shop Name",
    m.mcc AS "MCC",
    m.status AS "Status",
    m.preferred_processor_visa AS "VISA Processor",
    m.preferred_processor_master AS "MASTER Processor",
    m.preferred_processor_jcb AS "JCB Processor",
    m.preferred_processor_unionpay AS "UPI Processor",
    CASE 
        WHEN m.preferred_processor_amex = 'AMEX_BBMSL' THEN 'YES'
        ELSE 'NO'
    END AS "Amex Aggregator",
    t."Installation Date",
    m.sales_first_name AS "Sales",
    m.referrer_name AS "Referrer",
    COALESCE(p."Total Transaction Amount - ALIPAY", 0) AS "Total Transaction Amount - ALIPAY",
    COALESCE(p."No of Transaction - ALIPAY", 0) AS "No of Transaction - ALIPAY",
    COALESCE(p."Total Transaction Amount - WECHAT", 0) AS "Total Transaction Amount - WECHAT",
    COALESCE(p."No of Transaction - WECHAT", 0) AS "No of Transaction - WECHAT",
    COALESCE(p."Total Transaction Amount - VISA", 0) AS "Total Transaction Amount - VISA",
    COALESCE(p."No of Transaction - VISA", 0) AS "No of Transaction - VISA",
    COALESCE(p."Total Transaction Amount - MASTER", 0) AS "Total Transaction Amount - MASTER",
    COALESCE(p."No of Transaction - MASTER", 0) AS "No of Transaction - MASTER",
    COALESCE(p."Total Transaction Amount - UNIONPAY", 0) AS "Total Transaction Amount - UNIONPAY",
    COALESCE(p."No of Transaction - UNIONPAY", 0) AS "No of Transaction - UNIONPAY",
    COALESCE(p."Total Transaction Amount - AMEX",  0) AS "Total Transaction Amount - AMEX",
    COALESCE(p."No of Transaction - AMEX", 0) "No of Transaction - AMEX",
    COALESCE(p."Total Transaction Amount - JCB", 0) AS "Total Transaction Amount - JCB",
    COALESCE(p."No of Transaction - JCB", 0) AS "No of Transaction - JCB",
    COALESCE(p."Total Transaction Amount - OCTOPUS", 0) AS "Total Transaction Amount - OCTOPUS",
    COALESCE(p."No of Transaction - OCTOPUS", 0) AS "No of Transaction - OCTOPUS"
FROM 
    datalake_etl_offline.offline_merchant m
LEFT JOIN 
    terminal_data t ON m.merchant_id = t.merchant_id
LEFT JOIN
    payment_summary p ON m.merchant_id = p.merchant_id
ORDER BY 
    m.merchant_id ASC;
