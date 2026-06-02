WITH purchase_month AS (
    SELECT
        SUBSTR(po_date, 1, 7) AS year_month,
        SUM(purchase_dollars) AS purchase_dollars
    FROM fct_purchases
    WHERE po_date IS NOT NULL
    GROUP BY SUBSTR(po_date, 1, 7)
),
sales_month AS (
    SELECT
        SUBSTR(sales_date, 1, 7) AS year_month,
        SUM(sales_dollars) AS sales_dollars
    FROM fct_sales
    WHERE sales_date IS NOT NULL
    GROUP BY SUBSTR(sales_date, 1, 7)
),
month_universe AS (
    SELECT year_month FROM purchase_month
    UNION
    SELECT year_month FROM sales_month
)
SELECT
    m.year_month,
    ROUND(COALESCE(p.purchase_dollars, 0), 2) AS purchase_dollars,
    ROUND(COALESCE(s.sales_dollars, 0), 2) AS sales_dollars
FROM month_universe m
LEFT JOIN purchase_month p
    ON m.year_month = p.year_month
LEFT JOIN sales_month s
    ON m.year_month = s.year_month
ORDER BY m.year_month

