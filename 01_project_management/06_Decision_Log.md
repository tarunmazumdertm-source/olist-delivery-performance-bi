# Decision Log

This log records current project decisions and assumptions through the 13 November 2026 milestone. Add a dated entry when the team agrees a material change.

| ID | Date | Decision / working rule | Reason / source | Status |
|---|---|---|---|---|
| D01 | 3 Nov 2026 | Keep the project title and overall scope from the GR05 proposal. | Approved proposal. | Agreed |
| D02 | 3 Nov 2026 | Use January 2017 to 31 August 2018, based on `order_purchase_timestamp`, as the project analysis period. | Proposal scope; Aimen's Q01 scope rule. | Working rule; reproduce the reported 99,092 in-scope orders. |
| D03 | 3 Nov 2026 | Use Aimen's 12-KPI catalogue as the working KPI framework, replacing the initial 10-KPI draft. | Aimen's Excel KPI catalogue and presentation, page 5. | Agreed as working catalogue; baselines require validation. |
| D04 | 3 Nov 2026 | Treat reported KPI baselines as provisional until independently recalculated. | Need consistent filters, grain and formulas across EDA and warehouse. | Agreed |
| D05 | 3 Nov 2026 | Keep the nine original CSVs in the shared Google Drive; keep documentation, notebook and code in GitHub. | Raw data size and repository management choice. | Agreed |
| D06 | 3 Nov 2026 | Tarun maintains GitHub; other members view/review and provide feedback rather than commit or manage branches. | Current team collaboration arrangement. | Agreed |
| D07 | 3 Nov 2026 | Do not directly join raw geolocation to customer/seller tables on ZIP prefix. Aggregate to one row per ZIP prefix after the documented exclusions/cleaning rules. | Aimen's data model and Q09–Q14 issue log. | Working rule; validate output before use. |
| D08 | 3 Nov 2026 | Treat the grain of order items, payments and reviews separately; aggregate before combining with order-level data. | One order can have multiple item, payment and review records. | Agreed analytical safeguard |
| D09 | 3 Nov 2026 | Use the latest review per order for K09/K11 only after confirming timestamp tie-breaking and duplicate handling. | Aimen's Q05/Q06 recommendation. | Proposed; validation required |
| D10 | 3 Nov 2026 | Keep original CSVs unchanged; apply transformations to derived data / ETL outputs. | Preserve source data and reproducibility. | Agreed |
| D11 | 3 Nov 2026 | Use relationship wording in analysis conclusions; do not claim delivery delay causes a review or sales outcome based only on observational analysis. | Analytical interpretation limitation. | Agreed |
| D12 | 3 Nov 2026 | Keep the 13 November 2026 milestone date and current team workstream ownership unchanged. | Team confirmation. | Agreed |

## Items to confirm before KPI sign-off

1. K03 uses sum of payment values divided by eligible order count, while K01 uses item price excluding freight. Keep those definitions distinct and explain their different bases.
2. K07 uses `shipping_limit_date` from the order-item table but is described as an order-level dispatch KPI. Confirm how multiple item deadlines within one order are aggregated and confirm the denominator.
3. K08 is calculated as estimated delivery date minus actual delivery date. Confirm the sign interpretation and whether the baseline includes early and late delivered orders.
4. K09 uses the latest review per order. Confirm selection by `review_answer_timestamp`, handling of duplicate `review_id` and any timestamp ties.
5. K10 says poor reviews (score <= 2) divided by all reviews. Confirm whether the denominator includes all review rows or one review per order.
6. Confirm whether K11 uses the same latest-review-per-order population as K09.
