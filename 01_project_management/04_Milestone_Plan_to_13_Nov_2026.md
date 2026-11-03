# Milestone Plan — Through 13 November 2026

## 1. Proposal milestone sequence

| Week | Proposal deliverables | Named workstream lead / contributors |
|---|---|---|
| 42 | RDBMS and BIA tool; initial business understanding; roles; milestones; risk matrix; success criteria. | Whole team. |
| 44 | Data source inventory; EDA report; schema diagrams (ERD); SQL DDL for warehouse schema. | Monica — source inventory; Aimen — data dictionary/profiling; Tarun — EDA; Laura — ERD/SQL DDL. |
| 46 | Milestone presentation: slides and demo; feedback log. | Project coordination and all members' contributions. Presentation date: **13 November 2026**. |

## 2. Current status snapshot — 3 November 2026

| Workstream / item | Current status based on materials received | Next action before the milestone |
|---|---|---|
| Project setup and business understanding | Completed in Tarun's EDA notebook and committed to GitHub. | Replace the initial 10-KPI draft with Aimen's 12-KPI working catalogue and updated research question. |
| Monica — data acquisition | Nine source CSVs and source documentation received; source inventory/provenance documentation added to GitHub; raw CSVs stored in Google Drive. | Confirm team members can access the Drive folder and finalise source inventory/provenance. |
| Aimen — data dictionary / profiling | Excel workbook, KPI presentation and Python profiling script received and committed to GitHub. | Confirm any open assumptions in KPI formulas, review deduplication and geolocation handling with Tarun/Laura. |
| Tarun — EDA | Stage 1 Business Understanding and Stage 2 Data Loading completed and committed. Stage 3 Initial Data Exploration is in progress. | Map variables and table grain; prepare analysis-ready population rules; reproduce KPI baselines. |
| Laura — data warehouse | Current progress has not been confirmed in the materials reviewed for this update. | Confirm ERD, star-schema grain and SQL DDL status; align fact grain with 12 KPIs and source relationships. |
| Milestone presentation / demo / feedback log | Pending. | Integrate all workstream outputs, prepare demo and capture feedback on 13 November. |

## 3. EDA working sequence before the milestone

The following is a working sequence for Tarun's EDA preparation, not a change to the university's official milestone dates:

1. Update Stage 1 business questions and KPI framework to align with Aimen's 12 KPIs.
2. Complete Stage 3 initial data exploration: variables, dates, keys, table grain and join paths.
3. Prepare analysis rules using Aimen's issue log; preserve raw source files and create derived/cleaned data separately.
4. Calculate and check the relevant delivery, satisfaction, customer and sales KPIs.
5. Create initial charts, interpretation and limitations for the EDA report.
6. Share the KPI definitions and analysis grain with Laura for warehouse alignment.

## 4. Milestone evidence checklist

- Source inventory, provenance and raw-data access location.
- Data dictionary and initial data-quality findings.
- Initial EDA notebook and report, including the analysis scope, fields and KPI definitions/results that are ready by the milestone.
- ERD and initial warehouse/star-schema design.
- SQL DDL for the proposed warehouse schema.
- Milestone presentation slides and demo.
- Feedback log from the milestone presentation.

The team should label each item as complete, partial or open in the final presentation. Receipt of an artefact does not automatically mean its findings have been independently validated.

## 5. Boundary

This plan ends at the **13 November 2026 Milestone Presentation**. Work after the presentation will be planned after the team reviews the feedback.
