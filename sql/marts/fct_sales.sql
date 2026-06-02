SELECT
    ROW_NUMBER() OVER (
        ORDER BY inventory_id, sales_date, store_id, vendor_number, brand_id, sales_dollars
    ) AS sales_line_id,
    inventory_id,
    store_id,
    brand_id,
    vendor_number,
    sales_date,
    sales_quantity,
    sales_dollars,
    sales_unit_price,
    volume_ml,
    classification,
    excise_tax_dollars
FROM stg_sales

