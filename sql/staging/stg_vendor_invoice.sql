SELECT
    CAST(VendorNumber AS INTEGER) AS vendor_number,
    TRIM(VendorName) AS vendor_name,
    DATE(InvoiceDate) AS invoice_date,
    CAST(PONumber AS INTEGER) AS po_number,
    DATE(PODate) AS po_date,
    DATE(PayDate) AS pay_date,
    CAST(Quantity AS INTEGER) AS invoice_quantity,
    CAST(Dollars AS REAL) AS invoice_dollars,
    CAST(Freight AS REAL) AS freight_dollars,
    NULLIF(TRIM(Approval), '') AS approval_status
FROM vendor_invoice
WHERE VendorNumber IS NOT NULL

