WITH vendor_procurement AS (
    SELECT
        vendor_name,
        SUM(total_purchase_dollars) AS purchase_dollars
    FROM mart_vendor_performance
    GROUP BY vendor_id, vendor_name
)
SELECT
    vendor_name,
    ROUND(purchase_dollars, 2) AS purchase_dollars,
    ROUND(100.0 * purchase_dollars / SUM(purchase_dollars) OVER (), 2) AS contribution_pct
FROM vendor_procurement
ORDER BY purchase_dollars DESC
LIMIT {{limit}}

