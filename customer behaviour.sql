------------------------------Topic 1 (Offline) refund time interval --------------------------------
SELECT
    payment_id AS "Payment ID",
    merchant_id AS "Merchant ID",
    date_add('hour', 8, created_at) AS "Transaction date",
    date_add('hour', 8, updated_at) AS "Refund date",
    DATE_DIFF('day', date_add('hour', 8, created_at), date_add('hour', 8, updated_at)) AS "refund time interval"
FROM 
    datalake_etl_offline.offline_payment
WHERE
    status = 'REFUNDED'
    AND transaction_category = 'SALE'
ORDER BY
    payment_id,
    merchant_id;

--------------------------------------------Topic 1 (Online) Refund Time interval --------------------------------------
SELECT
    order_id As "Order ID",
    merchant_id AS "Merchant ID",
    date_add('hour', 8, created_at) AS "Transaction date",
    date_add('hour', 8, updated_at) AS "Refund date",
    DATE_DIFF('day', created_at, updated_at) AS "refund time interval"
FROM 
    datalake_etl_online.online_order
WHERE
    status = 'REFUNDED'
    AND order_category = 'SALE'
ORDER BY
    order_id,
    merchant_id;

-------------Topic 2-(Offline) Time interval between merchant create date and its first successful transaction date-----------------

WITH first_successful_transactions AS (
    SELECT
        merchant_id,
        MIN(date_add('hour', 8, created_at)) AS "first successful transaction date"
    FROM 
        datalake_etl_offline.offline_payment
    WHERE
        status IN ('SUCCESS', 'REFUNDED')
        AND transaction_category = 'SALE'
    GROUP BY
        merchant_id
)
SELECT
    m.merchant_id AS "Merchant ID",
    date_add('hour', 8, m.created_at) AS "Merchant Create Date",
    fst."first successful transaction date",
    DATE_DIFF('day', date_add('hour', 8, m.created_at), fst."first successful transaction date") AS "days to first transaction"
FROM
    datalake_etl_offline.offline_merchant m
JOIN
    first_successful_transactions fst
ON
    m.merchant_id = fst.merchant_id
ORDER BY
    m.merchant_id;

------------Topic 2- (Online) Time interval between merchant create date and its first successful transaction date ----------

WITH first_successful_transactions AS (
    SELECT
        merchant_id,
        MIN(date_add('hour', 8, created_at)) AS "first successful transaction date"
    FROM 
        datalake_etl_online.online_order
    WHERE
        status IN ('SUCCESS', 'REFUNDED', ' SETTLED')
        AND order_category = 'SALE'
    GROUP BY 
        merchant_id
)
SELECT
    m.merchant_id AS "Merchant ID",
    date_add('hour', 8, m.created_at) AS "Merchant Create Date",
    fst."first successful transaction date",
    DATE_DIFF('day', date_add('hour', 8, m.created_at), fst."first successful transaction date") AS "days to first transaction"
FROM
    datalake_etl_online.online_merchant m
JOIN
    first_successful_transactions fst
ON
    m.merchant_id = fst.merchant_id
ORDER BY
    m.merchant_id;

----------------------------------------Topic 3-- Transaction by terminal model -------------------------------------------

SELECT 
    p.merchant_id AS "Merchant ID",
    p.terminal_id AS "Terminal ID",
    t.terminal_model AS "Terminal Model",
    COUNT(p.payment_id) AS "Transaction Count",
    SUM(p.net_amount) AS "Total Transaction Amount",
    AVG(p.net_amount) AS "Average Transaction Amount"
FROM
    datalake_etl_offline.offline_payment p
LEFT JOIN
    datalake_etl_offline.offline_terminal t
ON
    p.terminal_id = t.terminal_serial_number
WHERE
    p.status IN ('SUCCESS', 'REFUNDED')
    AND p.transaction_category = 'SALE'
GROUP BY
    p.merchant_id,
    p.terminal_id,
    t.terminal_model
ORDER BY
    p.merchant_id;

----------------------------------Topic 4- Transaction by status (further analyzed with terminal model) ---------------------------------------

SELECT
    p.merchant_id AS "Merchant ID",
    p.terminal_id AS "Terminal ID",
    t.terminal_model AS "Terminal Model",
    COUNT(p.payment_id) AS "Number of Transactions",
    SUM(p.net_amount) AS "Total Transaction Amount",
    COUNT(CASE WHEN p.status IN ('SUCCESS', 'REFUNDED') THEN 1 END) AS "successful transactions",
    COUNT(CASE WHEN p.status IN ('CANCELLED', 'AUTHORIZED', 'PENDING', 'NONE', 'REVERSED', 'VOIDED', 'DECLINED') THEN 1 END) AS "failed transactions",
    ROUND((COUNT(CASE WHEN p.status IN ('SUCCESS', 'REFUNDED') THEN 1 END) / CAST(COUNT(p.payment_id) AS DOUBLE)) * 100, 2) AS "success rate percentage"
FROM
    datalake_etl_offline.offline_payment p
LEFT JOIN
    datalake_etl_offline.offline_terminal t
ON
    p.terminal_id = t.terminal_serial_number
WHERE
    p.transaction_category = 'SALE'
GROUP BY
    p.merchant_id,
    p.terminal_id,
    t.terminal_model
ORDER BY 
    p.merchant_id;

------------------------------------------Topic 4- (offline) Transaction by status ------------------------------------------

SELECT
    p.merchant_id AS "Merchant ID",
    COUNT(p.payment_id) AS "Number of Transactions",
    SUM(p.net_amount) AS "Total Transaction Amount",
    COUNT(CASE WHEN p.status IN ('SUCCESS', 'REFUNDED') THEN 1 END) AS "successful transactions",
    COUNT(CASE WHEN p.status IN ('CANCELLED', 'AUTHORIZED', 'PENDING', 'NONE', 'REVERSED', 'VOIDED', 'DECLINED') THEN 1 END) AS "failed transactions",
    ROUND((COUNT(CASE WHEN p.status IN ('SUCCESS', 'REFUNDED') THEN 1 END) / CAST(COUNT(p.payment_id) AS DOUBLE)) * 100, 2) AS "success rate percentage"
FROM
    datalake_etl_offline.offline_payment p
WHERE
    p.transaction_category = 'SALE'
GROUP BY
    p.merchant_id
ORDER BY 
    p.merchant_id;

-------------------------------------------Topic 4-(online) Transaction by status---------------------------------------------------

SELECT
    merchant_id AS "Merchant ID",
    COUNT(order_id) AS "Number of Transactions",
    SUM(net_amount) AS "Total Transaction Amount",
    COUNT(CASE WHEN status IN ('SUCCESS', 'SETTLED', 'REFUNDED') THEN 1 END) AS "successful transactions",
    COUNT(CASE WHEN status IN ('DECLINED', 'VOIDED', 'OPEN', 'CLOSED') THEN 1 END) AS "failed transactions",
    ROUND((COUNT(CASE WHEN status IN ('SUCCESS', 'SETTLED', 'REFUNDED') THEN 1 END) / CAST(COUNT(order_id) AS DOUBLE)) * 100, 2) AS "success rate percentage"
FROM
    datalake_etl_online.online_order
WHERE
    order_category = 'SALE'
GROUP BY
    merchant_id
ORDER BY
    merchant_id;

----------------------------------------Topic 5-(offline) Average transaction by day type -----------------------------------------

SELECT
    merchant_id AS "Merchant ID",
    CASE
        WHEN DAY_OF_WEEK(DATE_ADD('hour', 8, created_at)) BETWEEN 1 AND 5 THEN 'Weekday'
        ELSE 'Weekend'
    END AS "day type",
    day_of_week(date_add('hour', 8, created_at)) AS "day of week",
    COUNT(payment_id) AS "Number of Transactions",
    SUM(net_amount) AS "Total Transaction Amount",
    AVG(net_amount) AS "Average Transaction Amount"
FROM
    datalake_etl_offline.offline_payment
WHERE
    status IN ('SUCCESS', 'REFUNDED')
    AND transaction_category = 'SALE'
GROUP BY
    merchant_id,
    CASE
        WHEN DAY_OF_WEEK(DATE_ADD('hour', 8, created_at)) BETWEEN 1 AND 5 THEN 'Weekday'
        ELSE 'Weekend'
    END,
    DAY_OF_WEEK(DATE_ADD('hour', 8, created_at))
ORDER BY
    merchant_id;

-----------------------------------Topic 5- (online) Average transaction by day type ----------------------------------

SELECT
    merchant_id AS "Merchant ID",
    CASE
        WHEN DAY_OF_WEEK(DATE_ADD('hour', 8, created_at)) BETWEEN 1 AND 5 THEN 'Weekday'
        ELSE 'Weekend'
    END AS "day type",
    day_of_week(date_add('hour', 8, created_at)) AS "day of week",
    COUNT(order_id) AS "Number of Transactions",
    SUM(net_amount) AS "Total Transaction Amount",
    AVG(net_amount) AS "Average Transaction Amount"
FROM
    datalake_etl_online.online_order
WHERE
    status IN ('SUCCESS', 'SETTLED', 'REFUNDED')
    AND order_category = 'SALE'
GROUP BY
    merchant_id,
    CASE
        WHEN DAY_OF_WEEK(DATE_ADD('hour', 8, created_at)) BETWEEN 1 AND 5 THEN 'Weekday'
        ELSE 'Weekend'
    END,
    DAY_OF_WEEK(DATE_ADD('hour', 8, created_at))
ORDER BY
    merchant_id;

----------------------------------------Topic 6 (offline) Average hourly transaction (by day type) ------------------------------

SELECT
    merchant_id AS "Merchant ID",
    CASE
        WHEN DAY_OF_WEEK(DATE_ADD('hour', 8, created_at)) BETWEEN 1 AND 5 THEN 'Weekday'
        ELSE 'Weekend'
    END AS "day type",
    day_of_week(date_add('hour', 8, created_at)) AS "day of week",
    HOUR(DATE_ADD('hour', 8, created_at)) AS "Hour of Day",
    COUNT(payment_id) AS "Number of Transactions",
    SUM(net_amount) AS "Total Transaction Amount",
    AVG(net_amount) AS "Average Transaction Amount"
FROM
    datalake_etl_offline.offline_payment
WHERE
    status IN ('SUCCESS', 'REFUNDED')
    AND transaction_category = 'SALE'
GROUP BY
    merchant_id,
    CASE
        WHEN DAY_OF_WEEK(DATE_ADD('hour', 8, created_at)) BETWEEN 1 AND 5 THEN 'Weekday'
        ELSE 'Weekend'
    END,
    DAY_OF_WEEK(DATE_ADD('hour', 8, created_at)),
    HOUR(DATE_ADD('hour', 8, created_at))
ORDER BY
    merchant_id;

-----------------------------------Topic 6 (online) Average hourly transaction (by day type) ------------------------

SELECT
    merchant_id AS "Merchant ID",
    CASE
        WHEN DAY_OF_WEEK(DATE_ADD('hour', 8, created_at)) BETWEEN 1 AND 5 THEN 'Weekday'
        ELSE 'Weekend'
    END AS "day type",
    day_of_week(date_add('hour', 8, created_at)) AS "day of week",
    HOUR(DATE_ADD('hour', 8, created_at)) AS "Hour of Day",
    COUNT(order_id) AS "Number of Transactions",
    SUM(net_amount) AS "Total Transaction Amount",
    AVG(net_amount) AS "Average Transaction Amount"
FROM
    datalake_etl_online.online_order
WHERE
    status IN ('SUCCESS', 'SETTLED', 'REFUNDED')
    AND order_category = 'SALE'
GROUP BY
    merchant_id,
    CASE
        WHEN DAY_OF_WEEK(DATE_ADD('hour', 8, created_at)) BETWEEN 1 AND 5 THEN 'Weekday'
        ELSE 'Weekend'
    END,
    DAY_OF_WEEK(DATE_ADD('hour', 8, created_at)),
    HOUR(DATE_ADD('hour', 8, created_at))
ORDER BY
    merchant_id;


-----------------------------------------Topic 6 hourly (online) ----------------------------

SELECT
    merchant_id AS "Merchant ID",
    HOUR(DATE_ADD('hour', 8, created_at)) AS "Hour of Day",
    COUNT(order_id) AS "Number of Transactions",
    SUM(net_amount) AS "Total Transaction Amount",
    AVG(net_amount) AS "Average Transaction Amount"
FROM
    datalake_etl_online.online_order
WHERE
    status IN ('SUCCESS', 'SETTLED', 'REFUNDED')
    AND order_category = 'SALE'
GROUP BY
    merchant_id,
    HOUR(DATE_ADD('hour', 8, created_at))
ORDER BY
    merchant_id;

----------------------------------------------Topic 6 hourly (offline) ----------------------------------

SELECT
    merchant_id AS "Merchant ID",
    HOUR(DATE_ADD('hour', 8, created_at)) AS "Hour of Day",
    COUNT(payment_id) AS "Number of Transactions",
    SUM(net_amount) AS "Total Transaction Amount",
    AVG(net_amount) AS "Average Transaction Amount"
FROM
    datalake_etl_offline.offline_payment
WHERE
    status IN ('SUCCESS', 'REFUNDED')
    AND transaction_category = 'SALE'
GROUP BY
    merchant_id,
    HOUR(DATE_ADD('hour', 8, created_at))
ORDER BY
    merchant_id;