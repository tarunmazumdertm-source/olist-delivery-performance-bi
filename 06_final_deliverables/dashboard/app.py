from __future__ import annotations

from datetime import date, datetime, timedelta
from typing import Any

import mysql.connector
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
import streamlit as st


# -----------------------------------------------------------------------------
# App configuration and visual style
# -----------------------------------------------------------------------------
st.set_page_config(
    page_title="Olist | Delivery & Customer Analytics",
    page_icon="📦",
    layout="wide",
    initial_sidebar_state="expanded",
)

NAVY = "#14243A"
BLUE = "#2878B5"
TEAL = "#159A91"
GOLD = "#E6A23C"
RED = "#D65A5A"
MUTED = "#738197"
PALETTE = [BLUE, TEAL, GOLD, RED, "#8064A2", "#6B8E23", "#C47A43"]

st.markdown(
    """
    <style>
      .stApp { background: #F5F7FA; }
      [data-testid="stHeader"] { background: rgba(245,247,250,0.92); }
      .block-container { padding-top: 1.5rem; padding-bottom: 2.5rem; max-width: 1500px; }
      [data-testid="stMetric"] {
        background: #FFFFFF; border: 1px solid #E4EAF1; border-radius: 13px;
        padding: 15px 17px; box-shadow: 0 2px 8px rgba(20,36,58,0.035);
      }
      [data-testid="stMetricLabel"] p { color: #65758B; font-size: 0.82rem; }
      [data-testid="stMetricValue"] { color: #14243A; font-weight: 700; }
      .hero {
        background: linear-gradient(110deg, #14243A 0%, #1E4966 58%, #167D7A 100%);
        border-radius: 17px; padding: 25px 29px; color: white; margin-bottom: 18px;
      }
      .hero h1 { color: white; font-size: 1.75rem; margin: 0 0 5px 0; }
      .hero p { color: #DCE8F0; margin: 0; font-size: 0.96rem; }
      .section-title { color: #14243A; font-size: 1.12rem; font-weight: 700; margin: 0.3rem 0 0.65rem; }
      .baseline { color: #738197; font-size: 0.76rem; margin-top: -10px; margin-bottom: 9px; }
      .note-card {
        background: #FFFFFF; border: 1px solid #E4EAF1; border-left: 4px solid #159A91;
        border-radius: 11px; padding: 14px 16px; color: #33465C;
      }
      .small-muted { color: #738197; font-size: 0.82rem; }
      div[data-testid="stPlotlyChart"] { background: #FFFFFF; border: 1px solid #E4EAF1; border-radius: 13px; padding: 8px; }
      section[data-testid="stSidebar"] { background: #EDF2F7; }
      .stButton button { border-radius: 9px; }
    </style>
    """,
    unsafe_allow_html=True,
)


# -----------------------------------------------------------------------------
# Database helpers. The app only executes SELECT statements.
# -----------------------------------------------------------------------------
def open_connection(config: dict[str, Any]):
    return mysql.connector.connect(
        host=config["host"],
        port=int(config["port"]),
        user=config["user"],
        password=config["password"],
        database=config["database"],
        charset="utf8mb4",
        use_unicode=True,
        connection_timeout=12,
        autocommit=True,
    )


def query_df(connection, sql: str, params: tuple[Any, ...] = ()) -> pd.DataFrame:
    cursor = connection.cursor(dictionary=True)
    try:
        cursor.execute(sql, params)
        rows = cursor.fetchall()
        return pd.DataFrame(rows)
    finally:
        cursor.close()


def query_one(connection, sql: str, params: tuple[Any, ...] = ()) -> dict[str, Any]:
    cursor = connection.cursor(dictionary=True)
    try:
        cursor.execute(sql, params)
        return cursor.fetchone() or {}
    finally:
        cursor.close()


def build_scope(
    start_date: date,
    end_date: date,
    region: str,
    states: list[str],
    fact_alias: str = "f",
    location_alias: str = "loc",
) -> tuple[str, tuple[Any, ...]]:
    """Build a parameterized purchase-date and customer-location filter."""
    conditions = [
        f"{fact_alias}.purchase_ts >= %s",
        f"{fact_alias}.purchase_ts < %s",
    ]
    params: list[Any] = [start_date, end_date + timedelta(days=1)]
    if region != "All regions":
        conditions.append(f"{location_alias}.region_name = %s")
        params.append(region)
    if states:
        conditions.append(
            f"{location_alias}.state_code IN ({', '.join(['%s'] * len(states))})"
        )
        params.extend(states)
    return "WHERE " + " AND ".join(conditions), tuple(params)


def brl(value: Any) -> str:
    if value is None or pd.isna(value):
        return "—"
    return f"R$ {float(value):,.2f}"


def number(value: Any, decimals: int = 2) -> str:
    if value is None or pd.isna(value):
        return "—"
    return f"{float(value):,.{decimals}f}"


def pct(value: Any) -> str:
    if value is None or pd.isna(value):
        return "—"
    return f"{float(value):.2f}%"


def metric_card(column, label: str, value: str, baseline: str | None = None):
    column.metric(label, value)
    if baseline:
        column.markdown(f'<div class="baseline">EDA baseline: {baseline}</div>', unsafe_allow_html=True)


def chart_layout(fig, height: int = 340):
    fig.update_layout(
        height=height,
        margin=dict(l=18, r=18, t=42, b=18),
        paper_bgcolor="rgba(0,0,0,0)",
        plot_bgcolor="white",
        font=dict(family="Arial", color=NAVY, size=12),
        title_font=dict(size=15, color=NAVY),
        legend_title_text="",
        hoverlabel=dict(bgcolor="white"),
    )
    fig.update_xaxes(showgrid=False, linecolor="#E7ECF2")
    fig.update_yaxes(gridcolor="#EDF1F5", zeroline=False)
    return fig


def chart_empty(message: str):
    st.info(message)


# -----------------------------------------------------------------------------
# Sidebar: local MySQL connection and dashboard filters
# -----------------------------------------------------------------------------
def read_server_mysql_config() -> dict[str, Any] | None:
    """Read optional shared server-side credentials from .streamlit/secrets.toml."""
    try:
        secret = st.secrets.get("mysql")
        if not secret:
            return None
        return {
            "host": str(secret.get("host", "127.0.0.1")),
            "port": int(secret.get("port", 3306)),
            "user": str(secret.get("user", "olist_dashboard")),
            "password": str(secret.get("password", "")),
            "database": str(secret.get("database", "olist_dm_test")),
        }
    except Exception:
        # No secrets file is normal during local development; use the manual form.
        return None


server_mysql_config = read_server_mysql_config()
if (
    server_mysql_config
    and "db_config" not in st.session_state
    and not st.session_state.get("manual_disconnect", False)
):
    st.session_state["db_config"] = server_mysql_config
    st.session_state["db_config_source"] = "server_secrets"

st.sidebar.markdown("# 📦 Olist Analytics")
st.sidebar.caption("Delivery performance · Customer satisfaction · Sales")
st.sidebar.divider()

if server_mysql_config:
    st.sidebar.markdown("**MySQL connection**")
    st.sidebar.info("This dashboard uses the private server-side database settings. Team viewers do not need the database password.")
    if st.session_state.get("db_config_source") == "server_secrets" and "db_config" in st.session_state:
        st.sidebar.caption(f"Database: `{server_mysql_config['database']}` · User: `{server_mysql_config['user']}`")
        if st.sidebar.button("Disconnect",use_container_width=True,key="disconnect_private_db"):
            st.session_state.pop("db_config", None)
            st.session_state["manual_disconnect"] = True
            st.rerun()
    elif st.sidebar.button("Connect to Data Mart", type="primary", use_container_width=True):
        st.session_state["manual_disconnect"] = False
        st.session_state["db_config"] = server_mysql_config
        st.session_state["db_config_source"] = "server_secrets"
        st.rerun()
else:
    with st.sidebar.form("mysql_connection_form"):
        st.markdown("**MySQL connection**")
        host = st.text_input("Host", value="127.0.0.1")
        port = st.number_input("Port", min_value=1, max_value=65535, value=3306, step=1)
        user = st.text_input("User", value="root")
        password = st.text_input("Password", type="password", value="")
        database = st.text_input("Database", value="olist_dm_test")
        connect_clicked = st.form_submit_button("Connect to Data Mart", type="primary", use_container_width=True)

    if connect_clicked:
        candidate = {
            "host": host.strip(),
            "port": int(port),
            "user": user.strip(),
            "password": password,
            "database": database.strip(),
        }
        try:
            test_conn = open_connection(candidate)
            test_cursor = test_conn.cursor()
            test_cursor.execute("SELECT 1")
            test_cursor.fetchone()
            test_cursor.close()
            test_conn.close()
            st.session_state["db_config"] = candidate
            st.session_state["db_config_source"] = "manual"
            st.session_state["manual_disconnect"] = False
            st.session_state["db_error"] = None
            st.rerun()
        except mysql.connector.Error as exc:
            st.session_state["db_error"] = str(exc)

if st.session_state.get("db_error"):
    st.sidebar.error(f"Connection failed: {st.session_state['db_error']}")

if "db_config" not in st.session_state:
    st.markdown(
        '<div class="hero"><h1>Olist: From Order to Review</h1>'
        '<p>Explore how delivery performance relates to customer satisfaction and sales.</p></div>',
        unsafe_allow_html=True,
    )
    st.info("Connect to your local MySQL Data Mart using the form in the left sidebar.")
    st.markdown(
        "**Connection defaults:** `127.0.0.1` · port `3306` · database `olist_dm_test`. "
        "The dashboard uses read-only SELECT queries and does not change your database."
    )
    st.stop()


# Open a fresh connection for each Streamlit run; close it after rendering.
connection = None
try:
    connection = open_connection(st.session_state["db_config"])

    # Verify that this is the expected, completed Data Mart run.
    latest_run = query_one(
        connection,
        """SELECT etl_run_id, run_status, finished_at, run_note
           FROM olist_meta_test.etl_run
           WHERE run_note LIKE 'Data Mart load;%'
           ORDER BY etl_run_id DESC LIMIT 1""",
    )
    date_bounds = query_one(
        connection,
        """SELECT MIN(DATE(purchase_ts)) AS min_date, MAX(DATE(purchase_ts)) AS max_date
           FROM olist_dm_test.fact_order_fulfillment""",
    )
    region_df = query_df(
        connection,
        """SELECT DISTINCT l.region_name
           FROM olist_dm_test.fact_order_fulfillment f
           JOIN olist_dm_test.dim_location l ON l.location_key = f.customer_location_key
           WHERE f.customer_location_key <> -1
           ORDER BY l.region_name""",
    )
    all_regions = [x for x in region_df.get("region_name", pd.Series(dtype=str)).dropna().tolist()]

    st.sidebar.divider()
    st.sidebar.markdown("**Report filters**")
    min_date = date_bounds.get("min_date") or date(2017, 1, 1)
    max_date = date_bounds.get("max_date") or date(2018, 8, 31)
    chosen_dates = st.sidebar.date_input(
        "Purchase date range",
        value=(min_date, max_date),
        min_value=min_date,
        max_value=max_date,
        help="Filters orders by purchase date. The Data Mart already contains the approved project scope.",
    )
    if isinstance(chosen_dates, (tuple, list)) and len(chosen_dates) == 2:
        start_date, end_date = chosen_dates
    else:
        start_date = end_date = chosen_dates

    region = st.sidebar.selectbox("Customer region", ["All regions"] + all_regions)
    state_sql = """SELECT DISTINCT l.state_code
                    FROM olist_dm_test.fact_order_fulfillment f
                    JOIN olist_dm_test.dim_location l ON l.location_key = f.customer_location_key
                    WHERE f.customer_location_key <> -1"""
    state_params: tuple[Any, ...] = ()
    if region != "All regions":
        state_sql += " AND l.region_name = %s"
        state_params = (region,)
    state_sql += " ORDER BY l.state_code"
    state_df = query_df(connection, state_sql, state_params)
    available_states = [x for x in state_df.get("state_code", pd.Series(dtype=str)).dropna().tolist()]
    selected_states = st.sidebar.multiselect("Customer state(s)", available_states, default=[])

    st.sidebar.caption("Filters apply to purchase date and customer location. K12 is a project-wide customer measure.")
    if st.sidebar.button("Disconnect", use_container_width=True):
        st.session_state.pop("db_config", None)
        st.rerun()

    where, params = build_scope(start_date, end_date, region, selected_states)
    loc_join = "LEFT JOIN olist_dm_test.dim_location loc ON loc.location_key = f.customer_location_key"

    page = st.sidebar.radio(
        "Dashboard page",
        ["Executive overview", "Delivery performance", "Customer satisfaction"],
        index=0,
    )

    # Top header and load status.
    st.markdown(
        '<div class="hero"><h1>Olist: From Order to Review</h1>'
        '<p>How does delivery performance affect customer satisfaction and sales?</p></div>',
        unsafe_allow_html=True,
    )
    if latest_run:
        status = str(latest_run.get("run_status", "Unknown"))
        finished = latest_run.get("finished_at")
        st.caption(
            f"Data source: `{st.session_state['db_config']['database']}`  ·  "
            f"Latest Data Mart ETL: run {latest_run.get('etl_run_id')} ({status})  ·  "
            f"Last completed: {finished or 'not recorded'}"
        )
    st.caption(f"Selected purchase period: {start_date:%d %b %Y} – {end_date:%d %b %Y}")

    # -------------------------------------------------------------------------
    # KPI query functions, each using the validated SQL/EDA population rules.
    # -------------------------------------------------------------------------
    kpis = query_one(
        connection,
        f"""SELECT
              (SELECT SUM(si.item_price)
               FROM olist_dm_test.fact_sales_item si
               JOIN olist_dm_test.fact_order_fulfillment f ON f.order_key = si.order_key
               {loc_join}
               {where} AND si.is_sales_eligible = 1) AS k01_gmv,
              (SELECT COUNT(DISTINCT f.order_id)
               FROM olist_dm_test.fact_order_fulfillment f
               {loc_join}
               {where} AND f.is_sales_eligible = 1) AS k02_orders,
              (SELECT SUM(p.payment_value)
               FROM olist_dm_test.fact_payment p
               JOIN olist_dm_test.fact_order_fulfillment f ON f.order_key = p.order_key
               {loc_join}
               {where} AND p.is_sales_eligible = 1) AS eligible_payment_value""",
        params * 3,
    )
    k02_orders = int(kpis.get("k02_orders") or 0)
    k03_aov = (float(kpis.get("eligible_payment_value") or 0) / k02_orders) if k02_orders else None

    delivery_kpis = query_one(
        connection,
        f"""SELECT
              100.0 * SUM(CASE WHEN is_on_time = 1 THEN 1 ELSE 0 END)
                  / NULLIF(SUM(CASE WHEN is_delivery_kpi_eligible = 1 THEN 1 ELSE 0 END), 0) AS k04_on_time,
              AVG(CASE WHEN is_delivery_kpi_eligible = 1 THEN delivery_days END) AS k05_delivery_days,
              AVG(CASE WHEN is_delivery_kpi_eligible = 1 AND is_late = 1 THEN delay_days END) AS k06_late_days,
              100.0 * SUM(CASE WHEN is_dispatch_on_time = 1 THEN 1 ELSE 0 END)
                  / NULLIF(SUM(CASE WHEN is_dispatch_on_time IS NOT NULL THEN 1 ELSE 0 END), 0) AS k07_dispatch,
              AVG(CASE WHEN is_delivery_kpi_eligible = 1 THEN estimate_buffer_days END) AS k08_buffer
           FROM olist_dm_test.fact_order_fulfillment f
           {loc_join}
           {where}""",
        params,
    )
    review_kpis = query_one(
        connection,
        f"""SELECT
              AVG(CASE WHEN r.is_latest_for_order = 1 THEN r.review_score END) AS k09_latest_score,
              100.0 * SUM(CASE WHEN r.review_score <= 2 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS k10_poor_rate,
              AVG(CASE WHEN r.is_latest_for_order = 1 AND ds.status_code = 'ON_TIME' THEN r.review_score END)
                - AVG(CASE WHEN r.is_latest_for_order = 1 AND ds.status_code = 'LATE' THEN r.review_score END) AS k11_review_gap
           FROM olist_dm_test.fact_review r
           JOIN olist_dm_test.fact_order_fulfillment f ON f.order_key = r.order_key
           LEFT JOIN olist_dm_test.dim_delivery_status ds ON ds.delivery_status_key = r.delivery_status_key
           {loc_join}
           {where}""",
        params,
    )
    k12 = query_one(
        connection,
        """SELECT 100.0 * SUM(CASE WHEN is_repeat_customer = 1 THEN 1 ELSE 0 END)
                    / NULLIF(SUM(CASE WHEN eligible_order_count > 0 THEN 1 ELSE 0 END), 0) AS k12_repeat
           FROM olist_dm_test.dim_customer
           WHERE customer_key <> -1""",
    ).get("k12_repeat")

    # -------------------------------------------------------------------------
    # PAGE 1 — Executive overview
    # -------------------------------------------------------------------------
    if page == "Executive overview":
        st.markdown('<div class="section-title">Business performance at a glance</div>', unsafe_allow_html=True)
        c1, c2, c3, c4 = st.columns(4)
        metric_card(c1, "K01 · Gross merchandise value", brl(kpis.get("k01_gmv")), "R$ 13,449,529.68")
        metric_card(c2, "K02 · Eligible orders", number(k02_orders, 0), "97,910 orders")
        metric_card(c3, "K03 · Average order value", brl(k03_aov), "R$ 160.22")
        metric_card(c4, "K04 · On-time delivery", pct(delivery_kpis.get("k04_on_time")), "93.21%")

        monthly = query_df(
            connection,
            f"""SELECT DATE_FORMAT(f.purchase_ts, '%Y-%m') AS month,
                      SUM(CASE WHEN f.is_sales_eligible = 1 THEN f.items_value ELSE 0 END) AS gmv,
                      COUNT(DISTINCT CASE WHEN f.is_sales_eligible = 1 THEN f.order_id END) AS eligible_orders,
                      100.0 * SUM(CASE WHEN f.is_delivery_kpi_eligible = 1 AND f.is_on_time = 1 THEN 1 ELSE 0 END)
                        / NULLIF(SUM(CASE WHEN f.is_delivery_kpi_eligible = 1 THEN 1 ELSE 0 END), 0) AS on_time_pct
                   FROM olist_dm_test.fact_order_fulfillment f
                   {loc_join}
                   {where}
                   GROUP BY DATE_FORMAT(f.purchase_ts, '%Y-%m')
                   ORDER BY month""",
            params,
        )
        status = query_df(
            connection,
            f"""SELECT os.status_label, COUNT(*) AS orders
               FROM olist_dm_test.fact_order_fulfillment f
               LEFT JOIN olist_dm_test.dim_order_status os ON os.order_status_key = f.order_status_key
               {loc_join}
               {where}
               GROUP BY os.status_label ORDER BY orders DESC""",
            params,
        )
        left, right = st.columns([1.55, 1])
        with left:
            st.markdown('<div class="section-title">Monthly sales and delivery trend</div>', unsafe_allow_html=True)
            if not monthly.empty:
                fig = go.Figure()
                fig.add_trace(go.Bar(x=monthly["month"], y=monthly["gmv"], name="GMV (BRL)", marker_color=BLUE, opacity=0.82, yaxis="y"))
                fig.add_trace(go.Scatter(x=monthly["month"], y=monthly["on_time_pct"], name="On-time delivery (%)", mode="lines+markers", line=dict(color=TEAL, width=3), yaxis="y2"))
                fig.update_layout(
                    title="GMV by purchase month and on-time delivery",
                    yaxis=dict(title="GMV (BRL)", tickprefix="R$ ", separatethousands=True),
                    yaxis2=dict(title="On-time (%)", overlaying="y", side="right", range=[0, 100], ticksuffix="%"),
                    legend=dict(orientation="h", y=1.12, x=0),
                )
                st.plotly_chart(chart_layout(fig, 390), use_container_width=True)
            else:
                chart_empty("No data for the selected filters.")
        with right:
            st.markdown('<div class="section-title">Order status mix</div>', unsafe_allow_html=True)
            if not status.empty:
                fig = px.bar(status, x="orders", y="status_label", orientation="h", text="orders", color="status_label", color_discrete_sequence=PALETTE)
                fig.update_layout(showlegend=False, yaxis_title="", xaxis_title="Orders")
                fig.update_traces(textposition="outside")
                st.plotly_chart(chart_layout(fig, 390), use_container_width=True)
            else:
                chart_empty("No order statuses for the selected filters.")

        st.markdown(
            '<div class="note-card"><b>How to read this page</b><br>'
            'GMV is based on eligible item prices (freight excluded). Average order value uses eligible payment value divided by eligible orders. '
            'Delivery KPIs use delivered orders with a valid delivery date.</div>',
            unsafe_allow_html=True,
        )

    # -------------------------------------------------------------------------
    # PAGE 2 — Delivery performance
    # -------------------------------------------------------------------------
    elif page == "Delivery performance":
        st.markdown('<div class="section-title">Delivery reliability and fulfilment efficiency</div>', unsafe_allow_html=True)
        c1, c2, c3, c4, c5 = st.columns(5)
        metric_card(c1, "K04 · On-time delivery", pct(delivery_kpis.get("k04_on_time")), "93.21%")
        metric_card(c2, "K05 · Average delivery", f"{number(delivery_kpis.get('k05_delivery_days'))} days", "12.54 days")
        metric_card(c3, "K06 · Average late days", f"{number(delivery_kpis.get('k06_late_days'))} days", "10.62 days")
        metric_card(c4, "K07 · Seller dispatch compliance", pct(delivery_kpis.get("k07_dispatch")), "91.06%")
        metric_card(c5, "K08 · Delivery estimate buffer", f"{number(delivery_kpis.get('k08_buffer'))} days", "11.81 days")

        by_state = query_df(
            connection,
            f"""SELECT loc.state_code, loc.state_name,
                      COUNT(DISTINCT CASE WHEN f.is_delivery_kpi_eligible = 1 THEN f.order_id END) AS delivered_orders,
                      100.0 * SUM(CASE WHEN f.is_delivery_kpi_eligible = 1 AND f.is_on_time = 1 THEN 1 ELSE 0 END)
                        / NULLIF(SUM(CASE WHEN f.is_delivery_kpi_eligible = 1 THEN 1 ELSE 0 END), 0) AS on_time_pct,
                      AVG(CASE WHEN f.is_delivery_kpi_eligible = 1 THEN f.delivery_days END) AS avg_delivery_days
                   FROM olist_dm_test.fact_order_fulfillment f
                   LEFT JOIN olist_dm_test.dim_location loc ON loc.location_key = f.customer_location_key
                   {where}
                   GROUP BY loc.state_code, loc.state_name
                   HAVING delivered_orders > 0
                   ORDER BY delivered_orders DESC""",
            params,
        )
        delay_cause = query_df(
            connection,
            f"""SELECT f.delay_cause, COUNT(*) AS late_orders, AVG(f.delay_days) AS avg_delay_days
                   FROM olist_dm_test.fact_order_fulfillment f
                   {loc_join}
                   {where} AND f.is_delivery_kpi_eligible = 1 AND f.is_late = 1 AND f.delay_cause IS NOT NULL
                   GROUP BY f.delay_cause ORDER BY late_orders DESC""",
            params,
        )
        sellers = query_df(
            connection,
            f"""SELECT s.seller_id,
                      COUNT(DISTINCT CASE WHEN si.is_dispatch_on_time IS NOT NULL THEN si.order_id END) AS eligible_dispatch_orders,
                      100.0 * COUNT(DISTINCT CASE WHEN si.is_dispatch_on_time = 1 THEN si.order_id END)
                        / NULLIF(COUNT(DISTINCT CASE WHEN si.is_dispatch_on_time IS NOT NULL THEN si.order_id END), 0) AS dispatch_compliance_pct
                   FROM olist_dm_test.fact_sales_item si
                   JOIN olist_dm_test.fact_order_fulfillment f ON f.order_key = si.order_key
                   JOIN olist_dm_test.dim_seller s ON s.seller_key = si.seller_key
                   {loc_join}
                   {where}
                   GROUP BY s.seller_id
                   HAVING eligible_dispatch_orders > 0
                   ORDER BY eligible_dispatch_orders DESC
                   LIMIT 15""",
            params,
        )
        left, right = st.columns([1.25, 1])
        with left:
            st.markdown('<div class="section-title">On-time delivery by customer state</div>', unsafe_allow_html=True)
            if not by_state.empty:
                fig = px.bar(by_state.sort_values("on_time_pct"), x="on_time_pct", y="state_code", orientation="h", color="on_time_pct", color_continuous_scale=["#D96B6B", "#E6A23C", "#159A91"], hover_data={"state_name": True, "delivered_orders": True, "avg_delivery_days": ":.2f"})
                fig.update_layout(xaxis_title="On-time delivery (%)", yaxis_title="Customer state", coloraxis_showscale=False)
                fig.update_xaxes(range=[0, 100], ticksuffix="%")
                st.plotly_chart(chart_layout(fig, 430), use_container_width=True)
            else:
                chart_empty("No delivery records for the selected filters.")
        with right:
            st.markdown('<div class="section-title">Sources of late delivery</div>', unsafe_allow_html=True)
            if not delay_cause.empty:
                fig = px.pie(delay_cause, names="delay_cause", values="late_orders", hole=0.58, color="delay_cause", color_discrete_map={"seller": BLUE, "carrier": GOLD, "both": RED})
                fig.update_traces(textposition="inside", textinfo="label+percent")
                st.plotly_chart(chart_layout(fig, 430), use_container_width=True)
            else:
                chart_empty("No late-delivery cause records for the selected filters.")

        st.markdown('<div class="section-title">Seller dispatch performance · Top 15 by eligible dispatch orders</div>', unsafe_allow_html=True)
        if not sellers.empty:
            fig = px.bar(sellers, x="dispatch_compliance_pct", y="seller_id", orientation="h", color="dispatch_compliance_pct", color_continuous_scale=["#D96B6B", "#E6A23C", "#159A91"], hover_data={"eligible_dispatch_orders": True})
            fig.update_layout(xaxis_title="Dispatch compliance (%)", yaxis_title="Seller ID", coloraxis_showscale=False)
            fig.update_xaxes(range=[0, 100], ticksuffix="%")
            st.plotly_chart(chart_layout(fig, 470), use_container_width=True)
        else:
            chart_empty("No seller dispatch records for the selected filters.")

        st.caption("K07 uses the earliest shipping deadline per order. Orders with the Q18/Q19 timestamp anomalies are excluded from the dispatch-compliance denominator.")

    # -------------------------------------------------------------------------
    # PAGE 3 — Customer satisfaction
    # -------------------------------------------------------------------------
    else:
        st.markdown('<div class="section-title">Customer experience and repeat behaviour</div>', unsafe_allow_html=True)
        c1, c2, c3, c4 = st.columns(4)
        metric_card(c1, "K09 · Average latest review", f"{number(review_kpis.get('k09_latest_score'))} / 5", "4.09 / 5")
        metric_card(c2, "K10 · Poor review rate", pct(review_kpis.get("k10_poor_rate")), "14.63% · all valid reviews")
        metric_card(c3, "K11 · On-time vs late review gap", f"{number(review_kpis.get('k11_review_gap'))} stars", "2.02 stars")
        metric_card(c4, "K12 · Repeat customer rate", pct(k12), "3.04% · project-wide")

        score_distribution = query_df(
            connection,
            f"""SELECT r.review_score, COUNT(*) AS review_count
                   FROM olist_dm_test.fact_review r
                   JOIN olist_dm_test.fact_order_fulfillment f ON f.order_key = r.order_key
                   {loc_join}
                   {where} AND r.is_latest_for_order = 1
                   GROUP BY r.review_score ORDER BY r.review_score""",
            params,
        )
        score_by_delivery = query_df(
            connection,
            f"""SELECT ds.status_label, ds.status_code,
                      AVG(r.review_score) AS avg_review_score,
                      100.0 * SUM(CASE WHEN r.review_score <= 2 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS poor_review_pct,
                      COUNT(*) AS latest_reviews
                   FROM olist_dm_test.fact_review r
                   JOIN olist_dm_test.fact_order_fulfillment f ON f.order_key = r.order_key
                   JOIN olist_dm_test.dim_delivery_status ds ON ds.delivery_status_key = r.delivery_status_key
                   {loc_join}
                   {where} AND r.is_latest_for_order = 1
                   GROUP BY ds.status_label, ds.status_code
                   ORDER BY avg_review_score DESC""",
            params,
        )
        score_by_duration = query_df(
            connection,
            f"""SELECT CASE
                        WHEN f.delivery_days <= 7 THEN '0–7 days'
                        WHEN f.delivery_days <= 14 THEN '8–14 days'
                        WHEN f.delivery_days <= 21 THEN '15–21 days'
                        ELSE '22+ days' END AS delivery_band,
                      AVG(r.review_score) AS avg_review_score,
                      COUNT(*) AS latest_reviews
                   FROM olist_dm_test.fact_review r
                   JOIN olist_dm_test.fact_order_fulfillment f ON f.order_key = r.order_key
                   {loc_join}
                   {where} AND r.is_latest_for_order = 1 AND f.is_delivery_kpi_eligible = 1
                   GROUP BY delivery_band
                   ORDER BY MIN(f.delivery_days)""",
            params,
        )
        left, right = st.columns([1, 1.25])
        with left:
            st.markdown('<div class="section-title">Latest review score distribution</div>', unsafe_allow_html=True)
            if not score_distribution.empty:
                fig = px.bar(score_distribution, x="review_score", y="review_count", text="review_count", color="review_score", color_continuous_scale=["#D96B6B", "#E6A23C", "#159A91"])
                fig.update_layout(xaxis_title="Review score (1–5)", yaxis_title="Latest reviews", coloraxis_showscale=False)
                fig.update_xaxes(dtick=1)
                fig.update_traces(textposition="outside")
                st.plotly_chart(chart_layout(fig, 360), use_container_width=True)
            else:
                chart_empty("No latest reviews for the selected filters.")
        with right:
            st.markdown('<div class="section-title">Review score by delivery outcome</div>', unsafe_allow_html=True)
            if not score_by_delivery.empty:
                fig = px.bar(score_by_delivery, x="status_label", y="avg_review_score", color="status_code", text=score_by_delivery["avg_review_score"].round(2), color_discrete_map={"ON_TIME": TEAL, "LATE": RED, "NOT_DELIVERED": MUTED, "INCONSISTENT": GOLD}, hover_data={"latest_reviews": True, "poor_review_pct": ":.2f"})
                fig.update_layout(xaxis_title="Delivery status", yaxis_title="Average review score")
                fig.update_yaxes(range=[0, 5.3])
                fig.update_traces(textposition="outside")
                st.plotly_chart(chart_layout(fig, 360), use_container_width=True)
            else:
                chart_empty("No review outcomes for the selected filters.")

        st.markdown('<div class="section-title">Average review score by delivery time</div>', unsafe_allow_html=True)
        if not score_by_duration.empty:
            fig = px.bar(score_by_duration, x="delivery_band", y="avg_review_score", text=score_by_duration["avg_review_score"].round(2), color="avg_review_score", color_continuous_scale=["#D96B6B", "#E6A23C", "#159A91"], hover_data={"latest_reviews": True})
            fig.update_layout(xaxis_title="Purchase-to-delivery time", yaxis_title="Average latest review score", coloraxis_showscale=False)
            fig.update_yaxes(range=[0, 5.3])
            fig.update_traces(textposition="outside")
            st.plotly_chart(chart_layout(fig, 340), use_container_width=True)
        else:
            chart_empty("No delivered reviews for the selected filters.")

        st.markdown(
            '<div class="note-card"><b>Interpretation note</b><br>'
            'K09 and K11 use the latest review per order. K10 uses all valid review rows. '
            'K12 is project-wide and does not change with the date or location filters.</div>',
            unsafe_allow_html=True,
        )

    st.divider()
    st.caption("GR05 · Olist BI & Big Data Analytics · Source: validated MySQL Data Mart (olist_dm_test). Dashboard queries are read-only.")

except mysql.connector.Error as exc:
    st.error(f"Could not read the Data Mart: {exc}")
    st.info("Check that MySQL is running and that database `olist_dm_test` contains the successful Data Mart ETL run 12.")
except Exception as exc:  # Keep a helpful message visible rather than a blank app.
    st.exception(exc)
finally:
    if connection is not None and connection.is_connected():
        connection.close()
