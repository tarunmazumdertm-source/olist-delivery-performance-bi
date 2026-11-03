# Team Roles and Responsibilities

## 1. Current named task ownership

The following work allocation reflects the team ownership agreed during project setup. No changes have been reported as of 3 November 2026.

| Team member | Workstream | Main responsibilities up to 13 November | Expected evidence / output |
|---|---|---|---|
| Monica | Data acquisition | Identify and obtain the Olist source data; record dataset source and provenance; organise the nine source CSV files; inspect file structure, columns and basic relationships. | Source inventory; organised raw data files or shared access location; notes on file structure and provenance. |
| Aimen | Data dictionary and data quality | Document attributes, data types, meanings and candidate keys; profile missing values, duplicates, valid ranges and relationship / referential-integrity concerns. | Data dictionary; initial data profiling and quality summary. |
| Tarun | Exploratory Data Analysis (EDA) | Set up and maintain Python/Jupyter analysis; explore the dataset; check relevant distributions and relationships; document early findings and analysis limitations. | Reproducible EDA notebook(s); EDA report. |
| Laura | Data warehouse design and SQL | Develop the data warehouse model; prepare the ERD and initial star-schema design; prepare SQL DDL for the proposed warehouse schema. | Conceptual/logical schema diagrams as agreed; star-schema design; SQL DDL scripts. |

## 2. Dependencies between workstreams

1. Monica provides the source files and source inventory so the other workstreams can work from the same dataset version.
2. Aimen's data dictionary and quality findings help Tarun interpret the fields correctly and help Laura define entities, keys and relationships.
3. Tarun's analysis questions and candidate KPIs should inform the warehouse fact grain, dimensions and measures. Design assumptions should be discussed with Laura before the schema is finalised.
4. Laura's ERD and SQL DDL should be checked against the source structure and the analytical requirements.
5. All members review the combined milestone presentation and confirm that their outputs are represented accurately.

## 3. Proposal's functional role model

The GR05 proposal also describes four functional roles. These are role descriptions in the proposal, not a confirmed mapping to named team members:

| Functional role | Responsibilities in the proposal |
|---|---|
| Project Manager & Business Analyst (PM) | Cross-functional communication; plan, risk log and status reports; requirements and KPI definitions. |
| Data Engineer (DE) | MySQL setup and staging loads; ETL scripts and star-schema build; performance tuning and backups. |
| BI Developer (BI) | Power BI data model; dashboard design and prototype; usability tests with peers. |
| Data Scientist & QA Lead (DS) | Data profiling and quality tests; review-risk model in Python; KPI validation against SQL. |

The team should confirm later whether these functional role labels should be formally assigned to individuals. This document does not assume that mapping.

## 4. Team working rules

- Each member works on their assigned workstream and keeps work in the appropriate project folder.
- Use a separate Git branch for changes rather than editing the shared `main` branch directly.
- Submit work through a Pull Request for team review.
- Keep raw data outside GitHub; share it through the team's agreed storage location and document access instructions.
- Raise blockers early and record decisions that affect shared data, KPIs, scope or schema design.
