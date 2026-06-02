WITH purchase_summary AS (
    SELECT
        vendor_number,
        brand_id,
        SUM(purchase_quantity) AS total_purchase_quantity,
        ROUND(SUM(purchase_dollars), 2) AS total_purchase_dollars,
        ROUND(SUM(purchase_dollars) / NULLIF(SUM(purchase_quantity), 0), 4) AS avg_purchase_unit_cost,
        MIN(po_date) AS first_purchase_date,
        MAX(po_date) AS last_purchase_date
    FROM fct_purchases
    GROUP BY vendor_number, brand_id
),
sales_summary AS (
    SELECT
        vendor_number,
        brand_id,
        SUM(sales_quantity) AS total_sales_quantity,
        ROUND(SUM(sales_dollars), 2) AS total_sales_dollars,
        ROUND(SUM(excise_tax_dollars), 2) AS total_excise_tax_dollars,
        ROUND(SUM(sales_dollars) / NULLIF(SUM(sales_quantity), 0), 4) AS avg_sales_unit_price,
        MIN(sales_date) AS first_sales_date,
        MAX(sales_date) AS last_sales_date
    FROM fct_sales
    GROUP BY vendor_number, brand_id
),
vendor_freight AS (
    SELECT
        vendor_number,
        ROUND(SUM(freight_dollars), 2) AS vendor_freight_total
    FROM fct_vendor_freight
    GROUP BY vendor_number
),
vendor_purchase_totals AS (
    SELECT
        vendor_number,
        SUM(total_purchase_dollars) AS vendor_purchase_total
    FROM purchase_summary
    GROUP BY vendor_number
),
inventory_summary AS (
    SELECT
        dp.default_vendor_number AS vendor_number,
        fi.brand_id,
        SUM(CASE WHEN fi.snapshot_type = 'begin' THEN fi.on_hand_units ELSE 0 END) AS begin_on_hand_units,
        SUM(CASE WHEN fi.snapshot_type = 'end' THEN fi.on_hand_units ELSE 0 END) AS end_on_hand_units,
        ROUND(SUM(CASE WHEN fi.snapshot_type = 'begin' THEN fi.retail_inventory_value ELSE 0 END), 2) AS begin_inventory_retail_value,
        ROUND(SUM(CASE WHEN fi.snapshot_type = 'end' THEN fi.retail_inventory_value ELSE 0 END), 2) AS end_inventory_retail_value
    FROM fct_inventory_snapshot fi
    LEFT JOIN dim_product dp
        ON fi.brand_id = dp.product_id
    GROUP BY dp.default_vendor_number, fi.brand_id
),
vendor_brand_universe AS (
    SELECT vendor_number, brand_id FROM purchase_summary
    UNION
    SELECT vendor_number, brand_id FROM sales_summary
    UNION
    SELECT vendor_number, brand_id FROM inventory_summary
),
finalized AS (
    SELECT
        u.vendor_number AS vendor_id,
        dv.vendor_name,
        u.brand_id AS product_id,
        dp.product_description,
        dp.size,
        dp.volume_ml,
        dp.classification,
        ps.first_purchase_date,
        ps.last_purchase_date,
        ss.first_sales_date,
        ss.last_sales_date,
        COALESCE(ps.total_purchase_quantity, 0) AS total_purchase_quantity,
        COALESCE(ps.total_purchase_dollars, 0) AS total_purchase_dollars,
        COALESCE(ps.avg_purchase_unit_cost, dp.default_purchase_unit_cost) AS avg_purchase_unit_cost,
        COALESCE(ss.total_sales_quantity, 0) AS total_sales_quantity,
        COALESCE(ss.total_sales_dollars, 0) AS total_sales_dollars,
        COALESCE(ss.avg_sales_unit_price, dp.list_price) AS avg_sales_unit_price,
        COALESCE(ss.total_excise_tax_dollars, 0) AS total_excise_tax_dollars,
        COALESCE(inv.begin_on_hand_units, 0) AS begin_on_hand_units,
        COALESCE(inv.end_on_hand_units, 0) AS end_on_hand_units,
        COALESCE(inv.begin_inventory_retail_value, 0) AS begin_inventory_retail_value,
        COALESCE(inv.end_inventory_retail_value, 0) AS end_inventory_retail_value,
        COALESCE(vf.vendor_freight_total, 0) AS vendor_freight_total,
        COALESCE(vpt.vendor_purchase_total, 0) AS vendor_purchase_total
    FROM vendor_brand_universe u
    LEFT JOIN purchase_summary ps
        ON u.vendor_number = ps.vendor_number
       AND u.brand_id = ps.brand_id
    LEFT JOIN sales_summary ss
        ON u.vendor_number = ss.vendor_number
       AND u.brand_id = ss.brand_id
    LEFT JOIN inventory_summary inv
        ON u.vendor_number = inv.vendor_number
       AND u.brand_id = inv.brand_id
    LEFT JOIN vendor_freight vf
        ON u.vendor_number = vf.vendor_number
    LEFT JOIN vendor_purchase_totals vpt
        ON u.vendor_number = vpt.vendor_number
    LEFT JOIN dim_vendor dv
        ON u.vendor_number = dv.vendor_id
    LEFT JOIN dim_product dp
        ON u.brand_id = dp.product_id
)
SELECT
    vendor_id,
    vendor_name,
    product_id,
    product_description,
    size,
    volume_ml,
    classification,
    first_purchase_date,
    last_purchase_date,
    first_sales_date,
    last_sales_date,
    total_purchase_quantity,
    total_purchase_dollars,
    avg_purchase_unit_cost,
    total_sales_quantity,
    total_sales_dollars,
    avg_sales_unit_price,
    total_excise_tax_dollars,
    begin_on_hand_units,
    end_on_hand_units,
    begin_inventory_retail_value,
    end_inventory_retail_value,
    vendor_freight_total,
    CASE
        WHEN vendor_purchase_total > 0 THEN vendor_freight_total * (total_purchase_dollars / vendor_purchase_total)
        ELSE 0
    END AS allocated_freight_dollars,
    ROUND(total_sales_dollars - total_purchase_dollars, 2) AS gross_profit_before_freight,
    ROUND(
        (total_sales_dollars - total_purchase_dollars) -
        CASE
            WHEN vendor_purchase_total > 0 THEN vendor_freight_total * (total_purchase_dollars / vendor_purchase_total)
            ELSE 0
        END,
        2
    ) AS gross_profit_after_allocated_freight,
    ROUND(
        (
            (total_sales_dollars - total_purchase_dollars) -
            CASE
                WHEN vendor_purchase_total > 0 THEN vendor_freight_total * (total_purchase_dollars / vendor_purchase_total)
                ELSE 0
            END
        ) / NULLIF(total_sales_dollars, 0)
        * 100,
        2
    ) AS profit_margin_after_freight_pct,
    ROUND(total_sales_dollars / NULLIF(total_purchase_dollars, 0), 4) AS sales_to_purchase_ratio,
    ROUND(total_sales_quantity / NULLIF((begin_on_hand_units + end_on_hand_units) / 2.0, 0), 4) AS inventory_turnover_ratio,
    ROUND(end_on_hand_units * COALESCE(avg_purchase_unit_cost, 0), 2) AS estimated_unsold_inventory_cost
FROM finalized
