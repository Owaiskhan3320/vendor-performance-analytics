WITH store_events AS (
    SELECT store_id, city FROM stg_begin_inventory
    UNION ALL
    SELECT store_id, city FROM stg_end_inventory
),
city_counts AS (
    SELECT
        store_id,
        city,
        COUNT(*) AS occurrence_count
    FROM store_events
    WHERE store_id IS NOT NULL
      AND city IS NOT NULL
    GROUP BY store_id, city
),
ranked_cities AS (
    SELECT
        store_id,
        city,
        ROW_NUMBER() OVER (
            PARTITION BY store_id
            ORDER BY occurrence_count DESC, city
        ) AS rn
    FROM city_counts
),
all_stores AS (
    SELECT DISTINCT store_id FROM stg_begin_inventory
    UNION
    SELECT DISTINCT store_id FROM stg_end_inventory
    UNION
    SELECT DISTINCT store_id FROM stg_purchases
    UNION
    SELECT DISTINCT store_id FROM stg_sales
)
SELECT
    s.store_id,
    rc.city
FROM all_stores s
LEFT JOIN ranked_cities rc
    ON s.store_id = rc.store_id
   AND rc.rn = 1
WHERE s.store_id IS NOT NULL

