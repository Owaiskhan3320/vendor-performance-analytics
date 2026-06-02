SELECT
    ROUND(SUM(total_purchase_dollars), 2) AS purchase_dollars,
    ROUND(SUM(total_sales_dollars), 2) AS sales_dollars,
    ROUND(SUM(allocated_freight_dollars), 2) AS allocated_freight,
    ROUND(SUM(gross_profit_after_allocated_freight), 2) AS gross_profit_after_freight,
    ROUND(100.0 * SUM(gross_profit_after_allocated_freight) / NULLIF(SUM(total_sales_dollars), 0), 2) AS weighted_margin_pct,
    ROUND(SUM(estimated_unsold_inventory_cost), 2) AS unsold_inventory_cost,
    COUNT(DISTINCT vendor_id) AS vendors,
    COUNT(DISTINCT product_id) AS products,
    COUNT(*) AS mart_rows
FROM mart_vendor_performance

