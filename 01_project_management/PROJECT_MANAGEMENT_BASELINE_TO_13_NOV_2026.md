# GR05 Project Management Baseline
## From Order to Review — How delivery performance affects customer satisfaction and sales

**Programme:** AIM — Business Intelligence & Big Data  
**Semester:** WiSe 2026/27  
**Group:** GR05  
**Baseline update date:** 3 November 2026  
**Planning boundary:** Milestone Presentation — **13 November 2026 (Week 46)**

> This document records the current project baseline through the 13 November 2026 milestone only. The next phase will be planned after reviewing the milestone presentation and its feedback.

## 1. Project overview and analytical framing

The project studies the customer journey from order to delivery to review using the Olist Brazilian e-commerce dataset. The proposal identifies that sales, delivery and review data are distributed across files and that the relationship between late deliveries and review scores needs to be quantified.

**Analytical research question:** How is delivery performance associated with customer satisfaction and sales outcomes in the Olist e-commerce marketplace?

The project title remains as approved in the proposal. The analysis should report associations and patterns supported by the historical data; it should not claim causation without an appropriate causal design.

## 2. Dataset, scope and tools

- **Business domain:** Online retail / e-commerce marketplace.
- **Case:** Olist, a Brazilian marketplace integrator.
- **Dataset:** Brazilian E-Commerce Public Dataset by Olist, distributed through Kaggle: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
- **Source data:** 9 CSV tables; 99,441 orders; 1,550,922 rows in total across tables, matching the acquired-file counts reported in Monica's inventory and Aimen's profiling.
- **Full source period:** 2016–2018 according to source documentation.
- **Analysis scope:** Purchase timestamp from 1 January 2017 through 31 August 2018 inclusive.
- **Aimen-reported in-scope orders:** 99,092. Reproduce before final reporting.
- **Aimen-reported K02 eligible orders:** 97,905 after excluding cancelled and unavailable statuses. This is not the same population as all in-scope orders.
- **Database:** MySQL 8.4 LTS / MySQL Workbench.
- **BI:** Power BI Desktop.
- **Analysis / development:** Python, Pandas, Jupyter Notebook and Visual Studio Code.
- **Repository:** GitHub maintained by Tarun.
- **Raw data storage:** Shared Google Drive: https://drive.google.com/drive/folders/18UaKUi23RyLpWwP0VCfA8H8RE5AjFkVw
- **Licence recorded in Monica's source documentation:** CC BY-NC-SA 4.0. Provide attribution and review licence terms before redistributing adapted material.

## 3. Business problem, objectives and outcomes

The project aims to bring order, delivery, sales and review information into a documented analytical foundation. The overall proposal objectives remain:

1. Build a MySQL star-schema warehouse from all nine source files.
2. Define and validate at least 12 relevant KPIs.
3. Create an interactive Power BI dashboard.
4. Build a model to flag orders at risk of a 1–2-star review.

The overall expected outcomes are a documented data warehouse, validated KPI catalogue, interactive dashboard and poor-review risk model. They are not all due by the 13 November milestone.

## 4. Refined KPI framework

Aimen supplied a 12-KPI working catalogue:

- **Sales:** K01 GMV; K02 number of orders; K03 average order value.
- **Delivery:** K04 on-time delivery rate; K05 average delivery time; K06 average delay of late orders; K07 seller dispatch compliance; K08 delivery estimate buffer.
- **Satisfaction:** K09 average review score; K10 poor review rate; K11 review gap between on-time and late orders.
- **Customer:** K12 repeat customer rate.

Full formulas, reported baselines, proposed targets and open validation questions are in `09_KPI_Catalogue_and_Validation_Notes.md`. Aimen's baselines are provisional until independently recalculated. Important unresolved definitions include K03 population, K07 order-level aggregation of item-level shipping deadlines, K08 sign interpretation and duplicate-review treatment for K09–K11.

## 5. Data structure and quality baseline

Aimen's data dictionary documents 52 attributes across nine source tables. The model identifies order, item, payment, review, customer, seller, product, category translation and geolocation tables.

Key safeguards:

- Order items use the composite key `order_id` + `order_item_id`.
- Payments use the composite key `order_id` + `payment_sequential`.
- More than one review can occur for an order; `review_id` is not unique in Aimen's profile.
- `customer_unique_id` identifies a person across order-specific `customer_id` values.
- Geolocation ZIP prefixes are repeated and cannot be joined as if they were unique; aggregate geolocation before joining.
- Read ZIP prefixes as five-character text to preserve leading zeros.
- Aggregate item and payment tables to the required grain before combining them with order-level data to avoid join fan-out.

Reported high-priority quality issues include missing delivery dates, duplicate/multiple reviews, missing product categories/translations, geolocation duplicates and ZIP-prefix ambiguity. See `10_Data_Model_and_Analysis_Rules.md` for details. These are Aimen-reported profiling results and require reproduction before final validation.

## 6. Team ownership and hand-offs

| Member | Workstream | Current evidence / expected output |
|---|---|---|
| Monica | Data acquisition | Source documentation, inventory and shared raw-data location received. |
| Aimen | Data dictionary and data quality | Dictionary workbook, profiling/KPI presentation and Python script received. |
| Tarun | EDA and GitHub repository maintenance | Stage 1 and Stage 2 notebook work committed; Stage 3 is in progress. EDA notebook, KPI validation and report are expected. |
| Laura | Data warehouse design and SQL | ERD, star schema and SQL DDL expected; current progress not confirmed in the materials reviewed for this update. |

Aimen's dictionary/quality work supports Tarun's analysis and Laura's schema. Tarun's KPI and analysis grain requirements should be aligned with Laura's warehouse design.

**Repository arrangement:** Tarun maintains GitHub. Other members view/review the shared project material and provide feedback; they are not expected to create branches or commit under the current arrangement. Raw CSVs remain on Google Drive, not GitHub.

## 7. Milestones through 13 November 2026

| Week | Proposal deliverables | Workstream alignment |
|---|---|---|
| 42 | RDBMS and BIA tool; initial business understanding; roles; milestones; risk matrix; success criteria. | Whole team. |
| 44 | Data source inventory; EDA report; schema diagrams (ERD); SQL DDL for warehouse schema. | Monica — acquisition/inventory; Aimen — dictionary/profiling; Tarun — EDA; Laura — ERD/DDL. |
| 46 | Milestone presentation, slides/demo and feedback log. | All workstreams contribute; presentation on 13 November 2026. |

### Status snapshot — 3 November 2026

- Project topic and business understanding documented; Stage 1 notebook committed.
- All nine source tables loaded in Tarun's notebook; Stage 2 summary created and committed.
- Monica's source documentation and data access information recorded in GitHub; raw CSVs kept in Google Drive.
- Aimen's dictionary, profiling workbook, KPI presentation and script received and committed to GitHub.
- Tarun's Stage 3 variable/relationship exploration is in progress; the initial 10-KPI draft needs replacement with the 12-KPI catalogue.
- Laura's ERD/DDL status needs confirmation.
- Milestone slides, demo and feedback log remain to be prepared.

## 8. Risks

The proposal's original risks R1–R8 remain. Three additional risks have been added based on Aimen's findings:

- **R9 — Join fan-out / grain mismatch:** Multiple item, payment or review rows and repeated geolocation ZIP prefixes may inflate measures. Aggregate to the required grain before joining.
- **R10 — KPI definitions/baselines not reproducible:** Record populations, denominators and exclusions; recalculate and reconcile Aimen's reported values.
- **R11 — Review duplicates/multiple reviews per order:** Validate the proposed latest-review-per-order rule and keep separate definitions for K09, K10 and K11 if their populations differ.

See `05_Risk_Register_and_Mitigations.md` for the full register.

## 9. Current milestone evidence

- Source inventory and shared raw-data access.
- Data dictionary and initial data-quality overview.
- Initial EDA notebook and report; KPI framework and any recalculated values clearly labelled as validated or provisional.
- ERD and initial star-schema design.
- SQL DDL for the proposed schema.
- Presentation slides, demo and feedback log.

The team should not present Aimen's reported baselines as independently verified unless Tarun reproduces them or documents an agreed reason for any difference.

## 10. Boundary and next update

This baseline stops at the **13 November 2026 Milestone Presentation**. After that presentation, the team will review feedback, agree priorities and prepare the next project plan. No detailed post-milestone plan is included here.

## 11. Source basis

- GR05 project proposal presentation: project background, scope, objectives, tools, functional role model, milestone plan, risk matrix and success criteria.
- Monica, `Data Source Documentation.xlsx`: dataset source, licence, provenance and inventory.
- Aimen, `Data Dictionary & Profiling.xlsx`: 52-attribute dictionary, profiling, issue log, relationships and KPI catalogue.
- Aimen, `Data Dictionary_Profiling + KPIs.pptx`: source model, quality summary, preparation issues and 12 KPI summary.
- Aimen, `olist-profiling.py`: profiling implementation reference.
- Team discussion: named workstream ownership and GitHub repository maintenance arrangement.
