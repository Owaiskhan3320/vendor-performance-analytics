SELECT
    CAST(Brand AS INTEGER) AS brand_id,
    TRIM(Description) AS product_description,
    CAST(Price AS REAL) AS list_price,
    TRIM(Size) AS size,
    CAST(Volume AS REAL) AS volume_ml,
    CAST(Classification AS INTEGER) AS classification,
    CAST(PurchasePrice AS REAL) AS default_purchase_unit_cost,
    CAST(VendorNumber AS INTEGER) AS vendor_number,
    TRIM(VendorName) AS vendor_name
FROM purchase_prices
WHERE Brand IS NOT NULL

