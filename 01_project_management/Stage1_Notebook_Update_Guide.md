# Stage 1 Notebook Update — Research Question, Business Questions and KPIs

**Purpose:** Apply this update inside `04_eda/notebooks/02_olist_eda.ipynb`. This is an insertion/replacement guide; it does not replace the notebook file, so your existing Stage 2 work remains intact.

## 1. Update the main research question in Section 1.3

Keep the project title as approved in the proposal: **How delivery performance affects customer satisfaction and sales**.

Use this analytical research question:

> How is delivery performance associated with customer satisfaction and sales outcomes in the Olist e-commerce marketplace?

Add this note:

> The analysis describes relationships in historical observational data. It does not by itself prove that delivery delays cause changes in reviews or sales.

## 2. Replace the old supporting business questions with these

1. How many eligible orders are in the agreed analysis period, and how does order volume vary by status and month?
2. What are GMV and average order value for the eligible order population?
3. What proportion of delivered orders arrive on or before the promised date?
4. How long does delivery take from purchase to customer receipt?
5. How many days late are orders that arrive after the promised date?
6. What proportion of eligible orders meet the seller dispatch deadline?
7. What is the average difference between the promised and actual delivery dates?
8. What is the average customer review score?
9. What proportion of reviews are poor (1–2 stars)?
10. How different are average review scores for on-time and late deliveries?
11. What proportion of unique customers place two or more orders in the analysis period?

Monthly, state and product-category breakdowns can be used as analysis dimensions where the data and sample sizes support them.

## 3. Replace the old 10-KPI draft in Section 1.7 with this 12-KPI catalogue

| ID | KPI | Formula supplied by Aimen | Reported baseline | Proposed target |
|---|---|---|---:|---|
| K01 | GMV | SUM(item price), excluding cancelled/unavailable orders and freight | 13,449,529.68 BRL | +10% YoY |
| K02 | Number of orders | Distinct order count, excluding cancelled/unavailable | 97,905 | +10% YoY |
| K03 | Average order value | SUM(payment value) / eligible order count | 160.22 BRL | >= 165 BRL |
| K04 | On-time delivery rate | Delivered on or before estimate / all delivered orders | 93.21% | >= 95% |
| K05 | Average delivery time | Average actual delivery date minus purchase timestamp | 12.54 days | <= 10 days |
| K06 | Average delay of late orders | Average actual delivery date minus estimated date, for late orders | 10.62 days | <= 7 days |
| K07 | Seller dispatch compliance | Orders handed to carrier by shipping deadline / delivered orders | 91.08% | >= 95% |
| K08 | Delivery estimate buffer | Average estimated date minus actual delivery date | 11.81 days | 5–8 days |
| K09 | Average review score | Average review score using latest review per order | 4.09 | >= 4.2 |
| K10 | Poor review rate | Reviews with score <= 2 / all reviews | 14.63% | <= 12% |
| K11 | Review gap: on-time vs late | Average on-time score minus average late score | 2.02 stars | Monitor |
| K12 | Repeat customer rate | Unique customers with 2+ orders / all unique customers | 3.11% | >= 5% |

**Important:** Baselines and targets are reproduced from Aimen's working catalogue. Baselines are provisional until independently recalculated. Targets are team-proposed targets, not externally verified company targets.

## 4. Add this validation note after the KPI table

- Use the purchase timestamp to apply the project period: 1 January 2017 to 31 August 2018 inclusive.
- Aimen reports 99,092 in-scope orders. K02 reports 97,905 after excluding cancelled and unavailable orders. These are different populations.
- K01 uses item price excluding freight; K03 uses payment value. Do not treat the two measures as interchangeable.
- K07 uses `shipping_limit_date` from the order-item table; agree how multiple item deadlines are aggregated to an order.
- K08 is estimated date minus actual date; positive values mean delivery before the promised date.
- Aimen proposes latest-review-per-order for K09. Confirm the exact timestamp/tie-breaking rule and whether K10/K11 use the same review population.
- Aggregate item, payment and review records to the required grain before joining. Do not directly join all raw fact-like tables and then sum values.

## 5. Suggested notebook section title

`## 1.7 Working KPI Catalogue — 12 KPIs from Aimen's Profiling`
