# KPI Catalogue and Validation Notes

**Source:** Aimen's `Data Dictionary & Profiling.xlsx`, sheet `9_KPI_catalogue`, and `Data Dictionary_Profiling + KPIs.pptx`, slide 5.  
**Status:** Working catalogue for EDA and warehouse alignment. Baselines are Aimen's reported values and must be independently reproduced before being presented as validated results.

## 1. KPI catalogue

| ID | Group | KPI | Formula supplied by Aimen | Unit | Reported baseline (Jan 2017–Aug 2018) | Team-proposed target |
|---|---|---|---|---|---:|---|
| K01 | Sales | GMV (gross merchandise value) | SUM(`order_items.price`) for orders not cancelled/unavailable; freight excluded. | BRL | 13,449,529.68 | +10% YoY |
| K02 | Sales | Number of orders | COUNT(DISTINCT `order_id`), excluding cancelled/unavailable. | Orders | 97,905 | +10% YoY |
| K03 | Sales | Average order value | SUM(`payment_value`) / number of eligible orders. | BRL | 160.22 | >= 165 BRL |
| K04 | Delivery | On-time delivery rate | Delivered orders where `delivered_customer_date` <= `estimated_delivery_date` / all delivered orders. | % | 93.21% | >= 95% |
| K05 | Delivery | Average delivery time | AVG(`delivered_customer_date` - `order_purchase_timestamp`). | Days | 12.54 | <= 10 days |
| K06 | Delivery | Average delay of late orders | AVG(`delivered_customer_date` - `estimated_delivery_date`) for late orders. | Days | 10.62 | <= 7 days |
| K07 | Delivery | Seller dispatch compliance | Orders with carrier handover <= `shipping_limit_date` / delivered orders. `shipping_limit_date` is in `order_items`. | % | 91.08% | >= 95% |
| K08 | Delivery | Delivery estimate buffer | AVG(`estimated_delivery_date` - `delivered_customer_date`). | Days | 11.81 | 5–8 days |
| K09 | Satisfaction | Average review score | AVG(`review_score`), latest review per order. | Stars (1–5) | 4.09 | >= 4.2 |
| K10 | Satisfaction | Poor review rate | Reviews with score <= 2 / all reviews. | % | 14.63% | <= 12% |
| K11 | Satisfaction | Review gap: on-time vs. late | AVG score on-time - AVG score late. | Stars | 2.02 | Monitor |
| K12 | Customer | Repeat customer rate | `customer_unique_id` with 2+ orders / all `customer_unique_id`. | % | 3.11% | >= 5% |

Targets are team-proposed targets from Aimen's catalogue; they are not externally verified company targets.

## 2. Important population and grain notes

- The overall source has 99,441 orders.
- Aimen's scope rule reports 99,092 orders with purchase timestamps from 1 January 2017 to 31 August 2018.
- K02 reports 97,905 orders after excluding cancelled and unavailable orders. Do not use 99,092 and 97,905 interchangeably.
- Delivery KPIs require a valid delivered date and a defined eligible delivered-order population.
- Review KPIs require a review population. There are orders without reviews and some orders with more than one review.
- Sales KPIs use different value sources: K01 is item price excluding freight; K03 is payment value divided by eligible order count. Keep them distinct.
- K12 uses `customer_unique_id` to identify a person across multiple order-specific `customer_id` values.

## 3. KPI-specific validation questions

| KPI | Validation required before sign-off |
|---|---|
| K01 | Confirm order-status exclusions and ensure item rows are aggregated without duplicating orders. |
| K02 | Confirm exact purchase-date scope and excluded statuses. |
| K03 | Confirm the same eligible order population as K02; payment values can include amounts that do not match items + freight for some orders. |
| K04 | Confirm date-level comparison and denominator; Aimen's detailed K04 sheet says calculate from delivered-order counts and recalculate ratios at each aggregation level (do not average percentages). |
| K05 | Exclude records without a valid delivered date; confirm treatment of impossible or inconsistent dates. |
| K06 | Define late orders as actual delivery date later than estimated date; calculate delay only for late delivered orders. |
| K07 | `shipping_limit_date` is at order-item grain. Decide and document the order-level rule when an order has multiple item deadlines; confirm denominator and treatment of invalid carrier dates. |
| K08 | Confirm sign interpretation: positive means actual delivery occurred before the promised date. Confirm population (all delivered orders, as implied by the supplied formula). |
| K09 | Confirm latest-review selection field (likely answer timestamp per Aimen's proposal), tie-breaking and treatment of repeated review IDs. |
| K10 | Confirm whether denominator is all review rows or one latest review per order. Do not assume it is the same as K09. |
| K11 | Confirm the same review selection rule as K09 and define on-time/late populations consistently with K04. |
| K12 | Count orders per `customer_unique_id` within the agreed scope; calculate unique people with at least two in-scope orders divided by all unique people in scope. Confirm this denominator with Aimen. |

## 4. Related source fields

- Orders: purchase timestamp, estimated delivery date, actual delivery date, carrier handover date, order status.
- Order items: item price, freight value, shipping deadline, product and seller identifiers.
- Payments: payment value and payment sequence.
- Reviews: order ID, review score, review timestamps.
- Customers: customer ID and customer unique ID.
- Sellers: seller ID and location.

## 5. Reporting rule

Label values as **Aimen-reported baseline** until independently recalculated. If a recalculated value differs, record the filters, denominator, aggregation grain and treatment rule, then reconcile with Aimen and Laura before publishing the final KPI result.
