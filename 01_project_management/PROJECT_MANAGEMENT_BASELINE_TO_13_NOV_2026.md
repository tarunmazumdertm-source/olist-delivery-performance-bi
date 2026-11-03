# GR05 Project Management Baseline
## From Order to Review — How delivery performance affects customer satisfaction and sales

**Programme:** AIM — Business Intelligence & Big Data  
**Semester:** WiSe 2026/27  
**Group:** GR05  
**Baseline date:** 3 November 2026  
**Planning boundary:** Milestone Presentation — 13 November 2026 (Week 46)

> This document records the current project baseline through the 13 November 2026 milestone only. Planning for later work will be added after the team reviews the milestone presentation and its feedback.

## 1. Project overview

The project studies the customer journey from order to delivery to review using the Olist Brazilian e-commerce dataset. The proposal identifies that Olist's sales, delivery and review data are spread across files and that the effect of late deliveries on review scores has not been quantified.

**Main project question:** How does delivery performance affect customer satisfaction and sales?

The analysis will examine relationships supported by the historical data. An observed association should not automatically be described as a causal effect.

## 2. Business domain, dataset and tools

- **Business domain:** Online retail / e-commerce marketplace.
- **Case:** Olist, a Brazilian marketplace integrator.
- **Dataset:** Public Olist Brazilian e-commerce dataset listed on Kaggle.
- **Proposal dataset profile:** 99,441 orders, 9 source CSV files and approximately 1.55 million rows. These figures must be checked against the acquired files.
- **Analysis period in the proposal:** Orders from January 2017 to August 2018.
- **Database:** MySQL 8.4 LTS, managed with MySQL Workbench.
- **BI tool:** Power BI Desktop.
- **Team working tools:** GitHub, Visual Studio Code, Python and Jupyter Notebook for collaboration and analysis.
- **Dataset source:** https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce/data

## 3. Problem, scope and objectives

### Problem

The proposal states that Olist lacks a single, trusted view of how sales, delivery performance and customer satisfaction relate. The information is distributed across files, and the effect of late deliveries on review scores has not been quantified.

### Scope in the proposal

- Orders from January 2017 to August 2018.
- MySQL staging area and star-schema data warehouse.
- Power BI Desktop dashboard.
- Predictive model to flag orders at risk of a 1–2-star review.
- Use of all nine source files.

### Objectives in the proposal

1. Build a MySQL star-schema warehouse from all nine source files.
2. Define and validate at least 12 relevant KPIs.
3. Create an interactive Power BI dashboard.
4. Build a model that flags orders at risk of a poor review.

### Expected outcomes in the proposal

- Documented data warehouse.
- Validated KPI catalogue.
- Interactive dashboard.
- Predictive model for poor-review risk.

### Constraints

- Limited time.
- Free tools only: MySQL Community and Power BI Desktop.
- Standard laptops.
- Power BI Desktop runs on Windows only; the team must confirm the workable setup.
- Static, anonymised historical data from 2016–2018.

These are overall project scope and outcome statements. They are not all deliverables for the 13 November milestone.

## 4. Team ownership

The following named workstream allocation is the current team agreement and has not changed:

| Member | Workstream | Current expected output |
|---|---|---|
| Monica | Data acquisition | Source inventory, dataset provenance and organised raw source files / access location. |
| Aimen | Data dictionary and data quality | Attribute definitions, data types, candidate keys, initial profiling and quality summary. |
| Tarun | EDA | Reproducible Python/Jupyter notebook(s) and EDA report. |
| Laura | Data warehouse design and SQL | ERD, initial star-schema design and SQL DDL. |

### Dependencies

Monica's source files and inventory enable the other workstreams. Aimen's definitions and quality findings support both Tarun's interpretation and Laura's data model. Tarun's analysis needs and KPIs should be discussed with Laura when defining the warehouse grain, dimensions and measures. All four workstreams contribute to the milestone presentation and demo.

### Functional role model in the proposal

The proposal describes PM (Project Manager & Business Analyst), DE (Data Engineer), BI (BI Developer) and DS (Data Scientist & QA Lead). It defines responsibilities for each role but does not name the person assigned to each role. This baseline therefore keeps these functional roles separate from the named task allocation above.

## 5. Milestone plan through 13 November 2026

| Week | Deliverables in the proposal | Current working ownership |
|---|---|---|
| 42 | RDBMS and BIA tool; initial business understanding; roles; milestones; risk matrix; success criteria. | Whole team; coordinated as a group. |
| 44 | Data source inventory; EDA report; schema diagrams (ERD); SQL DDL for warehouse schema. | Monica — source inventory; Aimen — dictionary / profiling; Tarun — EDA; Laura — ERD / SQL DDL. |
| 46 | Milestone presentation: slides and demo; feedback log. | PM coordinates; all members contribute. Presentation date: **13 November 2026**. |

### Evidence expected for the Week 46 milestone

- Source inventory and access to the source data.
- Initial data dictionary and data-quality overview.
- Initial EDA notebook and report.
- ERD and initial warehouse design.
- SQL DDL for the proposed warehouse schema.
- Presentation slides, demo and feedback log.

The team should state clearly which items are complete, partial or still open. This baseline does not claim that any work is complete without confirmation.

## 6. Risk register

| ID | Risk | Planned response | Functional owner in proposal |
|---|---|---|---|
| R1 | Issues connecting Power BI to MySQL. | Test 64-bit Connector/NET; fallback to ODBC or CSV export. | DE |
| R2 | Data-quality issues slow the ETL. | Profile all files; use documented rules and automated tests. | DS |
| R3 | Scope creep. | Freeze KPI catalogue at M3; use MoSCoW priorities; allow approved changes only. | PM |
| R4 | Team availability / uneven workload. | Weekly stand-up; keep a one-week buffer before the final presentation. | PM |
| R5 | Laptop performance limit. | Aggregate geolocation by ZIP prefix; use Import mode; drop unused columns. | DE |
| R6 | Originality concerns. | Use a distinct order-to-review angle, own KPIs and model. | PM |
| R7 | Predictive model underperforming. | Start with a simple baseline; use interpretable features; report honestly. | DS |
| R8 | Loss of files or version conflicts. | Versioned folder for `.pbix`; weekly backups. | DE |

The proposal's risk matrix does not provide explicit probability and impact labels. No numeric risk scores are added here.

## 7. Overall success criteria in the proposal

These are overall project targets, not all targets due at the current milestone:

| Area | Proposal target |
|---|---|
| Data and ETL | 100% of source rows loaded, or logged with a reason. |
| KPI catalogue | 12 KPIs documented with formula, owner and target. |
| Dashboard usability | 80% task success in a usability test with 5 peers. |
| Analytics model | Minimum AUC of 0.7 for the low-review classifier on unseen test data. |

## 8. Team collaboration and document control

- The GitHub repository is the shared version-controlled location for project code and documentation.
- Keep the `main` branch as the agreed shared baseline.
- Each member should work on their own branch and submit changes using Pull Requests.
- Use GitHub Issues / Projects to track live task status.
- Do not commit the raw Olist CSV files to GitHub; store them in the team's agreed shared storage and keep source/access information in the repository.
- Record decisions, blockers and changes in this project-management folder.

## 9. Milestone boundary and next update

This document stops at the **13 November 2026 Milestone Presentation**. After the presentation, the team should review feedback, agree the next work phase and update the project-management baseline. No post-milestone work plan is included here.

## 10. Proposal source

Prepared from the uploaded GR05 proposal presentation, `GR05_Redesigned_Presentation(1).pptx`:

- Slides 1–2: project title, group and agenda.
- Slide 3: business domain, tools and dataset profile.
- Slide 4: business terms.
- Slide 5: problem, scope, objectives, expected outcomes and constraints.
- Slide 6: functional roles and responsibilities.
- Slide 7: milestone weeks and deliverables; dates for the milestone and final presentation.
- Slides 8–9: risk matrix and mitigation plan.
- Slide 10: overall success criteria.

Named team ownership and the GitHub working approach are based on the team's project setup discussion, not on named assignments in the proposal slides.
