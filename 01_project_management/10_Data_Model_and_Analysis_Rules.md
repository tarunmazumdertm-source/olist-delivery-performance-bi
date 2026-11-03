# Data Model and Analysis Rules

**Source:** Aimen's data model diagram and data dictionary. This file summarises the source-table grain and analysis safeguards for EDA and warehouse design; it does not replace Laura's ERD or SQL design.

## 1. Source-table grain and key fields

| Table | Source row grain | Key identified by Aimen | Main analytical role |
|---|---|---|---|
| `orders` | One row per order | `order_id` (PK); `customer_id` (FK) | Order status, purchase and delivery dates. |
| `customers` | One row per order-specific customer key | `customer_id` (PK); `customer_unique_id` identifies a person across orders | Customer location and repeat-customer analysis. |
| `order_items` | One row per item within an order | Composite PK: `order_id` + `order_item_id`; FKs to orders, products, sellers | Item revenue, freight, product and seller detail. |
| `payments` | One row per payment sequence within an order | Composite PK: `order_id` + `payment_sequential`; FK to orders | Payment amount and method. |
| `reviews` | One row per review record | `review_id` is not unique in the supplied profile; `review_id` + `order_id` is unique in Aimen's check; multiple reviews can exist per order | Review scores and review timestamps. |
| `products` | One row per product | `product_id` (PK); category link to translation table | Product category and attributes. |
| `sellers` | One row per seller | `seller_id` (PK) | Seller location and seller analysis. |
| `category_translation` | One row per Portuguese category | `product_category_name` (PK) | English category labels. |
| `geolocation` | Many coordinates / rows per ZIP prefix | No unique key; `geolocation_zip_code_prefix` repeats | Geographic lookup; must be reduced to one row per prefix before joining. |

## 2. Main relationships from the source model

- `orders.customer_id` -> `customers.customer_id`.
- `order_items.order_id` -> `orders.order_id`.
- `order_items.product_id` -> `products.product_id`.
- `order_items.seller_id` -> `sellers.seller_id`.
- `payments.order_id` -> `orders.order_id`.
- `reviews.order_id` -> `orders.order_id`.
- `products.product_category_name` -> `category_translation.product_category_name`.
- Customer and seller ZIP prefixes can be matched to geolocation ZIP prefixes, but geolocation has repeated prefixes and the source model marks these as non-unique / many-to-many unless aggregated.

## 3. Join and aggregation safeguards

1. Do not join raw `order_items`, `payments` and `reviews` directly to each other at row level and then sum measures. Each can contain multiple rows for one order and the join can create a fan-out.
2. For an order-level result, aggregate item amounts to `order_id` before joining with order-level data.
3. Aggregate payments to `order_id` before combining with order-level data.
4. For review KPIs, apply the agreed review selection rule before joining to one row per order. Aimen proposes keeping the latest review per order for K09; confirm if K10 and K11 use the same rule.
5. Do not join customer/seller records directly to raw geolocation on ZIP prefix. First remove exact duplicate geolocation rows, remove the 47 out-of-Brazil points according to Aimen's rule, resolve ZIP prefixes with multiple states by the agreed rule, and aggregate to one coordinate record per ZIP prefix. Keep unmatched customer/seller ZIPs with NULL coordinates rather than dropping their orders.
6. Keep the original source CSVs unchanged. Apply transformations in derived data or the ETL layer and document each rule.

## 4. Important source-format rules reported by Aimen

- Read customer, seller and geolocation ZIP prefixes as five-character text (`CHAR(5)`) to preserve leading zeros (for example, `01037`).
- The source product columns contain misspellings: `product_name_lenght` and `product_description_lenght`. Any normalised names such as `*_length` should be introduced in a derived/cleaned layer, not by changing the raw CSV.
- City names may appear with and without accents; normalisation should be documented if used for grouping.
- Category values without a product category can be labelled `unknown` in a derived analysis layer, as proposed by Aimen.

## 5. Reported quality findings to remember

- Orders: 2,965 missing customer delivery dates; 8 delivered-status rows without a delivery date; 6 non-delivered-status rows with a delivery date.
- Reviews: 814 duplicate `review_id` rows; 551 duplicate `order_id` rows in the uniqueness check; 547 orders with more than one review in the issue log. These represent different counts.
- Customers: 278 ZIP rows unmatched to geolocation (157 distinct missing ZIP prefixes).
- Sellers: 7 ZIP rows unmatched to geolocation.
- Products: 610 without a category; 13 product rows have categories without English translation.
- Geolocation: 261,831 exact duplicate rows; 47 points outside Brazil; 8 ZIP prefixes linked to more than one state.

These are Aimen-reported results. Reproduce them on the acquired files before treating them as final validated facts.
