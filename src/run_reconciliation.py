from __future__ import annotations

import argparse
import sqlite3
import sys
from pathlib import Path

import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_DB_PATH = PROJECT_ROOT / "inventory.db"
DEFAULT_TEST_DIR = PROJECT_ROOT / "tests" / "sql"


def run_sql_tests(db_path: Path, test_dir: Path) -> int:
    failures = 0
    with sqlite3.connect(db_path) as conn:
        for sql_path in sorted(test_dir.glob("*.sql")):
            query = sql_path.read_text(encoding="utf-8")
            result = pd.read_sql_query(query, conn)
            print(f"\n[{sql_path.name}]")
            if result.empty:
                print("PASS")
            else:
                failures += 1
                print("FAIL")
                print(result.to_string(index=False))
    return failures


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run SQL reconciliation checks.")
    parser.add_argument("--db-path", type=Path, default=DEFAULT_DB_PATH)
    parser.add_argument("--test-dir", type=Path, default=DEFAULT_TEST_DIR)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    failures = run_sql_tests(args.db_path, args.test_dir)
    if failures:
        print(f"\n{failures} SQL test file(s) reported failures.")
        sys.exit(1)
    print("\nAll SQL reconciliation checks passed.")


if __name__ == "__main__":
    main()

