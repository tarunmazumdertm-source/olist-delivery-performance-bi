# Data Analysis Rules and KPI Validation

**Project:** Olist Delivery Performance, Customer Satisfaction and Sales  
**Reference:** Data Dictionary and Profiling prepared by Aimen  
**Status:** Working rules for the BI analysis

These rules will guide data preparation, KPI calculations and Exploratory Data Analysis (EDA).

## 1. Project Analysis Period

The project analysis period is:

- Start date: 1 January 2017
- End date: 31 August 2018 (inclusive)

The `order_purchase_timestamp` field will be used to filter the orders.

## 2. Order Population

Two different order populations must be maintained:

- 99,092 orders: All orders within the project period.
- 97,905 orders: Orders after excluding cancelled and unavailable statuses, as defined for KPI K02.

These figures represent different populations and must not be treated as interchangeable.

## 3. Sales KPI Definitions

The two sales KPIs use different source columns:

- K01 – GMV: Sum of item prices, excluding freight, from the order-item table.
- K03 – Average Order Value: Total payment value divided by the number of relevant orders.

These two measures must be calculated separately.

## 4. Seller Dispatch Compliance (K07)

K07 uses:

- `shipping_limit_date` from the order-item table.
- The carrier handover date from the orders table.

An order can contain multiple items with different shipping deadlines.

**Pending confirmation:** The rule for combining multiple item deadlines into one order-level dispatch measure must be agreed before the final KPI calculation.

## 5. Delivery Estimate Buffer (K08)

Formula:

Estimated delivery date − Actual delivery date

Interpretation:

- Positive value: Delivered before the promised date.
- Zero: Delivered on the promised date.
- Negative value: Delivered after the promised date.

Orders without a valid actual delivery date will be excluded from this calculation.

## 6. Review Selection Rules (K09, K10 and K11)

The proposed approach for K09 is to use the latest review per order.

The following details must be confirmed before final calculations:

- Which timestamp identifies the latest review?
- How will records with identical timestamps be handled?
- Will K10 (Poor Review Rate) and K11 (Review Gap) use the same review population as K09?

The confirmed rules will be documented and applied consistently.

## 7. Data Aggregation and Table Joins

The Olist dataset contains multiple records per order in the order-items, payments and reviews tables.

To avoid duplicated records and incorrect KPI calculations:

- Aggregate each table to the required level before joining.
- Avoid directly joining multiple raw one-to-many tables and then summing values.
- Check record counts and totals after joins.
- Ensure that order counts, sales values and review scores are not inflated by duplicate records.

## Validation and Approval

The reported KPI baselines and data quality findings will be checked against the original source data before final reporting.

Any unresolved calculation rules will be confirmed during implementation and recorded in the project documentation.

The original source files and Aimen's profiling documents will remain unchanged.