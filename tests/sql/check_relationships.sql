SELECT 'fct_purchases missing dim_vendor' AS issue, COUNT(*) AS offending_rows
FROM fct_purchases fp
LEFT JOIN dim_vendor dv
    ON fp.vendor_number = dv.vendor_id
WHERE dv.vendor_id IS NULL
HAVING COUNT(*) > 0

UNION ALL

SELECT 'fct_purchases missing dim_product', COUNT(*) AS offending_rows
FROM fct_purchases fp
LEFT JOIN dim_product dp
    ON fp.brand_id = dp.product_id
WHERE dp.product_id IS NULL
HAVING COUNT(*) > 0

UNION ALL

SELECT 'fct_purchases missing dim_store', COUNT(*) AS offending_rows
FROM fct_purchases fp
LEFT JOIN dim_store ds
    ON fp.store_id = ds.store_id
WHERE ds.store_id IS NULL
HAVING COUNT(*) > 0

UNION ALL

SELECT 'fct_sales missing dim_vendor', COUNT(*) AS offending_rows
FROM fct_sales fs
LEFT JOIN dim_vendor dv
    ON fs.vendor_number = dv.vendor_id
WHERE dv.vendor_id IS NULL
HAVING COUNT(*) > 0

UNION ALL

SELECT 'fct_sales missing dim_product', COUNT(*) AS offending_rows
FROM fct_sales fs
LEFT JOIN dim_product dp
    ON fs.brand_id = dp.product_id
WHERE dp.product_id IS NULL
HAVING COUNT(*) > 0

UNION ALL

SELECT 'fct_sales missing dim_store', COUNT(*) AS offending_rows
FROM fct_sales fs
LEFT JOIN dim_store ds
    ON fs.store_id = ds.store_id
WHERE ds.store_id IS NULL
HAVING COUNT(*) > 0

UNION ALL

SELECT 'fct_vendor_freight missing dim_vendor', COUNT(*) AS offending_rows
FROM fct_vendor_freight ff
LEFT JOIN dim_vendor dv
    ON ff.vendor_number = dv.vendor_id
WHERE dv.vendor_id IS NULL
HAVING COUNT(*) > 0

UNION ALL

SELECT 'fct_inventory_snapshot missing dim_product', COUNT(*) AS offending_rows
FROM fct_inventory_snapshot fi
LEFT JOIN dim_product dp
    ON fi.brand_id = dp.product_id
WHERE dp.product_id IS NULL
HAVING COUNT(*) > 0

UNION ALL

SELECT 'fct_inventory_snapshot missing dim_store', COUNT(*) AS offending_rows
FROM fct_inventory_snapshot fi
LEFT JOIN dim_store ds
    ON fi.store_id = ds.store_id
WHERE ds.store_id IS NULL
HAVING COUNT(*) > 0

