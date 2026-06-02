SELECT
    ROW_NUMBER() OVER (
        ORDER BY inventory_id, po_number, invoice_date, vendor_number, brand_id, purchase_dollars
    ) AS purchase_line_id,
    inventory_id,
    store_id,
    brand_id,
    vendor_number,
    po_number,
    po_date,
    receiving_date,
    invoice_date,
    pay_date,
    purchase_unit_cost,
    purchase_quantity,
    purchase_dollars,
    classification
FROM stg_purchases

