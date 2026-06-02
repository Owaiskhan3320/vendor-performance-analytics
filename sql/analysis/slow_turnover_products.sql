SELECT
    vendor_name,
    product_description,
    ROUND(total_purchase_dollars, 2) AS purchase_dollars,
    ROUND(total_sales_dollars, 2) AS sales_dollars,
    ROUND(inventory_turnover_ratio, 4) AS inventory_turnover_ratio,
    ROUND(estimated_unsold_inventory_cost, 2) AS estimated_unsold_inventory_cost
FROM mart_vendor_performance
WHERE total_purchase_dollars > 0
  AND COALESCE(inventory_turnover_ratio, 0) < 1
ORDER BY estimated_unsold_inventory_cost DESC
LIMIT {{limit}}

