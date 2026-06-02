SELECT
    vendor_name,
    ROUND(SUM(estimated_unsold_inventory_cost), 2) AS unsold_cost,
    ROUND(AVG(inventory_turnover_ratio), 4) AS avg_inventory_turnover,
    ROUND(SUM(total_sales_dollars), 2) AS sales_dollars
FROM mart_vendor_performance
GROUP BY vendor_id, vendor_name
ORDER BY unsold_cost DESC
LIMIT {{limit}}

