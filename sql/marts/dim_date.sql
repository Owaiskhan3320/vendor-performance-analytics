WITH all_dates AS (
    SELECT po_date AS date_day FROM stg_purchases WHERE po_date IS NOT NULL
    UNION
    SELECT receiving_date FROM stg_purchases WHERE receiving_date IS NOT NULL
    UNION
    SELECT invoice_date FROM stg_purchases WHERE invoice_date IS NOT NULL
    UNION
    SELECT pay_date FROM stg_purchases WHERE pay_date IS NOT NULL
    UNION
    SELECT sales_date FROM stg_sales WHERE sales_date IS NOT NULL
    UNION
    SELECT invoice_date FROM stg_vendor_invoice WHERE invoice_date IS NOT NULL
    UNION
    SELECT po_date FROM stg_vendor_invoice WHERE po_date IS NOT NULL
    UNION
    SELECT pay_date FROM stg_vendor_invoice WHERE pay_date IS NOT NULL
    UNION
    SELECT snapshot_date FROM stg_begin_inventory WHERE snapshot_date IS NOT NULL
    UNION
    SELECT snapshot_date FROM stg_end_inventory WHERE snapshot_date IS NOT NULL
)
SELECT
    date_day,
    CAST(STRFTIME('%Y', date_day) AS INTEGER) AS calendar_year,
    CAST(STRFTIME('%m', date_day) AS INTEGER) AS calendar_month,
    CAST(STRFTIME('%d', date_day) AS INTEGER) AS day_of_month,
    CAST(STRFTIME('%w', date_day) AS INTEGER) AS day_of_week,
    STRFTIME('%Y-%m', date_day) AS year_month
FROM all_dates

