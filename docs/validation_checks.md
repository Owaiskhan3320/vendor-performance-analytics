# Validation Checks

The SQL files in `tests/sql/` return zero rows when everything is correct.

## Checks included

- `reconcile_purchase_dollars.sql`
  - source purchases vs `fct_purchases`
  - source purchases vs `mart_vendor_performance`

- `reconcile_sales_dollars.sql`
  - source sales vs `fct_sales`
  - source sales vs `mart_vendor_performance`

- `reconcile_freight.sql`
  - source freight vs `fct_vendor_freight`
  - source freight vs allocated freight in `mart_vendor_performance`

- `check_primary_keys.sql`
  - null and duplicate checks for dimension and fact primary keys

- `check_relationships.sql`
  - orphan checks from facts to dimensions

- `check_mart_grain.sql`
  - duplicate vendor-brand rows in the final mart

## How to run

```text
python src/run_reconciliation.py
```

The script prints each check and stops with an error if any test fails.
