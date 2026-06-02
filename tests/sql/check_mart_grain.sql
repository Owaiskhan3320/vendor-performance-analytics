SELECT
    vendor_id,
    product_id,
    COUNT(*) AS duplicate_rows
FROM mart_vendor_performance
GROUP BY vendor_id, product_id
HAVING COUNT(*) > 1

