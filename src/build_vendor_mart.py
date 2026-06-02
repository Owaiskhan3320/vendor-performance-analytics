from __future__ import annotations

import argparse
import logging
import sqlite3
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SQL_ROOT = PROJECT_ROOT / "sql"
DEFAULT_DB_PATH = PROJECT_ROOT / "inventory.db"
LOG_PATH = PROJECT_ROOT / "logs" / "build_vendor_mart.log"


RAW_INDEX_STATEMENTS = [
    "CREATE INDEX IF NOT EXISTS idx_purchases_vendor_brand ON purchases (VendorNumber, Brand)",
    "CREATE INDEX IF NOT EXISTS idx_purchases_store_brand ON purchases (Store, Brand)",
    "CREATE INDEX IF NOT EXISTS idx_sales_vendor_brand ON sales (VendorNo, Brand)",
    "CREATE INDEX IF NOT EXISTS idx_sales_store_brand ON sales (Store, Brand)",
    "CREATE INDEX IF NOT EXISTS idx_purchase_prices_brand ON purchase_prices (Brand)",
    "CREATE INDEX IF NOT EXISTS idx_vendor_invoice_vendor ON vendor_invoice (VendorNumber)",
    "CREATE INDEX IF NOT EXISTS idx_begin_inventory_store_brand ON begin_inventory (Store, Brand)",
    "CREATE INDEX IF NOT EXISTS idx_end_inventory_store_brand ON end_inventory (Store, Brand)",
]


MODEL_INDEX_STATEMENTS = [
    "CREATE INDEX IF NOT EXISTS idx_stg_purchases_vendor_brand ON stg_purchases (vendor_number, brand_id)",
    "CREATE INDEX IF NOT EXISTS idx_stg_sales_vendor_brand ON stg_sales (vendor_number, brand_id)",
    "CREATE INDEX IF NOT EXISTS idx_fct_purchases_vendor_brand ON fct_purchases (vendor_number, brand_id)",
    "CREATE INDEX IF NOT EXISTS idx_fct_sales_vendor_brand ON fct_sales (vendor_number, brand_id)",
    "CREATE INDEX IF NOT EXISTS idx_fct_inventory_snapshot_store_brand ON fct_inventory_snapshot (store_id, brand_id)",
    "CREATE INDEX IF NOT EXISTS idx_fct_vendor_freight_vendor ON fct_vendor_freight (vendor_number)",
    "CREATE INDEX IF NOT EXISTS idx_mart_vendor_performance_vendor_brand ON mart_vendor_performance (vendor_id, product_id)",
]


REQUIRED_RAW_TABLES = {
    "begin_inventory",
    "end_inventory",
    "purchase_prices",
    "purchases",
    "sales",
    "vendor_invoice",
}


def configure_logging() -> None:
    try:
        LOG_PATH.parent.mkdir(parents=True, exist_ok=True)
        logging.basicConfig(
            filename=LOG_PATH,
            level=logging.INFO,
            format="%(asctime)s - %(levelname)s - %(message)s",
            filemode="a",
        )
    except PermissionError:
        logging.basicConfig(
            level=logging.INFO,
            format="%(asctime)s - %(levelname)s - %(message)s",
        )


def ensure_raw_tables_exist(conn: sqlite3.Connection) -> None:
    existing = {
        row[0]
        for row in conn.execute(
            "SELECT name FROM sqlite_master WHERE type = 'table'"
        ).fetchall()
    }
    missing = sorted(REQUIRED_RAW_TABLES - existing)
    if missing:
        raise RuntimeError(
            "Missing raw tables. Load raw data first. Missing: " + ", ".join(missing)
        )


def execute_statements(conn: sqlite3.Connection, statements: list[str]) -> None:
    for statement in statements:
        conn.execute(statement)


def materialize_sql_directory(conn: sqlite3.Connection, sql_dir: Path) -> None:
    for sql_path in sorted(sql_dir.glob("*.sql")):
        table_name = sql_path.stem
        select_sql = sql_path.read_text(encoding="utf-8").strip()
        logging.info("Materializing %s from %s", table_name, sql_path.name)
        conn.execute(f'DROP TABLE IF EXISTS "{table_name}"')
        conn.execute(f'CREATE TABLE "{table_name}" AS {select_sql}')
        row_count = conn.execute(f'SELECT COUNT(*) FROM "{table_name}"').fetchone()[0]
        logging.info("Created %s with %s rows", table_name, row_count)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Build analytics marts in SQLite.")
    parser.add_argument("--db-path", type=Path, default=DEFAULT_DB_PATH)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    configure_logging()

    with sqlite3.connect(args.db_path) as conn:
        conn.execute("PRAGMA foreign_keys = OFF")
        ensure_raw_tables_exist(conn)
        execute_statements(conn, RAW_INDEX_STATEMENTS)
        materialize_sql_directory(conn, SQL_ROOT / "staging")
        materialize_sql_directory(conn, SQL_ROOT / "marts")
        execute_statements(conn, MODEL_INDEX_STATEMENTS)
        conn.commit()

    print(f"Built staged tables, marts, and indexes in {args.db_path}")


if __name__ == "__main__":
    main()
