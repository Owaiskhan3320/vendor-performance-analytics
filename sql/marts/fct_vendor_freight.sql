SELECT
    ROW_NUMBER() OVER (
        ORDER BY vendor_number, po_number, invoice_date, freight_dollars
    ) AS vendor_freight_id,
    vendor_number,
    po_number,
    invoice_date,
    po_date,
    pay_date,
    invoice_quantity,
    invoice_dollars,
    freight_dollars,
    approval_status
FROM stg_vendor_invoice

