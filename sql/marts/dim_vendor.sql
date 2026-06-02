WITH vendor_events AS (
    SELECT vendor_number, vendor_name FROM stg_purchase_prices
    UNION ALL
    SELECT vendor_number, vendor_name FROM stg_purchases
    UNION ALL
    SELECT vendor_number, vendor_name FROM stg_sales
    UNION ALL
    SELECT vendor_number, vendor_name FROM stg_vendor_invoice
),
name_counts AS (
    SELECT
        vendor_number,
        vendor_name,
        COUNT(*) AS occurrence_count
    FROM vendor_events
    WHERE vendor_number IS NOT NULL
      AND vendor_name IS NOT NULL
    GROUP BY vendor_number, vendor_name
),
ranked_names AS (
    SELECT
        vendor_number,
        vendor_name,
        ROW_NUMBER() OVER (
            PARTITION BY vendor_number
            ORDER BY occurrence_count DESC, vendor_name
        ) AS rn
    FROM name_counts
)
SELECT
    vendor_number AS vendor_id,
    vendor_name
FROM ranked_names
WHERE rn = 1

