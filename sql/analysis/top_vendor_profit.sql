SELECT
    vendor_name,
    ROUND(SUM(gross_profit_after_allocated_freight), 2) AS gross_profit_after_freight,
    ROUND(
        100.0 * SUM(gross_profit_after_allocated_freight) / NULLIF(SUM(total_sales_dollars), 0),
        2
    ) AS weighted_margin_pct
FROM mart_vendor_performance
GROUP BY vendor_id, vendor_name
ORDER BY gross_profit_after_freight DESC
LIMIT {{limit}}
