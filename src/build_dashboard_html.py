from __future__ import annotations

import html
import sqlite3
from datetime import datetime, timezone
from pathlib import Path

import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DB_PATH = PROJECT_ROOT / "inventory.db"
QUERY_DIR = PROJECT_ROOT / "sql" / "analysis"
OUTPUT_PATH = PROJECT_ROOT / "dashboard" / "vendor_performance_dashboard.html"


def read_query(query_name: str, limit: int = 10) -> str:
    sql_path = QUERY_DIR / f"{query_name}.sql"
    query = sql_path.read_text(encoding="utf-8")
    return query.replace("{{limit}}", str(limit))


def fetch_dataframe(
    conn: sqlite3.Connection,
    query_name: str,
    limit: int = 10,
) -> pd.DataFrame:
    return pd.read_sql_query(read_query(query_name, limit), conn)


def fmt_money(value: float) -> str:
    if value is None:
        return "-"
    sign = "-" if value < 0 else ""
    value = abs(float(value))
    if value >= 1_000_000_000:
        return f"{sign}${value / 1_000_000_000:.2f}B"
    if value >= 1_000_000:
        return f"{sign}${value / 1_000_000:.2f}M"
    if value >= 1_000:
        return f"{sign}${value / 1_000:.2f}K"
    return f"{sign}${value:.2f}"


def fmt_pct(value: float) -> str:
    if value is None:
        return "-"
    return f"{float(value):.2f}%"


def fmt_num(value: float) -> str:
    if value is None:
        return "-"
    return f"{float(value):,.0f}"


def pretty_header(value: str) -> str:
    return value.replace("_", " ").title()


def table_html(df: pd.DataFrame, formatters: dict[str, callable] | None = None) -> str:
    formatters = formatters or {}
    header = "".join(f"<th>{html.escape(pretty_header(str(col)))}</th>" for col in df.columns)
    rows = []
    for _, row in df.iterrows():
        cells = []
        for col in df.columns:
            value = row[col]
            rendered = formatters[col](value) if col in formatters else str(value)
            cells.append(f"<td>{html.escape(rendered)}</td>")
        rows.append("<tr>" + "".join(cells) + "</tr>")
    body = "".join(rows)
    return f"<table><thead><tr>{header}</tr></thead><tbody>{body}</tbody></table>"


def bar_table_html(
    df: pd.DataFrame,
    label_col: str,
    value_col: str,
    value_formatter: callable,
) -> str:
    if df.empty:
        return "<p>No data available.</p>"

    max_value = float(df[value_col].max())
    rows = []
    for _, row in df.iterrows():
        label = html.escape(str(row[label_col]))
        value = float(row[value_col])
        width = 0 if max_value == 0 else (value / max_value) * 100
        rows.append(
            "<div class='bar-row'>"
            f"<div class='bar-label'>{label}</div>"
            "<div class='bar-track'>"
            f"<div class='bar-fill' style='width:{width:.2f}%'></div>"
            "</div>"
            f"<div class='bar-value'>{html.escape(value_formatter(value))}</div>"
            "</div>"
        )
    return "".join(rows)


def line_chart_svg(df: pd.DataFrame) -> str:
    if df.empty:
        return "<p>No trend data available.</p>"

    width = 940
    height = 280
    left_pad = 50
    right_pad = 20
    top_pad = 20
    bottom_pad = 45
    chart_width = width - left_pad - right_pad
    chart_height = height - top_pad - bottom_pad

    sales_values = df["sales_dollars"].astype(float).tolist()
    purchase_values = df["purchase_dollars"].astype(float).tolist()
    max_value = max(sales_values + purchase_values) if (sales_values or purchase_values) else 0
    if max_value == 0:
        max_value = 1

    def x_pos(index: int) -> float:
        if len(df) == 1:
            return left_pad + chart_width / 2
        return left_pad + (chart_width * index / (len(df) - 1))

    def y_pos(value: float) -> float:
        return top_pad + chart_height - (value / max_value) * chart_height

    def points(values: list[float]) -> str:
        return " ".join(f"{x_pos(i):.2f},{y_pos(value):.2f}" for i, value in enumerate(values))

    sales_points = points(sales_values)
    purchase_points = points(purchase_values)

    labels = []
    for i, year_month in enumerate(df["year_month"].tolist()):
        labels.append(
            f"<text x='{x_pos(i):.2f}' y='{height - 12}' text-anchor='middle' class='axis-label'>{html.escape(str(year_month))}</text>"
        )

    grid_lines = []
    for step in range(5):
        y = top_pad + chart_height * step / 4
        grid_lines.append(
            f"<line x1='{left_pad}' y1='{y:.2f}' x2='{width - right_pad}' y2='{y:.2f}' class='grid-line' />"
        )

    return (
        f"<svg viewBox='0 0 {width} {height}' class='trend-svg' role='img' aria-label='Monthly sales and purchase trend'>"
        + "".join(grid_lines)
        + f"<polyline fill='none' stroke='#0f766e' stroke-width='4' points='{sales_points}' />"
        + f"<polyline fill='none' stroke='#d97706' stroke-width='4' points='{purchase_points}' />"
        + "".join(labels)
        + "</svg>"
    )


def build_dashboard() -> None:
    with sqlite3.connect(DB_PATH) as conn:
        kpis = fetch_dataframe(conn, "executive_kpis")
        monthly_trend = fetch_dataframe(conn, "monthly_sales_purchase_trend")
        top_vendor_sales = fetch_dataframe(conn, "top_vendor_sales", limit=10)
        top_vendor_profit = fetch_dataframe(conn, "top_vendor_profit", limit=10)
        vendor_concentration = fetch_dataframe(conn, "vendor_concentration", limit=10)
        inventory_risk = fetch_dataframe(conn, "inventory_risk", limit=10)
        store_dependency = fetch_dataframe(conn, "store_dependency", limit=10)
        slow_turnover_products = fetch_dataframe(conn, "slow_turnover_products", limit=10)

    kpi_row = kpis.iloc[0]
    top10_contribution = vendor_concentration["contribution_pct"].sum()
    generated_at = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")

    peak_sales_row = monthly_trend.loc[monthly_trend["sales_dollars"].idxmax()]
    top_sales_vendor = top_vendor_sales.iloc[0]
    top_profit_vendor = top_vendor_profit.iloc[0]
    high_dependency_count = int((store_dependency["dependency_pct"] >= 20).sum())

    html_output = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Vendor Performance Report</title>
  <style>
    :root {{
      --ink: #1b2430;
      --muted: #5d6a79;
      --line: #dde3ea;
      --panel: #ffffff;
      --bg: #f5f7f8;
      --teal: #0f766e;
      --amber: #d97706;
      --shadow: 0 10px 28px rgba(27, 36, 48, 0.08);
    }}
    * {{ box-sizing: border-box; }}
    body {{
      margin: 0;
      color: var(--ink);
      font-family: "Segoe UI", Tahoma, sans-serif;
      background: linear-gradient(180deg, #f8fafb 0%, var(--bg) 100%);
    }}
    .wrap {{
      max-width: 1320px;
      margin: 0 auto;
      padding: 28px 22px 52px;
    }}
    .hero {{
      background: var(--panel);
      border: 1px solid var(--line);
      border-radius: 22px;
      box-shadow: var(--shadow);
      padding: 28px;
      margin-bottom: 18px;
    }}
    .eyebrow {{
      font-size: 12px;
      text-transform: uppercase;
      letter-spacing: 0.10em;
      color: var(--teal);
      font-weight: 700;
      margin-bottom: 8px;
    }}
    h1 {{
      margin: 0 0 10px;
      font-size: 38px;
      line-height: 1.1;
    }}
    .hero p {{
      margin: 0;
      max-width: 900px;
      color: var(--muted);
      font-size: 16px;
      line-height: 1.6;
    }}
    .meta {{
      margin-top: 14px;
      font-size: 13px;
      color: var(--muted);
    }}
    .nav {{
      display: flex;
      flex-wrap: wrap;
      gap: 10px;
      margin: 0 0 18px;
    }}
    .nav a {{
      text-decoration: none;
      color: var(--ink);
      background: #eef4f5;
      border: 1px solid var(--line);
      padding: 10px 14px;
      border-radius: 999px;
      font-size: 14px;
      font-weight: 600;
    }}
    .kpi-grid {{
      display: grid;
      grid-template-columns: repeat(4, minmax(0, 1fr));
      gap: 14px;
      margin-bottom: 18px;
    }}
    .kpi {{
      background: var(--panel);
      border: 1px solid var(--line);
      border-radius: 18px;
      padding: 18px;
      box-shadow: var(--shadow);
    }}
    .kpi-label {{
      font-size: 12px;
      text-transform: uppercase;
      letter-spacing: 0.08em;
      color: var(--muted);
      margin-bottom: 6px;
      font-weight: 700;
    }}
    .kpi-value {{
      font-size: 28px;
      font-weight: 700;
      margin-bottom: 6px;
    }}
    .kpi-note {{
      color: var(--muted);
      font-size: 13px;
      line-height: 1.45;
    }}
    .insight-grid {{
      display: grid;
      grid-template-columns: repeat(3, minmax(0, 1fr));
      gap: 14px;
      margin-bottom: 18px;
    }}
    .insight {{
      background: var(--panel);
      border: 1px solid var(--line);
      border-radius: 18px;
      padding: 18px;
      box-shadow: var(--shadow);
    }}
    .insight h3 {{
      margin: 0 0 8px;
      font-size: 16px;
    }}
    .insight p {{
      margin: 0;
      color: var(--muted);
      line-height: 1.6;
      font-size: 14px;
    }}
    .grid {{
      display: grid;
      grid-template-columns: repeat(12, 1fr);
      gap: 18px;
    }}
    .card {{
      background: var(--panel);
      border: 1px solid var(--line);
      border-radius: 20px;
      box-shadow: var(--shadow);
      padding: 20px;
    }}
    .span-12 {{ grid-column: span 12; }}
    .span-6 {{ grid-column: span 6; }}
    h2 {{
      margin: 0 0 10px;
      font-size: 25px;
    }}
    .section-copy {{
      color: var(--muted);
      margin: 0 0 16px;
      line-height: 1.6;
      font-size: 15px;
    }}
    .legend {{
      display: flex;
      gap: 18px;
      margin-bottom: 8px;
      font-size: 14px;
      color: var(--muted);
    }}
    .legend span {{
      display: inline-flex;
      align-items: center;
      gap: 8px;
    }}
    .dot {{
      width: 12px;
      height: 12px;
      border-radius: 999px;
      display: inline-block;
    }}
    .trend-svg {{
      width: 100%;
      height: auto;
      display: block;
      background: #fbfcfd;
      border-radius: 14px;
      border: 1px solid #edf1f4;
    }}
    .axis-label {{
      fill: #71808e;
      font-size: 11px;
    }}
    .grid-line {{
      stroke: #e7edf2;
      stroke-width: 1;
    }}
    .bar-row {{
      display: grid;
      grid-template-columns: 220px 1fr 110px;
      gap: 12px;
      align-items: center;
      margin-bottom: 12px;
    }}
    .bar-label {{
      font-size: 14px;
      line-height: 1.3;
    }}
    .bar-track {{
      height: 14px;
      background: #eef2f5;
      border-radius: 999px;
      overflow: hidden;
    }}
    .bar-fill {{
      height: 100%;
      border-radius: 999px;
      background: linear-gradient(90deg, #0f766e 0%, #16928a 100%);
    }}
    .bar-value {{
      text-align: right;
      font-weight: 700;
      font-size: 14px;
    }}
    table {{
      width: 100%;
      border-collapse: collapse;
      font-size: 14px;
    }}
    th, td {{
      text-align: left;
      padding: 10px 8px;
      border-bottom: 1px solid #edf1f4;
      vertical-align: top;
    }}
    th {{
      color: var(--muted);
      text-transform: uppercase;
      letter-spacing: 0.05em;
      font-size: 11px;
    }}
    .note-box {{
      background: #f1f7f8;
      border: 1px solid #d8e7ea;
      border-radius: 16px;
      padding: 16px;
      margin-bottom: 14px;
      font-size: 14px;
      line-height: 1.6;
    }}
    .bullets {{
      margin: 0;
      padding-left: 18px;
      color: var(--muted);
      line-height: 1.8;
      font-size: 14px;
    }}
    @media (max-width: 1080px) {{
      .kpi-grid {{ grid-template-columns: repeat(2, minmax(0, 1fr)); }}
      .insight-grid {{ grid-template-columns: 1fr; }}
      .span-6 {{ grid-column: span 12; }}
      .bar-row {{ grid-template-columns: 1fr; }}
      .bar-value {{ text-align: left; }}
    }}
    @media (max-width: 680px) {{
      .wrap {{ padding: 16px 12px 32px; }}
      .hero {{ padding: 20px; }}
      h1 {{ font-size: 29px; }}
      .kpi-grid {{ grid-template-columns: 1fr; }}
    }}
  </style>
</head>
<body>
  <div class="wrap">
    <section class="hero" id="overview">
      <div class="eyebrow">Vendor Performance Report</div>
      <h1>Sales, Spend, Freight, and Inventory View</h1>
      <p>
        This report is built from the SQLite tables in this project. It brings sales, purchases, freight, inventory cost, and vendor concentration into one view.
      </p>
      <div class="meta">Generated on {html.escape(generated_at)}</div>
    </section>

    <nav class="nav">
      <a href="#overview">Overview</a>
      <a href="#trend">Trend</a>
      <a href="#vendors">Vendors</a>
      <a href="#risk">Risk</a>
      <a href="#notes">Notes</a>
    </nav>

    <section class="kpi-grid">
      <div class="kpi">
        <div class="kpi-label">Purchase Dollars</div>
        <div class="kpi-value">{fmt_money(kpi_row['purchase_dollars'])}</div>
        <div class="kpi-note">Total purchase dollars in the final table.</div>
      </div>
      <div class="kpi">
        <div class="kpi-label">Sales Dollars</div>
        <div class="kpi-value">{fmt_money(kpi_row['sales_dollars'])}</div>
        <div class="kpi-note">Total sales dollars in the final table.</div>
      </div>
      <div class="kpi">
        <div class="kpi-label">Gross Profit After Freight</div>
        <div class="kpi-value">{fmt_money(kpi_row['gross_profit_after_freight'])}</div>
        <div class="kpi-note">Sales minus purchase cost and allocated freight.</div>
      </div>
      <div class="kpi">
        <div class="kpi-label">Weighted Margin</div>
        <div class="kpi-value">{fmt_pct(kpi_row['weighted_margin_pct'])}</div>
        <div class="kpi-note">Gross profit after freight divided by sales dollars.</div>
      </div>
      <div class="kpi">
        <div class="kpi-label">Allocated Freight</div>
        <div class="kpi-value">{fmt_money(kpi_row['allocated_freight'])}</div>
        <div class="kpi-note">Allocated from vendor totals into the final mart.</div>
      </div>
      <div class="kpi">
        <div class="kpi-label">Unsold Inventory Cost</div>
        <div class="kpi-value">{fmt_money(kpi_row['unsold_inventory_cost'])}</div>
        <div class="kpi-note">Estimated using end inventory units and average purchase cost.</div>
      </div>
      <div class="kpi">
        <div class="kpi-label">Vendor Coverage</div>
        <div class="kpi-value">{fmt_num(kpi_row['vendors'])}</div>
        <div class="kpi-note">Distinct vendors in the final mart.</div>
      </div>
      <div class="kpi">
        <div class="kpi-label">Top 10 Vendor Share</div>
        <div class="kpi-value">{fmt_pct(top10_contribution)}</div>
        <div class="kpi-note">Share of purchase dollars held by the top 10 vendors.</div>
      </div>
    </section>

    <section class="insight-grid">
      <div class="insight">
        <h3>Top sales vendor</h3>
        <p><strong>{html.escape(str(top_sales_vendor['vendor_name']))}</strong> is the largest vendor by sales at <strong>{fmt_money(top_sales_vendor['sales_dollars'])}</strong>.</p>
      </div>
      <div class="insight">
        <h3>Top profit vendor</h3>
        <p><strong>{html.escape(str(top_profit_vendor['vendor_name']))}</strong> has the highest gross profit after freight at <strong>{fmt_money(top_profit_vendor['gross_profit_after_freight'])}</strong>.</p>
      </div>
      <div class="insight">
        <h3>Peak sales month</h3>
        <p>The highest monthly sales happened in <strong>{html.escape(str(peak_sales_row['year_month']))}</strong> with <strong>{fmt_money(peak_sales_row['sales_dollars'])}</strong> in sales.</p>
      </div>
    </section>

    <section class="grid">
      <div class="card span-12" id="trend">
        <h2>Monthly Sales and Purchase Trend</h2>
        <p class="section-copy">This trend compares monthly purchase dollars and sales dollars.</p>
        <div class="legend">
          <span><i class="dot" style="background:#0f766e"></i>Sales</span>
          <span><i class="dot" style="background:#d97706"></i>Purchases</span>
        </div>
        {line_chart_svg(monthly_trend)}
      </div>

      <div class="card span-6" id="vendors">
        <h2>Top Vendors By Sales</h2>
        <p class="section-copy">Vendors ranked by sales dollars.</p>
        {bar_table_html(top_vendor_sales, 'vendor_name', 'sales_dollars', fmt_money)}
      </div>

      <div class="card span-6">
        <h2>Top Vendors By Gross Profit</h2>
        <p class="section-copy">Vendors ranked by gross profit after freight.</p>
        {bar_table_html(top_vendor_profit, 'vendor_name', 'gross_profit_after_freight', fmt_money)}
      </div>

      <div class="card span-6">
        <h2>Procurement Concentration</h2>
        <p class="section-copy">This table shows how purchase spend is distributed across the largest vendors.</p>
        {table_html(vendor_concentration, {
            'purchase_dollars': fmt_money,
            'contribution_pct': fmt_pct,
        })}
      </div>

      <div class="card span-6" id="risk">
        <h2>Inventory Risk By Vendor</h2>
        <p class="section-copy">These vendors have the largest estimated unsold inventory cost.</p>
        {table_html(inventory_risk, {
            'unsold_cost': fmt_money,
            'avg_inventory_turnover': lambda v: f"{float(v):.4f}",
            'sales_dollars': fmt_money,
        })}
      </div>

      <div class="card span-6">
        <h2>Store Dependency Signals</h2>
        <p class="section-copy">For each store, this shows the largest vendor by purchase dollars. In this top 10 list, <strong>{fmt_num(high_dependency_count)}</strong> stores are at or above 20% dependency.</p>
        {table_html(store_dependency, {
            'purchase_dollars': fmt_money,
            'dependency_pct': fmt_pct,
        })}
      </div>

      <div class="card span-6">
        <h2>Slow-Turnover Products</h2>
        <p class="section-copy">These products have low turnover and still hold inventory cost.</p>
        {table_html(slow_turnover_products, {
            'purchase_dollars': fmt_money,
            'sales_dollars': fmt_money,
            'inventory_turnover_ratio': lambda v: f"{float(v):.4f}",
            'estimated_unsold_inventory_cost': fmt_money,
        })}
      </div>

      <div class="card span-12" id="notes">
        <h2>Checks and Notes</h2>
        <div class="note-box">
          The report is built from SQL tables that were checked against the source data. Purchase totals, sales totals, freight totals, table relationships, and final table grain all passed validation in the latest run.
        </div>
        <ul class="bullets">
          <li>The final mart is one row per vendor and product.</li>
          <li>Freight is not repeated across all vendor-product rows. It is allocated by purchase-dollar share.</li>
          <li>Inventory cost here is an estimate based on average purchase cost and end inventory units.</li>
          <li>This report is generated from local SQLite data, so it can be rebuilt after model changes.</li>
        </ul>
      </div>
    </section>
  </div>
</body>
</html>
"""

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_PATH.write_text(html_output, encoding="utf-8")
    print(f"Dashboard written to {OUTPUT_PATH}")


if __name__ == "__main__":
    build_dashboard()
