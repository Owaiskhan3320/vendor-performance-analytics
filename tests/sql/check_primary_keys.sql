SELECT 'dim_vendor.vendor_id_null' AS issue, COUNT(*) AS offending_rows
FROM dim_vendor
WHERE vendor_id IS NULL
HAVING COUNT(*) > 0

UNION ALL

SELECT 'dim_vendor.vendor_id_duplicate', COUNT(*) AS offending_rows
FROM (
    SELECT vendor_id
    FROM dim_vendor
    GROUP BY vendor_id
    HAVING COUNT(*) > 1
)
HAVING COUNT(*) > 0

UNION ALL

SELECT 'dim_product.product_id_null', COUNT(*) AS offending_rows
FROM dim_product
WHERE product_id IS NULL
HAVING COUNT(*) > 0

UNION ALL

SELECT 'dim_product.product_id_duplicate', COUNT(*) AS offending_rows
FROM (
    SELECT product_id
    FROM dim_product
    GROUP BY product_id
    HAVING COUNT(*) > 1
)
HAVING COUNT(*) > 0

UNION ALL

SELECT 'dim_store.store_id_null', COUNT(*) AS offending_rows
FROM dim_store
WHERE store_id IS NULL
HAVING COUNT(*) > 0

UNION ALL

SELECT 'dim_store.store_id_duplicate', COUNT(*) AS offending_rows
FROM (
    SELECT store_id
    FROM dim_store
    GROUP BY store_id
    HAVING COUNT(*) > 1
)
HAVING COUNT(*) > 0

UNION ALL

SELECT 'dim_date.date_day_null', COUNT(*) AS offending_rows
FROM dim_date
WHERE date_day IS NULL
HAVING COUNT(*) > 0

UNION ALL

SELECT 'dim_date.date_day_duplicate', COUNT(*) AS offending_rows
FROM (
    SELECT date_day
    FROM dim_date
    GROUP BY date_day
    HAVING COUNT(*) > 1
)
HAVING COUNT(*) > 0

UNION ALL

SELECT 'fct_purchases.purchase_line_id_null', COUNT(*) AS offending_rows
FROM fct_purchases
WHERE purchase_line_id IS NULL
HAVING COUNT(*) > 0

UNION ALL

SELECT 'fct_purchases.purchase_line_id_duplicate', COUNT(*) AS offending_rows
FROM (
    SELECT purchase_line_id
    FROM fct_purchases
    GROUP BY purchase_line_id
    HAVING COUNT(*) > 1
)
HAVING COUNT(*) > 0

UNION ALL

SELECT 'fct_sales.sales_line_id_null', COUNT(*) AS offending_rows
FROM fct_sales
WHERE sales_line_id IS NULL
HAVING COUNT(*) > 0

UNION ALL

SELECT 'fct_sales.sales_line_id_duplicate', COUNT(*) AS offending_rows
FROM (
    SELECT sales_line_id
    FROM fct_sales
    GROUP BY sales_line_id
    HAVING COUNT(*) > 1
)
HAVING COUNT(*) > 0

UNION ALL

SELECT 'fct_vendor_freight.vendor_freight_id_null', COUNT(*) AS offending_rows
FROM fct_vendor_freight
WHERE vendor_freight_id IS NULL
HAVING COUNT(*) > 0

UNION ALL

SELECT 'fct_vendor_freight.vendor_freight_id_duplicate', COUNT(*) AS offending_rows
FROM (
    SELECT vendor_freight_id
    FROM fct_vendor_freight
    GROUP BY vendor_freight_id
    HAVING COUNT(*) > 1
)
HAVING COUNT(*) > 0

UNION ALL

SELECT 'fct_inventory_snapshot.inventory_snapshot_id_null', COUNT(*) AS offending_rows
FROM fct_inventory_snapshot
WHERE inventory_snapshot_id IS NULL
HAVING COUNT(*) > 0

UNION ALL

SELECT 'fct_inventory_snapshot.inventory_snapshot_id_duplicate', COUNT(*) AS offending_rows
FROM (
    SELECT inventory_snapshot_id
    FROM fct_inventory_snapshot
    GROUP BY inventory_snapshot_id
    HAVING COUNT(*) > 1
)
HAVING COUNT(*) > 0

