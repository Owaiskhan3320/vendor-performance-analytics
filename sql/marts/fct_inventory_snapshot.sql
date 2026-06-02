WITH combined AS (
    SELECT
        inventory_id,
        store_id,
        brand_id,
        snapshot_date,
        snapshot_type,
        on_hand_units,
        retail_unit_price
    FROM stg_begin_inventory
    UNION ALL
    SELECT
        inventory_id,
        store_id,
        brand_id,
        snapshot_date,
        snapshot_type,
        on_hand_units,
        retail_unit_price
    FROM stg_end_inventory
)
SELECT
    ROW_NUMBER() OVER (
        ORDER BY inventory_id, store_id, brand_id, snapshot_date, snapshot_type
    ) AS inventory_snapshot_id,
    inventory_id,
    store_id,
    brand_id,
    snapshot_date,
    snapshot_type,
    on_hand_units,
    retail_unit_price,
    ROUND(on_hand_units * retail_unit_price, 2) AS retail_inventory_value
FROM combined

