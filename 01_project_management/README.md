# Project Management — GR05 Olist BI & Big Data Project

**Project:** From Order to Review — How delivery performance affects customer satisfaction and sales  
**Semester:** WiSe 2026/27  
**Current planning boundary:** Milestone Presentation — **13 November 2026 (Week 46)**

This folder contains the project-management baseline up to the 13 November 2026 milestone only. The next project phase will be planned after the presentation feedback is reviewed.

## Documents

1. `01_Project_Charter.md` — project background, problem, research framing and current status.
2. `02_Scope_Objectives_and_Constraints.md` — scope, objectives, KPI coverage and constraints.
3. `03_Team_Roles_and_Responsibilities.md` — named workstream ownership, hand-offs and repository review arrangement.
4. `04_Milestone_Plan_to_13_Nov_2026.md` — milestone deliverables, current status and working sequence.
5. `05_Risk_Register_and_Mitigations.md` — proposal risks plus data-grain and KPI-validation risks.
6. `06_Decision_Log.md` — dated decisions and assumptions.
7. `07_Meeting_Minutes_Template.md` — meeting record template.
8. `08_Milestone_Readiness_Checklist.md` — readiness checklist for 13 November.
9. `09_KPI_Catalogue_and_Validation_Notes.md` — Aimen's 12 proposed KPIs, formulas, baselines, targets and validation notes.
10. `10_Data_Model_and_Analysis_Rules.md` — source-table grain, keys, relationships and analysis safeguards.
11. `PROJECT_MANAGEMENT_BASELINE_TO_13_NOV_2026.md` — consolidated baseline.

## Current status snapshot — 3 November 2026

- Monica's nine source files and source documentation have been received. The raw files are kept in the team's Google Drive; GitHub contains the documentation and access information.
- Aimen's data dictionary, profiling workbook, KPI presentation and profiling script have been received and added to the project repository.
- Tarun's Stage 1 (Business Understanding) and Stage 2 (Data Loading) notebook work has been committed to GitHub. Stage 3 (Initial Data Exploration) is in progress.
- Laura's ERD / warehouse schema / SQL DDL progress has not yet been confirmed in the material reviewed for this update. Confirm status with Laura before the milestone review.

## How to use this folder

- Keep this folder as the agreed project baseline and decision record.
- Record changes that affect scope, definitions, KPI formulas, data rules or milestone outputs in `06_Decision_Log.md`.
- Use `09_KPI_Catalogue_and_Validation_Notes.md` as the working KPI reference. Aimen's baselines are reported values and must be independently reproduced before being presented as validated results.
- Use `10_Data_Model_and_Analysis_Rules.md` to avoid incorrect joins and mismatched aggregation levels.
- Use the meeting-minutes folder for meeting records.
- GitHub is maintained by Tarun as the project repository. Other team members review/view the shared documentation and provide feedback; the current working arrangement does not require them to make commits or manage branches.
- Raw CSV data remains in the shared Google Drive folder and is not committed to GitHub.

## Source basis

This update is based on the GR05 project proposal presentation, Monica's `Data Source Documentation.xlsx`, Aimen's `Data Dictionary & Profiling.xlsx`, Aimen's `Data Dictionary_Profiling + KPIs.pptx`, Aimen's `olist-profiling.py`, and the team's confirmed work allocation and repository arrangement.
