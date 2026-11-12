/* Read-only Q18 comparison: raw PSA source vs DWH vs Data Mart.
   Expected scope: purchase date 2017-01-01 through 2018-08-31. */
WITH source_scope_orders AS (
    SELECT
        TRIM(o.order_id) AS order_id,
        STR_TO_DATE(NULLIF(TRIM(o.order_purchase_timestamp), ''), '%Y-%m-%d %H:%i:%s') AS purchase_ts,
        STR_TO_DATE(NULLIF(TRIM(o.order_delivered_carrier_date), ''), '%Y-%m-%d %H:%i:%s') AS carrier_ts
    FROM olist_psa_test.psa_orders o
    WHERE o.etl_run_id = (SELECT MAX(etl_run_id) FROM olist_psa_test.psa_orders)
      AND DATE(STR_TO_DATE(NULLIF(TRIM(o.order_purchase_timestamp), ''), '%Y-%m-%d %H:%i:%s'))
          BETWEEN '2017-01-01' AND '2018-08-31'
)
SELECT 'PSA source — Q18 in scope' AS population, COUNT(*) AS q18_rows
FROM source_scope_orders
WHERE carrier_ts IS NOT NULL AND carrier_ts < purchase_ts
UNION ALL
SELECT 'DWH — Q18 with is_in_scope=1', COUNT(*)
FROM olist_dwh_test.dwh_order
WHERE is_in_scope = 1 AND dq_carrier_before_purchase = 1
UNION ALL
SELECT 'Data Mart — Q18 fact rows', SUM(dq_carrier_before_purchase = 1)
FROM olist_dm_test.fact_order_fulfillment;

SELECT d.order_id, d.purchase_ts, d.carrier_ts, d.is_in_scope,
       d.dq_carrier_before_purchase,
       CASE WHEN d.carrier_ts IS NOT NULL AND d.carrier_ts < d.purchase_ts
            THEN 'SOURCE_RULE_TRUE' ELSE 'SOURCE_RULE_FALSE' END AS recalculated_q18
FROM olist_dwh_test.dwh_order d
WHERE d.is_in_scope = 1 AND d.dq_carrier_before_purchase = 1
ORDER BY d.purchase_ts, d.order_id;
