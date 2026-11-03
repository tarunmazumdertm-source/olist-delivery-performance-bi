# Project Charter

## 1. Project identity

| Item | Baseline |
|---|---|
| Project group | GR05 |
| Programme / module | AIM — Business Intelligence & Big Data |
| Semester | WiSe 2026/27 |
| Project title | **From Order to Review: How delivery performance affects customer satisfaction and sales** |
| Business domain | Online retail / e-commerce marketplace |
| Case organisation | Olist, a Brazilian marketplace integrator |
| Current planning boundary | Milestone Presentation — **13 November 2026 (Week 46)** |

## 2. Project background and problem

The Olist source data is distributed across related CSV files. The project proposal identifies the need for a single, trusted view of sales, delivery performance and customer satisfaction. The analysis will examine whether delivery performance is associated with customer reviews and sales outcomes.

The project title retains the wording from the approved proposal. In analytical conclusions, the team will use association/relationship language unless the method provides evidence for a causal claim.

## 3. Main research question

**How is delivery performance associated with customer satisfaction and sales outcomes in the Olist e-commerce marketplace?**

This analytical wording retains all three dimensions in the proposal while avoiding an unsupported causal interpretation.

## 4. Intended value

- Organise the nine related Olist source tables into a documented analytical foundation.
- Define and validate the 12-KPI working catalogue.
- Analyse delivery timeliness, delivery duration and seller dispatch performance.
- Examine customer review outcomes in relation to delivery performance.
- Compare order and sales indicators across relevant groups.
- Provide a foundation for the proposed warehouse, BI dashboard and poor-review risk model in the overall project.

## 5. Dataset and analysis period

- **Dataset:** Brazilian E-Commerce Public Dataset by Olist, distributed through Kaggle.
- **Source URL:** https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
- **Source profile:** 9 CSV files; 99,441 orders; 1,550,922 rows in total across the nine tables, based on the acquired-file counts.
- **Full period represented:** 2016–2018, according to the source documentation.
- **Project analysis scope:** Orders with `order_purchase_timestamp` from **1 January 2017 through 31 August 2018**, inclusive.
- **In-scope order count reported by Aimen:** 99,092. This is a profiling result to reproduce before final reporting.
- **KPI order count reported by Aimen:** 97,905 for K02, after excluding cancelled and unavailable orders under the proposed KPI definition. This is a different population from all in-scope orders.
- **Storage:** Original CSV files are kept in the shared Google Drive folder. GitHub stores project documentation, notebooks and code, not the full raw CSV set.

## 6. KPI framework

Aimen has supplied a 12-KPI catalogue covering Sales (K01–K03), Delivery (K04–K08), Satisfaction (K09–K11) and Customer behaviour (K12). The catalogue, formulas, reported baselines, proposed targets and validation notes are maintained in `09_KPI_Catalogue_and_Validation_Notes.md`.

The initial 10-KPI draft in the first EDA notebook should be replaced by this 12-KPI working catalogue. Reported baselines remain provisional until independently recalculated from the source data.

## 7. Current milestone objective

By the 13 November 2026 milestone presentation, the team is preparing the source inventory, initial EDA report, schema diagrams (ERD), SQL DDL for the warehouse schema, presentation/demo and feedback log. The specific Week 44 and Week 46 deliverables are listed in `04_Milestone_Plan_to_13_Nov_2026.md`.

## 8. Team and repository governance

Named workstream ownership remains:

- Monica — data acquisition and source documentation.
- Aimen — data dictionary and data quality profiling.
- Tarun — EDA and maintenance of the GitHub project repository.
- Laura — data warehouse design and SQL.

Tarun maintains and updates the GitHub repository. Other team members use it to view and review shared material and provide feedback; they are not expected to manage branches or commit files under the current arrangement.

## 9. Change control

This baseline records the current position as of **3 November 2026**. The project topic, team ownership, source dataset and 13 November milestone have not changed. The KPI catalogue and data-structure understanding have been refined based on Aimen's deliverables. Any later scope, KPI or method change should be recorded in `06_Decision_Log.md`.
