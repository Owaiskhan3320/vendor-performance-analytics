WITH source_total AS (
    SELECT ROUND(SUM(CAST(Freight AS REAL)), 2) AS amount
    FROM vendor_invoice
),
fact_total AS (
    SELECT ROUND(SUM(freight_dollars), 2) AS amount
    FROM fct_vendor_freight
),
mart_total AS (
    SELECT ROUND(SUM(allocated_freight_dollars), 2) AS amount
    FROM mart_vendor_performance
)
SELECT
    'source_vs_fact_freight' AS check_name,
    source_total.amount AS source_amount,
    fact_total.amount AS modeled_amount,
    ROUND(fact_total.amount - source_total.amount, 2) AS difference
FROM source_total
CROSS JOIN fact_total
WHERE ABS(fact_total.amount - source_total.amount) > 0.01

UNION ALL

SELECT
    'source_vs_mart_allocated_freight' AS check_name,
    source_total.amount AS source_amount,
    mart_total.amount AS modeled_amount,
    ROUND(mart_total.amount - source_total.amount, 2) AS difference
FROM source_total
CROSS JOIN mart_total
WHERE ABS(mart_total.amount - source_total.amount) > 0.05

