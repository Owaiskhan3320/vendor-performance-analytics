WITH source_total AS (
    SELECT ROUND(SUM(CAST(SalesDollars AS REAL)), 2) AS amount
    FROM sales
),
fact_total AS (
    SELECT ROUND(SUM(sales_dollars), 2) AS amount
    FROM fct_sales
),
mart_total AS (
    SELECT ROUND(SUM(total_sales_dollars), 2) AS amount
    FROM mart_vendor_performance
)
SELECT
    'source_vs_fact_sales_dollars' AS check_name,
    source_total.amount AS source_amount,
    fact_total.amount AS modeled_amount,
    ROUND(fact_total.amount - source_total.amount, 2) AS difference
FROM source_total
CROSS JOIN fact_total
WHERE ABS(fact_total.amount - source_total.amount) > 0.01

UNION ALL

SELECT
    'source_vs_mart_sales_dollars' AS check_name,
    source_total.amount AS source_amount,
    mart_total.amount AS modeled_amount,
    ROUND(mart_total.amount - source_total.amount, 2) AS difference
FROM source_total
CROSS JOIN mart_total
WHERE ABS(mart_total.amount - source_total.amount) > 0.01

