# Vendor Performance Analytics

This project analyzes vendor performance using purchase, sales, freight, and inventory data stored in SQLite.

## Simple explanation

I loaded six CSV files into SQLite, cleaned them with SQL, built fact and dimension tables, created a final vendor performance table, checked the totals against the source data, and used that table for queries and reporting.

## Project goal

The main goal is to answer business questions such as:

- Which vendors bring the most sales?
- Which vendors account for most of the purchase spend?
- How much inventory cost is tied up in slow-moving products?
- Which stores depend too much on one vendor?

## Data

Raw files are stored in `data/data/`:

- `begin_inventory.csv`
- `end_inventory.csv`
- `purchases.csv`
- `purchase_prices.csv`
- `sales.csv`
- `vendor_invoice.csv`

## How it works

- raw CSV files are loaded into SQLite with a script
- staging SQL cleans types, dates, and text fields
- fact and dimension tables are built in SQL
- freight is handled separately and then allocated into the final mart
- SQL checks are run to make sure the totals match the source data
- the final mart feeds named queries and a local HTML report

## Data flow

```text
CSV files
  -> raw SQLite tables
  -> staging tables
  -> dimensions and facts
  -> mart_vendor_performance
  -> analysis queries and dashboard
```

## Main tables

- `dim_vendor`
- `dim_product`
- `dim_store`
- `dim_date`
- `fct_purchases`
- `fct_sales`
- `fct_vendor_freight`
- `fct_inventory_snapshot`
- `mart_vendor_performance`

The final mart is one row per `vendor_id + product_id`.

## Freight handling

Freight is handled separately so the final vendor-product mart stays safe to aggregate:

- freight stays separate in `fct_vendor_freight`
- the final mart allocates freight by each product's share of vendor purchase dollars

## Validation

The project includes SQL checks for:

- purchase dollar reconciliation
- sales dollar reconciliation
- freight reconciliation
- duplicate and null primary keys
- missing dimension relationships
- duplicate rows in the final mart

These checks live in [tests/sql](./tests/sql).

## Current results

From the rebuilt `mart_vendor_performance` table:

- purchase dollars: `321,900,765.53`
- sales dollars: `452,062,952.02`
- allocated freight: `1,640,474.69`
- vendors: `129`
- products: `11,503`
- rows in mart: `11,538`
- top 10 vendors account for `65.33%` of purchase dollars

## Main findings

- `DIAGEO NORTH AMERICA INC` is the top vendor by sales and purchase dollars.
- Purchase spend is concentrated across a small group of vendors.
- A large amount of inventory cost is tied up in a few vendors.
- Some stores depend heavily on one vendor.

## Files to look at first

- [src/load_raw_to_sqlite.py](./src/load_raw_to_sqlite.py)
- [src/build_vendor_mart.py](./src/build_vendor_mart.py)
- [sql/marts/mart_vendor_performance.sql](./sql/marts/mart_vendor_performance.sql)
- [src/run_reconciliation.py](./src/run_reconciliation.py)
- [src/query_mart.py](./src/query_mart.py)
- [src/build_dashboard_html.py](./src/build_dashboard_html.py)

Older notebook files from the earlier workflow are kept in [archive](./archive).

## How to run

### 1. Install dependencies

```powershell
pip install -r requirements.txt
```

### 2. Load raw CSV files

```powershell
python .\src\load_raw_to_sqlite.py
```

### 3. Build the modeled tables

```powershell
python .\src\build_vendor_mart.py
```

### 4. Run checks

```powershell
python .\src\run_reconciliation.py
```

### 5. Build the report

```powershell
python .\src\build_dashboard_html.py
```

Output:

- `dashboard/vendor_performance_dashboard.html`

## Query examples

List available queries:

```powershell
python .\src\query_mart.py --list
```

Run one query:

```powershell
python .\src\query_mart.py --query top_vendor_sales --limit 10
```

## Notes

- The main workflow is in `src/` and `sql/`.
- This project fits data analytics / BI better than machine learning.
- The HTML report is useful for presentation, but the core project is the SQL and Python pipeline.
