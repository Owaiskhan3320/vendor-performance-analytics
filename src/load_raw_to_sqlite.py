from __future__ import annotations

import argparse
import logging
import sqlite3
import time
from pathlib import Path

import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_DATA_DIR = PROJECT_ROOT / "data" / "data"
DEFAULT_DB_PATH = PROJECT_ROOT / "inventory.db"
LOG_PATH = PROJECT_ROOT / "logs" / "ingestion_refactor.log"


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


def load_csvs_to_sqlite(data_dir: Path, db_path: Path) -> None:
    if not data_dir.exists():
        raise FileNotFoundError(f"Data directory not found: {data_dir}")

    csv_files = sorted(data_dir.glob("*.csv"))
    if not csv_files:
        raise FileNotFoundError(f"No CSV files found in: {data_dir}")

    start = time.time()
    with sqlite3.connect(db_path) as conn:
        for csv_path in csv_files:
            table_name = csv_path.stem
            logging.info("Loading %s into %s", csv_path.name, table_name)
            df = pd.read_csv(csv_path, low_memory=False)
            df.to_sql(table_name, conn, if_exists="replace", index=False)
            logging.info("Loaded %s rows into %s", len(df), table_name)
    elapsed = (time.time() - start) / 60
    logging.info("Raw ingestion complete in %.2f minutes", elapsed)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Load raw CSV data into SQLite.")
    parser.add_argument("--data-dir", type=Path, default=DEFAULT_DATA_DIR)
    parser.add_argument("--db-path", type=Path, default=DEFAULT_DB_PATH)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    configure_logging()
    load_csvs_to_sqlite(args.data_dir, args.db_path)
    print(f"Loaded raw CSV files from {args.data_dir} into {args.db_path}")


if __name__ == "__main__":
    main()
