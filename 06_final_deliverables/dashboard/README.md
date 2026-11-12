# GR05 Olist Streamlit Dashboard

Interactive dashboard for the project question:

> How does delivery performance affect customer satisfaction and sales?

The app connects directly to the existing local MySQL Data Mart (`olist_dm_test`). It does not use Power BI, Excel upload, SharePoint, OneDrive, or a cloud database.

## Contents

- `app.py` — three-page Streamlit dashboard
- `requirements.txt` — Python dependencies
- `.streamlit/config.toml` — dashboard theme

## Requirements

- macOS with Python/Conda
- MySQL Community Server running locally
- Successful Data Mart load in `olist_dm_test` (validated run 12)
- Python packages: Streamlit, pandas, Plotly, MySQL Connector/Python

## Setup

Open Terminal in the `Olist_Project` folder and activate the existing environment:

```bash
conda activate hfu_ml
```

Install dependencies if needed:

```bash
python -m pip install -r 06_final_deliverables/dashboard/requirements.txt
```

## Run

From the `Olist_Project` folder:

```bash
streamlit run 06_final_deliverables/dashboard/app.py
```

Streamlit will show a local address, usually `http://localhost:8501`. Open it in Chrome.

In the left sidebar, enter your MySQL connection details:

- Host: `127.0.0.1`
- Port: `3306`
- User: `root`
- Password: your local MySQL password (leave blank if none)
- Database: `olist_dm_test`

The app tests the connection and then loads the dashboard. Credentials are kept in the Streamlit session state for the local session and are not written into this project folder.

## Dashboard pages

1. **Executive overview** — GMV, eligible orders, average order value, on-time delivery, monthly trend and order status mix.
2. **Delivery performance** — delivery KPIs K04–K08, state-level on-time performance, delay causes and seller dispatch compliance.
3. **Customer satisfaction** — K09–K12, latest review distribution, review score by delivery outcome and delivery duration.

## KPI definitions and baselines

| KPI | Rule used by this app | EDA baseline |
|---|---|---:|
| K01 GMV | Sum of eligible item prices; freight excluded | R$ 13,449,529.68 |
| K02 Eligible orders | Distinct orders not canceled/unavailable; item presence is not required | 97,910 |
| K03 Average order value | Eligible payment value / K02 eligible orders | R$ 160.22 |
| K04 On-time delivery | On-time delivered orders / delivered orders with valid delivery date | 93.21% |
| K05 Average delivery time | Average purchase-to-delivery days for delivery-KPI-eligible orders | 12.54 days |
| K06 Average late days | Average delay days for late, delivery-KPI-eligible orders | 10.62 days |
| K07 Seller dispatch compliance | On-time dispatch / records with non-null dispatch flag; earliest shipping deadline; Q18/Q19 anomalies excluded | 91.06% |
| K08 Delivery estimate buffer | Average estimated date minus actual delivery date for delivery-KPI-eligible orders | 11.81 days |
| K09 Average latest review score | Average review score for latest review per order | 4.09 |
| K10 Poor review rate | Reviews with score <= 2 / all valid reviews | 14.63% |
| K11 On-time vs late review gap | Latest-review average score for on-time orders minus late orders | 2.02 stars |
| K12 Repeat customer rate | Customers with 2+ eligible orders / customers with at least 1 eligible order; project-wide | 3.04% |

## Filters and interpretation

- Purchase date, customer region and customer state filters apply to the order-based measures and charts.
- K12 remains project-wide because customer repeat status is defined across the complete approved project scope, not a selected purchase-date slice.
- K07 excludes the event-date anomalies Q18 and Q19 through the non-null dispatch eligibility flag.
- K09 and K11 use the latest review per order.
- K10 uses all valid review rows, not latest-only rows.
- The app does not add another date scope. The Data Mart is already restricted to the approved project population.

## Security and data handling

- The app runs locally on the user's Mac by default.
- It only issues `SELECT` statements. It does not insert, update, or delete database records.
- Do not publish the app to a public host with a local root database account. For shared deployment, create a dedicated read-only MySQL user and use a secure network/VPN or managed database connection.
- Never commit passwords, `.env` files or `secrets.toml` containing credentials to GitHub.

## Current limitations

- This local app is for development and screen-sharing. Other team members cannot open `localhost` on their own devices. Shared hosted use requires deployment and a database reachable from that host.
- No map is currently shown; state-level delivery analysis is presented as a ranked chart.
