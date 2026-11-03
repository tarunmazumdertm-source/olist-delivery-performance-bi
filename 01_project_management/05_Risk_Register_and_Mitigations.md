# Risk Register and Mitigations

The original proposal risks R1–R8 are retained. Additional risks R9–R11 reflect the more detailed data model, profiling and KPI information received from Aimen. No probability/impact scores are added because the proposal's risk matrix does not provide explicit score definitions.

| ID | Risk | Impact | Mitigation / response | Current owner / coordination |
|---|---|---|---|---|
| R1 | Issues connecting Power BI to MySQL. | Dashboard cannot access warehouse data. | Test 64-bit Connector/NET; fallback to ODBC or CSV export. | DE functional role in proposal. |
| R2 | Data-quality issues slow ETL. | Delays, incorrect measures or unreliable output. | Use Aimen's issue log; document cleaning rules and automated checks. | DS / Aimen workstream. |
| R3 | Scope creep. | Incomplete milestone deliverables. | Keep the agreed project scope and 12-KPI working catalogue stable; approve and record changes. | PM functional role. |
| R4 | Team availability / uneven workload. | Missed hand-offs and milestone delay. | Hold short progress check-ins; identify blockers early; protect time for integration and presentation. | PM functional role / all members. |
| R5 | Laptop performance limit. | Slow processing, especially on geolocation. | Avoid repeated raw geolocation joins; deduplicate and aggregate by ZIP prefix before joining; load only required columns when appropriate. | DE / Tarun analysis coordination. |
| R6 | Originality concerns. | Project lacks a clear contribution. | Keep the specific order-to-review focus, documented KPI definitions and transparent analysis. | PM functional role / all members. |
| R7 | Predictive model underperforming. | Proposed model does not meet target. | Use a simple baseline, interpretable features and honest reporting. This is an overall project risk, not a current-milestone EDA dependency. | DS functional role. |
| R8 | Loss of files or version conflicts. | Work lost or inconsistent versions. | Keep source data in the agreed Google Drive; maintain GitHub documentation/code; keep backups and preserve original files. Tarun maintains GitHub. | DE functional role / Tarun for repository. |
| R9 | Join fan-out from one-to-many or many-to-many relationships. | Inflated order counts, GMV, payments or review measures. | Document grain for every table; aggregate items, payments and reviews to the required grain before joining; do not directly join raw geolocation by ZIP prefix. | Tarun with Aimen and Laura. |
| R10 | KPI formulas, populations or baselines are ambiguous or not reproducible. | Different team members report different KPI values. | Use the 12-KPI catalogue as a working definition; record exclusions/denominators; independently reproduce baselines; agree unresolved formulas before final reporting. | Tarun with Aimen; Laura for warehouse measure alignment. |
| R11 | Multiple reviews per order and repeated review IDs are handled inconsistently. | Review score, poor-review and review-gap KPIs may be double-counted. | Follow the proposed latest-review-per-order rule for the relevant analysis only after validating the sorting field and exact deduplication logic; retain an audit trail. | Tarun with Aimen. |

## Key data-quality issues already reported by Aimen

- Orders: 2,965 missing customer-delivery dates; 8 records marked delivered without a delivery date; 6 non-delivered statuses with a delivery date.
- Reviews: 814 duplicate `review_id` values; 547 orders with more than one review (551 duplicate `order_id` rows in the uniqueness check). These are different counts and should not be treated as interchangeable.
- Geolocation: 261,831 exact duplicate rows; 47 coordinates outside Brazil; repeated ZIP prefixes and 8 ZIP prefixes linked to more than one state.
- Products/categories: 610 products without a category; 13 product rows in two categories without an English translation.
- ZIP prefixes: preserve as five-character text to retain leading zeros.
- Product column names: source spelling includes `lenght`; any rename should happen in a derived/cleaned layer, not the original CSV.

All counts above are Aimen's reported profiling results and should be reproduced before being presented as final validated findings.
