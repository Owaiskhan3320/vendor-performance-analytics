SELECT
    InventoryId AS inventory_id,
    CAST(Store AS INTEGER) AS store_id,
    TRIM(City) AS city,
    CAST(Brand AS INTEGER) AS brand_id,
    TRIM(Description) AS product_description,
    TRIM(Size) AS size,
    CAST(onHand AS INTEGER) AS on_hand_units,
    CAST(Price AS REAL) AS retail_unit_price,
    DATE(endDate) AS snapshot_date,
    'end' AS snapshot_type
FROM end_inventory
WHERE Brand IS NOT NULL

