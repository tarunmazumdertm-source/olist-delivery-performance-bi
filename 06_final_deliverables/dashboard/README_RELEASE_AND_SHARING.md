# GR05 Olist — Data validation and local dashboard sharing

## What this release changes

- Restores the dashboard's earlier (pre-responsive redesign) layout.
- Keeps the existing KPI definitions and chart queries unchanged.
- Adds optional server-side MySQL secrets support. When `.streamlit/secrets.toml` exists, every browser session uses the private server-side connection settings; viewers do not need to enter the database password.
- Adds a read-only Data Mart audit SQL script.
- Adds a local-network launch script for a team meeting on the same trusted Wi-Fi.

## A. Restore the previous dashboard layout

This package places the restored file at:

`06_final_deliverables/dashboard/app.py`

It keeps the earlier layout and only adds optional secret-based connection settings for shared sessions. It does not include the later responsive CSS changes.

## B. Audit the Data Mart before changing records

Run the read-only script:

`05_data_warehouse/validation/GR05_Olist_final_data_audit.sql`

From the `Olist_Project` root:

```bash
mysql -u root --show-warnings < 05_data_warehouse/validation/GR05_Olist_final_data_audit.sql
```

It validates the known Data Mart row populations, K01–K12 baselines, documented data-quality exceptions, six important fact-to-dimension relationships and the latest DM ETL run.

Do not edit the raw Kaggle CSV files or delete flagged rows just to make the data look clean. Preserve the source data and resolve issues in ETL rules only when the audit shows a real transformation defect.

Key rules to preserve:

- K02 counts eligible orders by status, including the five eligible orders without order items.
- K09 and K11 use the latest review per order.
- K10 uses all valid reviews in scope, not latest-only reviews.
- K07 excludes Q18/Q19 timestamp anomalies through the null dispatch eligibility flag.
- Repeated review IDs, multiple reviews, empty comments, zero freight/payment values and missing coordinates are treated according to the DQ register; they are not all reasons to delete source rows.

## C. Create a read-only MySQL user

Use a strong unique password in place of the placeholder. Run in MySQL as an administrator:

```sql
CREATE USER IF NOT EXISTS 'olist_dashboard'@'127.0.0.1'
IDENTIFIED BY 'REPLACE_WITH_A_LONG_RANDOM_PASSWORD';
GRANT SELECT ON olist_dm_test.* TO 'olist_dashboard'@'127.0.0.1';
GRANT SELECT ON olist_meta_test.etl_run TO 'olist_dashboard'@'127.0.0.1';
SHOW GRANTS FOR 'olist_dashboard'@'127.0.0.1';
```

This user can read only the Data Mart and ETL run status needed by the app. Do not use MySQL `root` for a shared demonstration.

## D. Create the local secrets file

Copy `.streamlit/secrets.toml.example` to `.streamlit/secrets.toml`, then place the same password used for `olist_dashboard` in the file. The actual `secrets.toml` is ignored by Git.

The app checks for this file on each new browser session. Viewers on your Wi-Fi will then see the dashboard without entering MySQL credentials.

## E. Start a same-Wi-Fi team share

Activate the existing environment and start from `Olist_Project`:

```bash
conda activate hfu_ml
bash 06_final_deliverables/dashboard/scripts/start_dashboard_lan.sh
```

The terminal prints a URL for the Mac and a URL using the Mac's Wi-Fi IP. Share the Wi-Fi URL with teammates on the same trusted network.

Requirements and limitations:

- The Mac must remain awake and connected to Wi-Fi.
- Streamlit must remain running; stop it with `Ctrl+C` after the meeting.
- macOS may ask to allow incoming connections for Python. Allow this only on a trusted private network; keep the macOS firewall on.
- Do not enable router port forwarding or expose port 8501 directly to the public internet.
- This share is suitable for a classroom/team meeting on the same local network, not for remote access from other networks.

## F. Remote access later

For a stable remote URL, deploy to Streamlit Community Cloud or another host. Cloud deployment needs a database endpoint reachable from that host; it cannot reach `127.0.0.1` on your Mac. Use a managed/hosted database or secure VPN architecture. Do not expose local MySQL or root credentials to the internet.

Official Streamlit references:

- Server config: https://docs.streamlit.io/develop/api-reference/configuration/config.toml
- Community Cloud deploy: https://docs.streamlit.io/deploy/streamlit-community-cloud/deploy-your-app/deploy
- App sharing: https://docs.streamlit.io/deploy/streamlit-community-cloud/share-your-app
- Secrets: https://docs.streamlit.io/deploy/streamlit-community-cloud/deploy-your-app/secrets-management
