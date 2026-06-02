WITH store_vendor AS (
    SELECT
        fp.store_id,
        dv.vendor_name,
        SUM(fp.purchase_dollars) AS purchase_dollars
    FROM fct_purchases fp
    JOIN dim_vendor dv
        ON fp.vendor_number = dv.vendor_id
    GROUP BY fp.store_id, dv.vendor_name
),
ranked AS (
    SELECT
        store_id,
        vendor_name,
        purchase_dollars,
        ROW_NUMBER() OVER (
            PARTITION BY store_id
            ORDER BY purchase_dollars DESC
        ) AS vendor_rank,
        SUM(purchase_dollars) OVER (PARTITION BY store_id) AS store_total
    FROM store_vendor
)
SELECT
    store_id,
    vendor_name,
    ROUND(purchase_dollars, 2) AS purchase_dollars,
    ROUND(100.0 * purchase_dollars / store_total, 2) AS dependency_pct
FROM ranked
WHERE vendor_rank = 1
ORDER BY dependency_pct DESC
LIMIT {{limit}}

