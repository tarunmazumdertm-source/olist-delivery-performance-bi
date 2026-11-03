# Team Roles and Responsibilities

## 1. Named workstream ownership

The named allocation remains unchanged as of 3 November 2026.

| Member | Workstream | Responsibilities through 13 November | Expected output |
|---|---|---|---|
| Monica | Data acquisition | Obtain and organise the nine source CSV files; document source, licence, provenance and file inventory; provide the shared data location. | Source documentation, inventory and Google Drive access to raw data. |
| Aimen | Data dictionary and data quality | Document attribute meanings and types; identify keys and relationships; profile completeness, uniqueness, referential integrity and business-rule issues; provide proposed KPIs and formulas. | Data dictionary workbook, profiling report/issue log, KPI catalogue and profiling script. |
| Tarun | Exploratory Data Analysis | Maintain Python/Jupyter EDA; map business questions to fields; inspect data structure and relationships; prepare KPI calculations, analysis, visualisations and EDA report. Tarun also maintains the GitHub repository. | Reproducible EDA notebook(s), KPI validation and EDA report; curated project documentation in GitHub. |
| Laura | Data warehouse design and SQL | Use the source model and analytical requirements to prepare ERD, logical schema, initial star-schema design and SQL DDL. | Schema diagrams and SQL DDL. |

## 2. Confirmed hand-offs and dependencies

1. **Monica → team:** Source files, source details, licence/provenance and the shared storage location.
2. **Aimen → Tarun:** Data dictionary, data-quality findings, key candidates, relationship notes, issue treatments and KPI definitions. Tarun should not repeat Aimen's detailed profiling; he should use the findings to guide analysis and validate KPI calculations.
3. **Aimen / Tarun → Laura:** Table grain, key relationships, KPI dimensions and measures should inform Laura's warehouse design. Any disagreement about grain or formula must be resolved before final schema/KPI sign-off.
4. **Laura → team:** ERD and SQL DDL should be checked against the source data structure and the agreed KPI requirements.
5. **All members:** Review the integrated milestone presentation and confirm the accuracy of their workstream outputs.

## 3. Repository and review arrangement

- Tarun is the GitHub repository maintainer and performs repository updates and commits.
- Other team members need view/review access to the project documentation. They are not expected to create branches, commit code or manage Pull Requests under the current arrangement.
- Teammates provide review comments and feedback through the team's agreed communication channel or direct review discussions.
- The Google Drive folder is the raw-data location; GitHub stores project documentation and development artefacts.
- Keep raw CSV files out of GitHub.

## 4. Functional role model in the proposal

The proposal describes four functional roles but does not map them to named people:

| Functional role | Responsibilities in proposal |
|---|---|
| Project Manager & Business Analyst (PM) | Cross-functional communication; plans, risk log and status reports; requirements and KPI definitions. |
| Data Engineer (DE) | MySQL setup and staging loads; ETL scripts and star-schema build; performance tuning and backups. |
| BI Developer (BI) | Power BI data model; dashboard design and prototype; usability tests with peers. |
| Data Scientist & QA Lead (DS) | Data profiling and quality tests; review-risk model in Python; KPI validation against SQL. |

The functional roles are retained as proposal terminology. This document does not assume that these labels are assigned to specific named team members.
