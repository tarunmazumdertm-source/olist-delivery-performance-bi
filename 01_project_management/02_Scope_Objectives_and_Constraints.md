# Project Scope, Objectives, Outcomes and Constraints

## 1. Overall project scope from the proposal

- Olist orders in the project analysis period: 1 January 2017 to 31 August 2018.
- MySQL staging area and star-schema data warehouse.
- Power BI Desktop dashboard.
- Predictive model to flag orders at risk of a 1–2-star review.
- Use of all nine Olist source tables.

## 2. Overall project objectives from the proposal

1. Build a MySQL star-schema warehouse from all nine source files.
2. Define and validate at least 12 relevant KPIs.
3. Create an interactive Power BI dashboard.
4. Build a model that flags orders at risk of a poor review (1–2 stars).

These are overall project objectives. They are not all expected to be complete by the 13 November milestone.

## 3. Refined analytical scope

The business analysis covers four connected areas:

| Area | Analysis focus | KPI coverage |
|---|---|---|
| Sales | GMV, eligible order volume and average order value | K01–K03 |
| Delivery | On-time performance, delivery duration, delay, seller dispatch and estimate buffer | K04–K08 |
| Satisfaction | Average score, poor-review rate and score difference between on-time and late orders | K09–K11 |
| Customer | Repeat-customer rate using `customer_unique_id` | K12 |

The analysis should use the agreed order-purchase date scope. Different KPIs can have different eligible populations (for example, delivery KPIs require a valid delivered date; review KPIs require review records; sales KPIs follow their stated status exclusions). Do not apply one population filter blindly to every KPI.

## 4. Objectives for the current milestone — 13 November 2026

- Maintain the agreed business understanding and research question.
- Document the source inventory, provenance and access location for the nine CSV files.
- Use Aimen's data dictionary and initial profiling as the reference for table meanings, keys and quality issues.
- Prepare an initial EDA notebook/report that explains the analytical variables, key relationships and initial KPI results or calculation readiness.
- Prepare the ERD, proposed star-schema design and SQL DDL.
- Prepare and deliver the milestone presentation and demo, and record feedback.

## 5. KPI definition status

The 12 KPIs in Aimen's catalogue are the working KPI framework. Her reported baselines and team-proposed targets are recorded in `09_KPI_Catalogue_and_Validation_Notes.md`.

The catalogue is not considered fully validated until:

- KPI populations and exclusions are explicit.
- The data grain and join path are defined.
- Multiple item, payment or review rows cannot inflate order-level measures.
- Aimen's baseline values are independently reproduced or documented differences are explained.
- Ambiguous formulas (especially K03, K07, K08 and review deduplication for K09–K11) are agreed.

## 6. Constraints and technology

- Limited project time.
- Free tools only for the proposed database and BI solution: MySQL Community and Power BI Desktop.
- Standard laptop hardware.
- Power BI Desktop runs on Windows only; the team must confirm the workable setup.
- Static, anonymised historical data from 2016–2018.
- Geolocation table is large and contains repeated ZIP prefixes; aggregate it before joining to customer/seller tables.
- The source dataset is licensed CC BY-NC-SA 4.0 according to Monica's source documentation. Review the licence terms and provide attribution when sharing derived material.

## 7. Working tools and data storage

- **Database:** MySQL 8.4 LTS, managed with MySQL Workbench (proposal choice).
- **BI:** Power BI Desktop (proposal choice).
- **Analysis and development:** Python, Pandas, Jupyter Notebook and Visual Studio Code.
- **Version control/documentation:** GitHub, maintained by Tarun.
- **Raw data storage:** Shared Google Drive folder: https://drive.google.com/drive/folders/18UaKUi23RyLpWwP0VCfA8H8RE5AjFkVw
- **GitHub content:** Documentation, inventory, notebooks, scripts and SQL. Raw source CSV files remain in Google Drive to avoid repository storage and file-size issues.

## 8. Scope control through the milestone

This document stops at the 13 November 2026 milestone. A detailed plan for later ETL, dashboard, predictive modelling and final presentation work will be prepared after the team reviews the milestone feedback.
