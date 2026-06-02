WITH product_events AS (
    SELECT brand_id, product_description, size, vendor_number FROM stg_purchase_prices
    UNION ALL
    SELECT brand_id, product_description, size, vendor_number FROM stg_purchases
    UNION ALL
    SELECT brand_id, product_description, size, vendor_number FROM stg_sales
    UNION ALL
    SELECT brand_id, product_description, size, NULL AS vendor_number FROM stg_begin_inventory
    UNION ALL
    SELECT brand_id, product_description, size, NULL AS vendor_number FROM stg_end_inventory
),
name_counts AS (
    SELECT
        brand_id,
        product_description,
        size,
        COUNT(*) AS occurrence_count
    FROM product_events
    WHERE brand_id IS NOT NULL
      AND product_description IS NOT NULL
    GROUP BY brand_id, product_description, size
),
ranked_names AS (
    SELECT
        brand_id,
        product_description,
        size,
        occurrence_count,
        ROW_NUMBER() OVER (
            PARTITION BY brand_id
            ORDER BY occurrence_count DESC, product_description, size
        ) AS rn
    FROM name_counts
),
vendor_counts AS (
    SELECT
        brand_id,
        vendor_number,
        COUNT(*) AS occurrence_count
    FROM product_events
    WHERE brand_id IS NOT NULL
      AND vendor_number IS NOT NULL
    GROUP BY brand_id, vendor_number
),
ranked_vendors AS (
    SELECT
        brand_id,
        vendor_number,
        ROW_NUMBER() OVER (
            PARTITION BY brand_id
            ORDER BY occurrence_count DESC, vendor_number
        ) AS rn
    FROM vendor_counts
),
price_reference AS (
    SELECT
        brand_id,
        MAX(volume_ml) AS volume_ml,
        MAX(classification) AS classification,
        MAX(list_price) AS list_price,
        MAX(default_purchase_unit_cost) AS default_purchase_unit_cost
    FROM stg_purchase_prices
    GROUP BY brand_id
),
all_brands AS (
    SELECT DISTINCT brand_id FROM product_events WHERE brand_id IS NOT NULL
)
SELECT
    b.brand_id AS product_id,
    rn.product_description,
    rn.size,
    pr.volume_ml,
    pr.classification,
    pr.list_price,
    pr.default_purchase_unit_cost,
    rv.vendor_number AS default_vendor_number
FROM all_brands b
LEFT JOIN ranked_names rn
    ON b.brand_id = rn.brand_id
   AND rn.rn = 1
LEFT JOIN price_reference pr
    ON b.brand_id = pr.brand_id
LEFT JOIN ranked_vendors rv
    ON b.brand_id = rv.brand_id
   AND rv.rn = 1

