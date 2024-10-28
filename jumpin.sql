WITH filtered_transactions AS (
    SELECT 
        merchant_id,
        card_origin,
        month(date_add('hour', 8, created_at)) AS month,
        sum(total_amount + tips_amount) AS total_amount,
        count(*) AS transaction_count
    FROM datalake_etl_offline.offline_payment
    WHERE 
        agent_id IN (4393, 8450, 8454, 9030) 
        AND transaction_category = 'SALE'
        AND status IN ('SUCCESS', 'REFUNDED')
        AND DATE_FORMAT(date_add('hour', 8, created_at), '%Y-%m') IN ('2024-06', '2024-07')
    GROUP BY 
        month(date_add('hour', 8, created_at)),
        card_origin,
        merchant_id
),

pivoted_transactions AS (
    SELECT 
        merchant_id,
        SUM(CASE WHEN card_origin != 'FOREIGN' AND month = 6 THEN total_amount ELSE 0 END) AS "2024-06 domestic amount",
        SUM(CASE WHEN card_origin = 'FOREIGN' AND month = 6 THEN total_amount ELSE 0 END) AS "2024-06 foreign amount",
        SUM(CASE WHEN card_origin != 'FOREIGN' AND month = 6 THEN transaction_count ELSE 0 END) AS "2024-06 domestic count",
        SUM(CASE WHEN card_origin = 'FOREIGN' AND month = 6 THEN transaction_count ELSE 0 END) AS "2024-06 foreign count",
        SUM(CASE WHEN card_origin != 'FOREIGN' AND month = 7 THEN total_amount ELSE 0 END) AS "2024-07 domestic amount",
        SUM(CASE WHEN card_origin = 'FOREIGN' AND month = 7 THEN total_amount ELSE 0 END) AS "2024-07 foreign amount",
        SUM(CASE WHEN card_origin != 'FOREIGN' AND month = 7 THEN transaction_count ELSE 0 END) AS "2024-07 domestic count",
        SUM(CASE WHEN card_origin = 'FOREIGN' AND month = 7 THEN transaction_count ELSE 0 END) AS "2024-07 foreign count"
    FROM filtered_transactions
    GROUP BY merchant_id
),

ratio_calculation AS (
    SELECT 
        merchant_id,
        "2024-06 domestic amount",
        "2024-06 foreign amount",
        "2024-06 domestic count",
        "2024-06 foreign count",
        ("2024-06 foreign amount" * 1.0 / ("2024-06 domestic amount" + "2024-06 foreign amount")) AS "2024-06 foreign ratio amount",
        ("2024-06 foreign count" * 1.0 / ("2024-06 domestic count" + "2024-06 foreign count")) AS "2024-06 foreign ratio count",
        "2024-07 domestic amount",
        "2024-07 foreign amount",
        "2024-07 domestic count",
        "2024-07 foreign count",
        ("2024-07 foreign amount" * 1.0 / ("2024-07 domestic amount" + "2024-07 foreign amount")) AS "2024-07 foreign ratio amount",
        ("2024-07 foreign count" * 1.0 / ("2024-07 domestic count" + "2024-07 foreign count")) AS "2024-07 foreign ratio count"
    FROM pivoted_transactions
)

SELECT 
    m.merchant_id AS "Merchant ID",
    m.agent_id AS "Agent ID",
    m.dba_or_store_name AS "Shop Name",
    m.status AS "Status",
    r."2024-06 domestic amount",
    r."2024-06 foreign amount",
    r."2024-06 domestic count",
    r."2024-06 foreign count",
    r."2024-06 foreign ratio amount",
    r."2024-06 foreign ratio count",
    r."2024-07 domestic amount",
    r."2024-07 foreign amount",
    r."2024-07 domestic count",
    r."2024-07 foreign count",
    r."2024-07 foreign ratio amount",
    r."2024-07 foreign ratio count"
FROM datalake_etl_offline.offline_merchant m
LEFT JOIN ratio_calculation r
ON m.merchant_id = r.merchant_id
WHERE 
    m.agent_id IN (4393, 8450, 8454, 9030)
ORDER BY m.merchant_id;
