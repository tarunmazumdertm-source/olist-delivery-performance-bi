# Risk Register and Mitigations

The risks and planned responses below are taken from the GR05 proposal. The named functional owners (PM, DE, BI, DS) are retained as written in the proposal. They have not been mapped to named team members in this document.

| ID | Risk from proposal | Planned response from proposal | Functional owner | Current notes / status |
|---|---|---|---|---|
| R1 | Issues connecting Power BI to MySQL. | Test the 64-bit Connector/NET; fallback: ODBC or CSV export. | DE | Confirm connectivity and the team's available Windows / Power BI setup. |
| R2 | Data-quality issues slow the ETL. | Profile all files; use documented rules and automated tests. | DS | Data dictionary and profiling should expose issues early. |
| R3 | Scope creep. | Freeze the KPI catalogue at M3; use MoSCoW priorities; allow approved changes only. | PM | Keep the current scope stable through the 13 November milestone; record requested changes. |
| R4 | Team availability, uneven workload. | Weekly stand-up; keep a one-week buffer before the final presentation. | PM | Review workload and blockers regularly. |
| R5 | Laptop performance limit. | Aggregate geolocation by ZIP prefix; use Import mode; drop unused columns. | DE | Check dataset and tool performance on the hardware available to the team. |
| R6 | Originality concerns. | Use a distinct order-to-review angle for the dataset, own KPIs and model. | PM | Keep the analysis focused on the team's defined question and clearly document its own choices. |
| R7 | Predictive model underperforming. | Start with a simple baseline; use interpretable features; report honestly. | DS | This remains an overall project risk; model development is not a required output of the current Week 46 milestone. |
| R8 | Loss of files or version conflicts. | Use a versioned folder for `.pbix`; make weekly backups. | DE | Use GitHub for versioned code and documentation; keep large raw data outside GitHub with a shared backup arrangement. |

## Risk matrix note

The proposal shows risk codes placed in Green, Amber and Red areas. It does not provide explicit probability or impact labels for the matrix axes. Therefore, this register does not invent numerical probability or impact scores.

## Review routine

At each team check-in:

1. Review whether any risk has become an active issue.
2. Confirm the mitigation owner and next action.
3. Record new issues and decisions in GitHub and the meeting notes.
4. Update this file only when the team's risk position or agreed response changes.
