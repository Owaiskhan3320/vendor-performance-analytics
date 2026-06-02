SELECT
    InventoryId AS inventory_id,
    CAST(Store AS INTEGER) AS store_id,
    CAST(Brand AS INTEGER) AS brand_id,
    TRIM(Description) AS product_description,
    TRIM(Size) AS size,
    CAST(VendorNumber AS INTEGER) AS vendor_number,
    TRIM(VendorName) AS vendor_name,
    CAST(PONumber AS INTEGER) AS po_number,
    DATE(PODate) AS po_date,
    DATE(ReceivingDate) AS receiving_date,
    DATE(InvoiceDate) AS invoice_date,
    DATE(PayDate) AS pay_date,
    CAST(PurchasePrice AS REAL) AS purchase_unit_cost,
    CAST(Quantity AS INTEGER) AS purchase_quantity,
    CAST(Dollars AS REAL) AS purchase_dollars,
    CAST(Classification AS INTEGER) AS classification,
    'purchases' AS record_source
FROM purchases
WHERE Brand IS NOT NULL
  AND VendorNumber IS NOT NULL

