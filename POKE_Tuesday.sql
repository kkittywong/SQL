
SELECT 
    merchant_id AS "Merchant ID",
    DATE(date_add('hour', 8, created_at)) AS "Create Date",
    SUM(net_amount) AS "Total Net Amount",
    AVG(SUM(net_amount)) OVER () AS "Average Net Amount"
FROM
    datalake_etl_offline.offline_payment
WHERE
    merchant_id = 13572
    AND transaction_category = 'SALE'
    AND status IN ('SUCCESS', 'REFUNDED')
    AND day_of_week(date_add('hour', 8, created_at)) = 2
    AND HOUR(date_add('hour', 8, created_at)) BETWEEN 18 AND 20
    AND YEAR(date_add('hour', 8, created_at)) IN (2023, 2024)
    AND MONTH(date_add('hour', 8, created_at)) IN (8, 9)
GROUP BY
    merchant_id,
    DATE(date_add('hour', 8, created_at))
ORDER BY
    DATE(date_add('hour', 8, created_at));
