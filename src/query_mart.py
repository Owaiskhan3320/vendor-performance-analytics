from __future__ import annotations

import argparse
import sqlite3
from pathlib import Path

import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_DB_PATH = PROJECT_ROOT / "inventory.db"
QUERY_DIR = PROJECT_ROOT / "sql" / "analysis"


def available_queries() -> list[str]:
    return sorted(path.stem for path in QUERY_DIR.glob("*.sql"))


def render_query_template(query_name: str, limit: int) -> str:
    sql_path = QUERY_DIR / f"{query_name}.sql"
    if not sql_path.exists():
        raise FileNotFoundError(f"Unknown query: {query_name}")
    query = sql_path.read_text(encoding="utf-8")
    return query.replace("{{limit}}", str(limit))


def run_query(db_path: Path, query_name: str, limit: int) -> pd.DataFrame:
    query = render_query_template(query_name, limit)
    with sqlite3.connect(db_path) as conn:
        return pd.read_sql_query(query, conn)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run named SQL analyses against the vendor mart.")
    parser.add_argument("--db-path", type=Path, default=DEFAULT_DB_PATH)
    parser.add_argument("--query", help="Query name from sql/analysis")
    parser.add_argument("--limit", type=int, default=10)
    parser.add_argument("--output", type=Path, help="Optional CSV output path")
    parser.add_argument("--list", action="store_true", help="List available named queries")
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    if args.list:
        for name in available_queries():
            print(name)
        return

    if not args.query:
        raise SystemExit("Pass --query <name> or use --list")

    df = run_query(args.db_path, args.query, args.limit)
    print(df.to_string(index=False))

    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        df.to_csv(args.output, index=False)
        print(f"\nSaved CSV to {args.output}")


if __name__ == "__main__":
    main()

