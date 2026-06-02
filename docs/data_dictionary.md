# Data Dictionary

## Raw source tables

### `begin_inventory`
- Grain: one store-brand inventory snapshot row at the beginning of the period
- Key fields: `InventoryId`, `Store`, `Brand`, `startDate`

### `end_inventory`
- Grain: one store-brand inventory snapshot row at the end of the period
- Key fields: `InventoryId`, `Store`, `Brand`, `endDate`

### `purchases`
- Grain: one purchase transaction line
- Key fields: `InventoryId`, `PONumber`, `VendorNumber`, `Brand`

### `purchase_prices`
- Grain: one brand reference record in the source dataset
- Key fields: `Brand`, `VendorNumber`

### `sales`
- Grain: one daily sales transaction row
- Key fields: `InventoryId`, `Store`, `Brand`, `SalesDate`

### `vendor_invoice`
- Grain: one vendor invoice row
- Key fields: `VendorNumber`, `PONumber`, `InvoiceDate`

## Modeled tables

### `dim_vendor`
- Grain: one row per vendor
- Primary key: `vendor_id`

### `dim_product`
- Grain: one row per brand / product
- Primary key: `product_id`

### `dim_store`
- Grain: one row per store
- Primary key: `store_id`

### `dim_date`
- Grain: one row per calendar date observed in the source system
- Primary key: `date_day`

### `fct_purchases`
- Grain: one purchase line in the cleaned model
- Primary key: `purchase_line_id`

### `fct_sales`
- Grain: one sales line in the cleaned model
- Primary key: `sales_line_id`

### `fct_vendor_freight`
- Grain: one vendor invoice freight row
- Primary key: `vendor_freight_id`

### `fct_inventory_snapshot`
- Grain: one store-brand-date inventory snapshot
- Primary key: `inventory_snapshot_id`

### `mart_vendor_performance`
- Grain: one vendor-brand row
- Purpose: final reporting table for vendor purchase, sales, freight, and inventory analysis
