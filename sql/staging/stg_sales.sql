SELECT
    InventoryId AS inventory_id,
    CAST(Store AS INTEGER) AS store_id,
    CAST(Brand AS INTEGER) AS brand_id,
    TRIM(Description) AS product_description,
    TRIM(Size) AS size,
    CAST(SalesQuantity AS INTEGER) AS sales_quantity,
    CAST(SalesDollars AS REAL) AS sales_dollars,
    CAST(SalesPrice AS REAL) AS sales_unit_price,
    DATE(SalesDate) AS sales_date,
    CAST(Volume AS REAL) AS volume_ml,
    CAST(Classification AS INTEGER) AS classification,
    CAST(ExciseTax AS REAL) AS excise_tax_dollars,
    CAST(VendorNo AS INTEGER) AS vendor_number,
    TRIM(VendorName) AS vendor_name,
    'sales' AS record_source
FROM sales
WHERE Brand IS NOT NULL
  AND VendorNo IS NOT NULL

