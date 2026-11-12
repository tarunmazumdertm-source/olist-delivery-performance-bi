/*
GR05 Olist - Final Data Mart Audit V2 (project-scope source reconciliation)
Purpose: read-only validation of the existing TEST databases.
Run against local MySQL 8.4. This script does not INSERT, UPDATE, DELETE, DROP, or ALTER.
Expected Data Mart baseline: ETL run 12; approved purchase scope 2017-01-01 to 2018-08-31.
*/

SELECT 'A. DATA MART TABLE POPULATIONS' AS audit_section;

SELECT check_name, actual_value, expected_value,
       CASE WHEN actual_value = expected_value THEN 'PASS' ELSE 'CHECK' END AS result
FROM (
    SELECT 'fact_order_fulfillment rows (all in-scope orders)' AS check_name,
           COUNT(*) AS actual_value, 99092 AS expected_value
    FROM olist_dm.fact_order_fulfillment
    UNION ALL
    SELECT 'fact_sales_item rows (all in-scope order items)', COUNT(*), 112279
    FROM olist_dm.fact_sales_item
    UNION ALL
    SELECT 'fact_payment rows (all in-scope payment lines)', COUNT(*), 103520
    FROM olist_dm.fact_payment
    UNION ALL
    SELECT 'fact_review rows (all valid reviews for in-scope orders)', COUNT(*), 98879
    FROM olist_dm.fact_review
    UNION ALL
    SELECT 'dim_customer real members (unknown key excluded)', COUNT(*), 95774
    FROM olist_dm.dim_customer WHERE customer_key <> -1
    UNION ALL
    SELECT 'dim_location real members (unknown key excluded)', COUNT(*), 15243
    FROM olist_dm.dim_location WHERE location_key <> -1
    UNION ALL
    SELECT 'dim_seller real members (unknown key excluded)', COUNT(*), 3095
    FROM olist_dm.dim_seller WHERE seller_key <> -1
    UNION ALL
    SELECT 'dim_category real members (unknown key excluded)', COUNT(*), 74
    FROM olist_dm.dim_category WHERE category_key <> -1
    UNION ALL
    SELECT 'dim_product real members (unknown key excluded)', COUNT(*), 32951
    FROM olist_dm.dim_product WHERE product_key <> -1
) AS populations;

SELECT 'B. KPI REGRESSION CHECKS' AS audit_section;

WITH kpi_values AS (
    SELECT 'K01' AS kpi_id, 'GMV (BRL)' AS kpi_name,
           ROUND(SUM(item_price), 2) AS actual_value,
           CAST(13449529.68 AS DECIMAL(18,2)) AS expected_value
    FROM olist_dm.fact_sales_item
    WHERE is_sales_eligible = 1

    UNION ALL
    SELECT 'K02', 'Eligible orders',
           CAST(COUNT(DISTINCT order_id) AS DECIMAL(18,2)),
           CAST(97910.00 AS DECIMAL(18,2))
    FROM olist_dm.fact_order_fulfillment
    WHERE is_sales_eligible = 1

    UNION ALL
    SELECT 'K03', 'Average order value (BRL)',
           ROUND(
             (SELECT SUM(payment_value) FROM olist_dm.fact_payment WHERE is_sales_eligible = 1)
             / NULLIF((SELECT COUNT(DISTINCT order_id) FROM olist_dm.fact_order_fulfillment WHERE is_sales_eligible = 1), 0), 2
           ),
           CAST(160.22 AS DECIMAL(18,2))

    UNION ALL
    SELECT 'K04', 'On-time delivery rate (%)',
           ROUND(100.0 * SUM(is_on_time = 1) / NULLIF(COUNT(*), 0), 2),
           CAST(93.21 AS DECIMAL(18,2))
    FROM olist_dm.fact_order_fulfillment
    WHERE is_delivery_kpi_eligible = 1

    UNION ALL
    SELECT 'K05', 'Average delivery time (days)',
           ROUND(AVG(delivery_days), 2), CAST(12.54 AS DECIMAL(18,2))
    FROM olist_dm.fact_order_fulfillment
    WHERE is_delivery_kpi_eligible = 1

    UNION ALL
    SELECT 'K06', 'Average late days',
           ROUND(AVG(delay_days), 2), CAST(10.62 AS DECIMAL(18,2))
    FROM olist_dm.fact_order_fulfillment
    WHERE is_delivery_kpi_eligible = 1 AND is_late = 1

    UNION ALL
    SELECT 'K07', 'Seller dispatch compliance (%)',
           ROUND(100.0 * SUM(is_dispatch_on_time = 1) / NULLIF(COUNT(*), 0), 2),
           CAST(91.06 AS DECIMAL(18,2))
    FROM olist_dm.fact_order_fulfillment
    WHERE is_dispatch_on_time IS NOT NULL

    UNION ALL
    SELECT 'K08', 'Delivery estimate buffer (days)',
           ROUND(AVG(estimate_buffer_days), 2), CAST(11.81 AS DECIMAL(18,2))
    FROM olist_dm.fact_order_fulfillment
    WHERE is_delivery_kpi_eligible = 1

    UNION ALL
    SELECT 'K09', 'Average latest review score',
           ROUND(AVG(review_score), 2), CAST(4.09 AS DECIMAL(18,2))
    FROM olist_dm.fact_review
    WHERE is_latest_for_order = 1

    UNION ALL
    SELECT 'K10', 'Poor review rate (%)',
           ROUND(100.0 * SUM(review_score <= 2) / NULLIF(COUNT(*), 0), 2),
           CAST(14.63 AS DECIMAL(18,2))
    FROM olist_dm.fact_review

    UNION ALL
    SELECT 'K11', 'On-time vs late review gap (stars)',
           ROUND(
             AVG(CASE WHEN ds.status_code = 'ON_TIME' THEN r.review_score END)
             - AVG(CASE WHEN ds.status_code = 'LATE' THEN r.review_score END), 2
           ),
           CAST(2.02 AS DECIMAL(18,2))
    FROM olist_dm.fact_review r
    JOIN olist_dm.dim_delivery_status ds
      ON ds.delivery_status_key = r.delivery_status_key
    WHERE r.is_latest_for_order = 1

    UNION ALL
    SELECT 'K12', 'Repeat customer rate (%)',
           ROUND(100.0 * SUM(is_repeat_customer = 1) / NULLIF(SUM(eligible_order_count > 0), 0), 2),
           CAST(3.04 AS DECIMAL(18,2))
    FROM olist_dm.dim_customer
    WHERE customer_key <> -1
)
SELECT kpi_id, kpi_name, actual_value, expected_value,
       CASE WHEN actual_value = expected_value THEN 'MATCH' ELSE 'CHECK' END AS result
FROM kpi_values
ORDER BY kpi_id;

SELECT 'C. KNOWN DATA-QUALITY CONDITIONS — PROJECT SCOPE SOURCE RECONCILIATION' AS audit_section;

/*
  Compare each Data Mart DQ count with the same population in the raw PSA source:
  orders purchased 2017-01-01 through 2018-08-31.
  Shared review IDs are identified across the full source history, then only
  in-scope review rows are counted. This matches the DWH Q05 flagging rule.
*/
WITH
source_scope_orders AS (
    SELECT
        TRIM(o.order_id) AS order_id,
        STR_TO_DATE(NULLIF(TRIM(o.order_purchase_timestamp), ''), '%Y-%m-%d %H:%i:%s') AS purchase_ts,
        STR_TO_DATE(NULLIF(TRIM(o.order_delivered_carrier_date), ''), '%Y-%m-%d %H:%i:%s') AS carrier_ts,
        STR_TO_DATE(NULLIF(TRIM(o.order_delivered_customer_date), ''), '%Y-%m-%d %H:%i:%s') AS delivered_ts
    FROM olist_psa.psa_orders o
    WHERE o.etl_run_id = (SELECT MAX(etl_run_id) FROM olist_psa.psa_orders)
      AND DATE(STR_TO_DATE(NULLIF(TRIM(o.order_purchase_timestamp), ''), '%Y-%m-%d %H:%i:%s'))
          BETWEEN '2017-01-01' AND '2018-08-31'
),
source_scope_reviews AS (
    SELECT r.*
    FROM olist_psa.psa_reviews r
    JOIN source_scope_orders o ON o.order_id = TRIM(r.order_id)
    WHERE r.etl_run_id = (SELECT MAX(etl_run_id) FROM olist_psa.psa_reviews)
),
source_shared_review_ids AS (
    SELECT TRIM(review_id) AS review_id
    FROM olist_psa.psa_reviews
    WHERE etl_run_id = (SELECT MAX(etl_run_id) FROM olist_psa.psa_reviews)
    GROUP BY TRIM(review_id)
    HAVING COUNT(DISTINCT TRIM(order_id)) > 1
),
source_scope_payments AS (
    SELECT p.*
    FROM olist_psa.psa_payments p
    JOIN source_scope_orders o ON o.order_id = TRIM(p.order_id)
    WHERE p.etl_run_id = (SELECT MAX(etl_run_id) FROM olist_psa.psa_payments)
)
SELECT check_name, actual_value, source_expected_value,
       CASE WHEN actual_value = source_expected_value THEN 'MATCH' ELSE 'CHECK' END AS result,
       treatment
FROM (
    SELECT 'Eligible orders without item rows' AS check_name,
           COUNT(*) AS actual_value, 5 AS source_expected_value,
           'Retain in K02 and the order denominator for K03; do not delete.' AS treatment
    FROM olist_dm.fact_order_fulfillment
    WHERE is_sales_eligible = 1 AND COALESCE(item_count, 0) = 0

    UNION ALL
    SELECT 'Latest review rows in the project scope',
           SUM(is_latest_for_order = 1), 98330,
           'Use latest rows for K09 and K11; use all rows for K10.'
    FROM olist_dm.fact_review

    UNION ALL
    SELECT 'All valid review rows in the project scope',
           COUNT(*), 98879,
           'Retain every valid review row for K10.'
    FROM olist_dm.fact_review

    UNION ALL
    SELECT 'Poor reviews (score 1 or 2)',
           SUM(review_score <= 2), 14463,
           'Keep as valid customer feedback; classify as poor for K10.'
    FROM olist_dm.fact_review

    UNION ALL
    SELECT 'Review rows with empty comment message',
           (SELECT SUM(has_comment = 0) FROM olist_dm.fact_review),
           (SELECT COUNT(*) FROM source_scope_reviews
             WHERE review_comment_message IS NULL OR BINARY review_comment_message = BINARY ''),
           'Expected count is recalculated from raw PSA reviews for in-scope orders; whitespace-only text is retained.'

    UNION ALL
    SELECT 'Review rows flagged for shared review ID',
           (SELECT SUM(dq_shared_review_id = 1) FROM olist_dm.fact_review),
           (SELECT COUNT(*)
              FROM source_scope_reviews r
              JOIN source_shared_review_ids s
                ON BINARY TRIM(r.review_id) = BINARY s.review_id),
           'Shared IDs are detected across all source history; only in-scope review-order rows are counted here.'

    UNION ALL
    SELECT 'Orders with multiple review rows',
           (SELECT COUNT(*) FROM (
                SELECT order_key FROM olist_dm.fact_review
                GROUP BY order_key HAVING COUNT(*) > 1
            ) dm_multi),
           (SELECT COUNT(*) FROM (
                SELECT TRIM(order_id) AS order_id FROM source_scope_reviews
                GROUP BY TRIM(order_id) HAVING COUNT(*) > 1
            ) src_multi),
           'Count orders with multiple review rows within the project scope; retain every review row.'

    UNION ALL
    SELECT 'Zero-value payment rows flagged',
           (SELECT SUM(dq_zero_value = 1) FROM olist_dm.fact_payment),
           (SELECT COUNT(*) FROM source_scope_payments
             WHERE CAST(NULLIF(TRIM(payment_value), '') AS DECIMAL(10,2)) = 0),
           'Compare with zero-value payment lines attached to in-scope orders; retain the payment rows.'

    UNION ALL
    SELECT 'Carrier-before-purchase anomalies (Q18)',
           (SELECT SUM(dq_carrier_before_purchase = 1) FROM olist_dm.fact_order_fulfillment),
           (SELECT COUNT(*) FROM source_scope_orders
             WHERE carrier_ts IS NOT NULL AND carrier_ts < purchase_ts),
           'Must match a direct source-level calculation for in-scope orders. Investigate any difference before changing data.'

    UNION ALL
    SELECT 'Delivered-before-carrier anomalies (Q19)',
           (SELECT SUM(dq_delivered_before_carrier = 1) FROM olist_dm.fact_order_fulfillment),
           (SELECT COUNT(*) FROM source_scope_orders
             WHERE delivered_ts IS NOT NULL AND carrier_ts IS NOT NULL AND delivered_ts < carrier_ts),
           'Compare with the direct source-level calculation for in-scope orders; retain and flag anomalies.'
) AS dq_checks;

SELECT 'C2. Q18 SOURCE-TO-DWH-TO-DATAMART DIAGNOSTIC' AS audit_section;

WITH source_scope_orders AS (
    SELECT
        TRIM(o.order_id) AS order_id,
        STR_TO_DATE(NULLIF(TRIM(o.order_purchase_timestamp), ''), '%Y-%m-%d %H:%i:%s') AS purchase_ts,
        STR_TO_DATE(NULLIF(TRIM(o.order_delivered_carrier_date), ''), '%Y-%m-%d %H:%i:%s') AS carrier_ts
    FROM olist_psa.psa_orders o
    WHERE o.etl_run_id = (SELECT MAX(etl_run_id) FROM olist_psa.psa_orders)
      AND DATE(STR_TO_DATE(NULLIF(TRIM(o.order_purchase_timestamp), ''), '%Y-%m-%d %H:%i:%s'))
          BETWEEN '2017-01-01' AND '2018-08-31'
)
SELECT 'PSA source — Q18 in scope' AS population, COUNT(*) AS q18_rows
FROM source_scope_orders
WHERE carrier_ts IS NOT NULL AND carrier_ts < purchase_ts
UNION ALL
SELECT 'DWH — Q18 with is_in_scope=1', COUNT(*)
FROM olist_dwh.dwh_order
WHERE is_in_scope = 1 AND dq_carrier_before_purchase = 1
UNION ALL
SELECT 'Data Mart — Q18 fact rows', SUM(dq_carrier_before_purchase = 1)
FROM olist_dm.fact_order_fulfillment;

/* Return the specific DWH/Data Mart Q18 rows so a one-row scope mismatch can be traced. */
SELECT
    d.order_id,
    d.purchase_ts,
    d.carrier_ts,
    d.is_in_scope,
    d.dq_carrier_before_purchase,
    CASE
      WHEN d.carrier_ts IS NOT NULL AND d.carrier_ts < d.purchase_ts THEN 'SOURCE_RULE_TRUE'
      ELSE 'SOURCE_RULE_FALSE'
    END AS recalculated_q18
FROM olist_dwh.dwh_order d
WHERE d.is_in_scope = 1
  AND d.dq_carrier_before_purchase = 1
ORDER BY d.purchase_ts, d.order_id;

SELECT 'D. RELATIONSHIP INTEGRITY' AS audit_section;

SELECT check_name, orphan_rows,
       CASE WHEN orphan_rows = 0 THEN 'PASS' ELSE 'CHECK' END AS result
FROM (
    SELECT 'Fulfillment -> customer' AS check_name, COUNT(*) AS orphan_rows
    FROM olist_dm.fact_order_fulfillment f
    LEFT JOIN olist_dm.dim_customer d ON d.customer_key = f.customer_key
    WHERE d.customer_key IS NULL
    UNION ALL
    SELECT 'Fulfillment -> customer location', COUNT(*)
    FROM olist_dm.fact_order_fulfillment f
    LEFT JOIN olist_dm.dim_location d ON d.location_key = f.customer_location_key
    WHERE d.location_key IS NULL
    UNION ALL
    SELECT 'Sales item -> product', COUNT(*)
    FROM olist_dm.fact_sales_item f
    LEFT JOIN olist_dm.dim_product d ON d.product_key = f.product_key
    WHERE d.product_key IS NULL
    UNION ALL
    SELECT 'Sales item -> seller', COUNT(*)
    FROM olist_dm.fact_sales_item f
    LEFT JOIN olist_dm.dim_seller d ON d.seller_key = f.seller_key
    WHERE d.seller_key IS NULL
    UNION ALL
    SELECT 'Payment -> payment type', COUNT(*)
    FROM olist_dm.fact_payment f
    LEFT JOIN olist_dm.dim_payment_type d ON d.payment_type_key = f.payment_type_key
    WHERE d.payment_type_key IS NULL
    UNION ALL
    SELECT 'Review -> review score', COUNT(*)
    FROM olist_dm.fact_review f
    LEFT JOIN olist_dm.dim_review_score d ON d.review_score_key = f.review_score_key
    WHERE d.review_score_key IS NULL
) AS relationship_checks;

SELECT 'E. LATEST DATAMART ETL RUN' AS audit_section;
SELECT etl_run_id, run_status, started_at, finished_at, run_note
FROM olist_meta.etl_run
WHERE run_note LIKE 'Data Mart load;%'
ORDER BY etl_run_id DESC
LIMIT 1;

/* End of read-only audit. */
