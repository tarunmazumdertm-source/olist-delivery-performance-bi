# -*- coding: utf-8 -*-
"""
GR05 - Olist dataset: data dictionary and data profiling (completeness, uniqueness, consistency)
Output: output/GR05_data_dictionary_and_profiling.xlsx
"""

#%% Setup
import os
import pandas as pd

DATA_DIR = r"path\to\data"   # folder with the 9 Olist CSV files

OUT_DIR = os.path.join(os.path.dirname(DATA_DIR), "output")
os.makedirs(OUT_DIR, exist_ok=True)

pd.set_option("display.max_columns", 30)
pd.set_option("display.width", 200)

print("Data folder  :", DATA_DIR)
print("Output folder:", OUT_DIR)
print("Files found  :", sorted(f for f in os.listdir(DATA_DIR) if f.endswith(".csv")))


#%% Load data
FILES = {
    "orders":      "olist_orders_dataset.csv",
    "order_items": "olist_order_items_dataset.csv",
    "payments":    "olist_order_payments_dataset.csv",
    "reviews":     "olist_order_reviews_dataset.csv",
    "customers":   "olist_customers_dataset.csv",
    "sellers":     "olist_sellers_dataset.csv",
    "products":    "olist_products_dataset.csv",
    "category_translation": "product_category_name_translation.csv",
    "geolocation": "olist_geolocation_dataset.csv",
}

# ZIP prefixes as text to keep leading zeros
ZIP_COLS = {"customer_zip_code_prefix": str,
            "seller_zip_code_prefix": str,
            "geolocation_zip_code_prefix": str}

DATE_COLS = {
    "orders": ["order_purchase_timestamp", "order_approved_at",
               "order_delivered_carrier_date", "order_delivered_customer_date",
               "order_estimated_delivery_date"],
    "order_items": ["shipping_limit_date"],
    "reviews": ["review_creation_date", "review_answer_timestamp"],
}

dfs = {}
for name, file in FILES.items():
    path = os.path.join(DATA_DIR, file)
    df = pd.read_csv(path, dtype=ZIP_COLS, encoding="utf-8-sig")
    for col in DATE_COLS.get(name, []):
        df[col] = pd.to_datetime(df[col], errors="coerce")
    dfs[name] = df
    print(f"{name:22s} {df.shape[0]:>10,} rows  {df.shape[1]:>3} columns")

total_rows = sum(len(d) for d in dfs.values())
print(f"\nTOTAL: {total_rows:,} rows in {len(dfs)} tables")

orders, items, payments, reviews = dfs["orders"], dfs["order_items"], dfs["payments"], dfs["reviews"]
customers, sellers, products = dfs["customers"], dfs["sellers"], dfs["products"]
translation, geo = dfs["category_translation"], dfs["geolocation"]


#%% First look
for name, df in dfs.items():
    print("=" * 80)
    print(name.upper())
    print(df.head(3))
    print("\nData types:")
    print(df.dtypes)


#%% Data dictionary

DESCRIPTIONS = {
    ("orders", "order_id"): ("Unique identifier of an order", "PK"),
    ("orders", "customer_id"): ("Customer key for this order; a new customer_id is created for every order", "FK -> customers"),
    ("orders", "order_status"): ("Current status of the order (delivered, shipped, canceled, ...)", ""),
    ("orders", "order_purchase_timestamp"): ("Date and time the customer placed the order", ""),
    ("orders", "order_approved_at"): ("Date and time the payment was approved", ""),
    ("orders", "order_delivered_carrier_date"): ("Date the seller handed the parcel to the logistics partner", ""),
    ("orders", "order_delivered_customer_date"): ("Actual date the customer received the order", ""),
    ("orders", "order_estimated_delivery_date"): ("Delivery date promised to the customer at purchase", ""),
    ("order_items", "order_id"): ("Order the item belongs to", "PK (with order_item_id), FK -> orders"),
    ("order_items", "order_item_id"): ("Sequence number of the item within the order (1, 2, 3 ...)", "PK (with order_id)"),
    ("order_items", "product_id"): ("Product sold", "FK -> products"),
    ("order_items", "seller_id"): ("Seller who sold the item", "FK -> sellers"),
    ("order_items", "shipping_limit_date"): ("Deadline for the seller to hand the item to the carrier", ""),
    ("order_items", "price"): ("Item price in BRL (excluding freight)", ""),
    ("order_items", "freight_value"): ("Freight cost for this item in BRL", ""),
    ("payments", "order_id"): ("Order the payment belongs to", "PK (with payment_sequential), FK -> orders"),
    ("payments", "payment_sequential"): ("Sequence number when one order is paid with several methods", "PK (with order_id)"),
    ("payments", "payment_type"): ("Payment method (credit_card, boleto, voucher, debit_card)", ""),
    ("payments", "payment_installments"): ("Number of installments chosen by the customer", ""),
    ("payments", "payment_value"): ("Amount paid in BRL", ""),
    ("reviews", "review_id"): ("Identifier of the satisfaction survey response", "PK (expected)"),
    ("reviews", "order_id"): ("Order being reviewed", "FK -> orders"),
    ("reviews", "review_score"): ("Rating from 1 (very bad) to 5 (very good)", ""),
    ("reviews", "review_comment_title"): ("Optional title of the review comment (Portuguese)", ""),
    ("reviews", "review_comment_message"): ("Optional review text (Portuguese)", ""),
    ("reviews", "review_creation_date"): ("Date the survey was sent to the customer", ""),
    ("reviews", "review_answer_timestamp"): ("Date and time the customer answered the survey", ""),
    ("customers", "customer_id"): ("Customer key used in orders (one per order)", "PK"),
    ("customers", "customer_unique_id"): ("Identifies the real person across several orders", ""),
    ("customers", "customer_zip_code_prefix"): ("First 5 digits of the customer ZIP code", "FK -> geolocation (many-to-many)"),
    ("customers", "customer_city"): ("Customer city", ""),
    ("customers", "customer_state"): ("Customer state (2-letter code, e.g. SP)", ""),
    ("sellers", "seller_id"): ("Unique identifier of a seller", "PK"),
    ("sellers", "seller_zip_code_prefix"): ("First 5 digits of the seller ZIP code", "FK -> geolocation (many-to-many)"),
    ("sellers", "seller_city"): ("Seller city", ""),
    ("sellers", "seller_state"): ("Seller state (2-letter code)", ""),
    ("products", "product_id"): ("Unique identifier of a product", "PK"),
    ("products", "product_category_name"): ("Product category in Portuguese", "FK -> category_translation"),
    ("products", "product_name_lenght"): ("Number of characters in the product name (column name misspelled in source)", ""),
    ("products", "product_description_lenght"): ("Number of characters in the product description (column name misspelled)", ""),
    ("products", "product_photos_qty"): ("Number of product photos published", ""),
    ("products", "product_weight_g"): ("Product weight in grams", ""),
    ("products", "product_length_cm"): ("Product length in cm", ""),
    ("products", "product_height_cm"): ("Product height in cm", ""),
    ("products", "product_width_cm"): ("Product width in cm", ""),
    ("category_translation", "product_category_name"): ("Category name in Portuguese", "PK"),
    ("category_translation", "product_category_name_english"): ("Category name in English", ""),
    ("geolocation", "geolocation_zip_code_prefix"): ("First 5 digits of a ZIP code (repeats: many points per prefix)", "No unique key"),
    ("geolocation", "geolocation_lat"): ("Latitude", ""),
    ("geolocation", "geolocation_lng"): ("Longitude", ""),
    ("geolocation", "geolocation_city"): ("City name", ""),
    ("geolocation", "geolocation_state"): ("State (2-letter code)", ""),
}


def suggest_sql_type(series, col):
    """Suggest a MySQL data type for a column."""
    if pd.api.types.is_datetime64_any_dtype(series):
        return "DATETIME"
    if pd.api.types.is_integer_dtype(series):
        return "INT"
    if pd.api.types.is_float_dtype(series):
        s = series.dropna()
        if len(s) and (s % 1 == 0).all() and not col.endswith(("lat", "lng")):
            return "INT"
        if col.endswith(("lat", "lng")):
            return "DECIMAL(10,7)"
        return "DECIMAL(10,2)"
    lengths = series.dropna().astype(str).str.len()
    max_len = int(lengths.max()) if len(lengths) else 0
    min_len = int(lengths.min()) if len(lengths) else 0
    if max_len == min_len and max_len <= 32:
        return f"CHAR({max_len})"
    return f"VARCHAR({max_len})" if max_len <= 255 else "TEXT"


rows = []
for name, df in dfs.items():
    for col in df.columns:
        s = df[col]
        desc, key = DESCRIPTIONS.get((name, col), ("", ""))
        example = s.dropna().iloc[0] if s.notna().any() else ""
        rows.append({
            "table": name,
            "column": col,
            "description": desc,
            "key": key,
            "pandas_type": str(s.dtype),
            "suggested_mysql_type": suggest_sql_type(s, col),
            "example": str(example)[:40],
            "rows": len(s),
            "missing": int(s.isna().sum()),
            "missing_%": round(s.isna().mean() * 100, 2),
            "distinct_values": int(s.nunique()),
        })

data_dictionary = pd.DataFrame(rows)
print(data_dictionary[["table", "column", "key", "suggested_mysql_type", "missing_%"]].to_string())


#%% Completeness
completeness = (data_dictionary[data_dictionary["missing"] > 0]
                [["table", "column", "rows", "missing", "missing_%"]]
                .sort_values("missing_%", ascending=False))
print("Columns with missing values:\n")
print(completeness.to_string(index=False))

table_completeness = pd.DataFrame({
    name: {"rows": len(df), "columns": df.shape[1],
           "cells_filled_%": round(df.notna().mean().mean() * 100, 2)}
    for name, df in dfs.items()}).T
print("\nCompleteness per table:\n", table_completeness)


#%% Uniqueness
pk_checks = [
    ("orders",      ["order_id"]),
    ("customers",   ["customer_id"]),
    ("sellers",     ["seller_id"]),
    ("products",    ["product_id"]),
    ("category_translation", ["product_category_name"]),
    ("order_items", ["order_id", "order_item_id"]),
    ("payments",    ["order_id", "payment_sequential"]),
    ("reviews",     ["review_id"]),
    ("reviews",     ["review_id", "order_id"]),
    ("reviews",     ["order_id"]),
    ("geolocation", ["geolocation_zip_code_prefix"]),
]
uniq_rows = []
for table, cols in pk_checks:
    df = dfs[table]
    dupes = int(df.duplicated(subset=cols).sum())
    uniq_rows.append({"table": table, "key_tested": " + ".join(cols),
                      "rows": len(df), "duplicate_rows": dupes,
                      "unique?": "YES" if dupes == 0 else "NO"})
uniqueness = pd.DataFrame(uniq_rows)

full_dupes = pd.DataFrame([{"table": n, "fully_duplicated_rows": int(d.duplicated().sum())}
                           for n, d in dfs.items()])
uniqueness = pd.concat([uniqueness, pd.DataFrame(
    [{"table": n, "key_tested": "all columns (exact copy of another row)", "rows": len(d),
      "duplicate_rows": int(d.duplicated().sum()), "unique?": "YES" if d.duplicated().sum() == 0 else "NO"}
     for n, d in dfs.items() if d.duplicated().sum() > 0])], ignore_index=True)
print(uniqueness.to_string(index=False))
print("\nFully duplicated rows:\n", full_dupes.to_string(index=False))

n_ids = customers["customer_id"].nunique()
n_people = customers["customer_unique_id"].nunique()
print(f"\ncustomer_id values: {n_ids:,} | real people (customer_unique_id): {n_people:,}")


#%% Consistency: links between tables
fk_checks = [
    ("orders", "customer_id", "customers", "customer_id"),
    ("order_items", "order_id", "orders", "order_id"),
    ("order_items", "product_id", "products", "product_id"),
    ("order_items", "seller_id", "sellers", "seller_id"),
    ("payments", "order_id", "orders", "order_id"),
    ("reviews", "order_id", "orders", "order_id"),
    ("products", "product_category_name", "category_translation", "product_category_name"),
    ("customers", "customer_zip_code_prefix", "geolocation", "geolocation_zip_code_prefix"),
    ("sellers", "seller_zip_code_prefix", "geolocation", "geolocation_zip_code_prefix"),
]
fk_rows = []
for child, ccol, parent, pcol in fk_checks:
    values = dfs[child][ccol].dropna()
    missing = ~values.isin(dfs[parent][pcol])
    fk_rows.append({"link": f"{child}.{ccol} -> {parent}.{pcol}",
                    "rows_checked": len(values),
                    "broken_links": int(missing.sum()),
                    "broken_%": round(missing.mean() * 100, 2),
                    "distinct_missing_values": int(values[missing].nunique()),
                    "missing_examples": ", ".join(values[missing].astype(str).unique()[:3])})
referential = pd.DataFrame(fk_rows)
print(referential.to_string(index=False))

coverage = pd.DataFrame([
    {"check": "orders without any item",    "count": int((~orders.order_id.isin(items.order_id)).sum())},
    {"check": "orders without any payment", "count": int((~orders.order_id.isin(payments.order_id)).sum())},
    {"check": "orders without any review",  "count": int((~orders.order_id.isin(reviews.order_id)).sum())},
])
print("\n", coverage.to_string(index=False))


#%% Consistency: business rules
o = orders
checks = {}

checks["approved before purchase"] = (o.order_approved_at < o.order_purchase_timestamp).sum()
checks["handed to carrier before purchase"] = (o.order_delivered_carrier_date < o.order_purchase_timestamp).sum()
checks["delivered to customer before handed to carrier"] = (o.order_delivered_customer_date < o.order_delivered_carrier_date).sum()
checks["delivered before purchase"] = (o.order_delivered_customer_date < o.order_purchase_timestamp).sum()
checks["review answered before survey sent"] = (reviews.review_answer_timestamp < reviews.review_creation_date).sum()

delivered = o.order_status == "delivered"
checks["status 'delivered' but no delivery date"] = (delivered & o.order_delivered_customer_date.isna()).sum()
checks["status not 'delivered' but has delivery date"] = (~delivered & o.order_delivered_customer_date.notna()).sum()

checks["item price <= 0"] = (items.price <= 0).sum()
checks["freight value = 0 (free shipping?)"] = (items.freight_value == 0).sum()
checks["payment value = 0"] = (payments.payment_value == 0).sum()
checks["payment installments = 0"] = (payments.payment_installments == 0).sum()
checks["payment type 'not_defined'"] = (payments.payment_type == "not_defined").sum()
checks["product weight = 0 g"] = (products.product_weight_g == 0).sum()
checks["review score outside 1-5"] = (~reviews.review_score.between(1, 5)).sum()

order_value = items.groupby("order_id")[["price", "freight_value"]].sum().sum(axis=1)
paid = payments.groupby("order_id")["payment_value"].sum()
both = pd.concat([order_value.rename("items_total"), paid.rename("paid")], axis=1).dropna()
checks["paid amount differs from items+freight by > 1 BRL"] = (abs(both.paid - both.items_total) > 1).sum()

missing_translation = sorted(set(products.product_category_name.dropna()) - set(translation.product_category_name))
checks["categories with no English translation"] = len(missing_translation)
outside = ~(geo.geolocation_lat.between(-33.8, 5.3) & geo.geolocation_lng.between(-74.0, -34.8))
checks["geolocation points outside Brazil"] = outside.sum()
checks["geolocation ZIP prefixes with > 1 state"] = (geo.groupby("geolocation_zip_code_prefix").geolocation_state.nunique() > 1).sum()

consistency = pd.DataFrame({"rule_broken": list(checks.keys()),
                            "rows": [int(v) for v in checks.values()]})
print(consistency.to_string(index=False))
print("\nCategories missing a translation:", missing_translation)
print("Misspelled column names in products:",
      [c for c in products.columns if "lenght" in c])


#%% Time coverage
per_month = o.groupby(o.order_purchase_timestamp.dt.to_period("M")).size()
print(per_month.to_string())
print(f"\nFirst order: {o.order_purchase_timestamp.min()} | Last order: {o.order_purchase_timestamp.max()}")
months_in_scope = per_month[(per_month.index >= "2017-01") & (per_month.index <= "2018-08")]
print(f"Orders inside scope (Jan 2017 - Aug 2018): {months_in_scope.sum():,} "
      f"of {len(o):,} ({months_in_scope.sum()/len(o):.1%})")

print("\nOrder status:\n", o.order_status.value_counts().to_string())


#%% Export to Excel
out_file = os.path.join(OUT_DIR, "GR05_data_dictionary_and_profiling.xlsx")
with pd.ExcelWriter(out_file) as xl:
    data_dictionary.to_excel(xl, sheet_name="1_data_dictionary", index=False)
    table_completeness.to_excel(xl, sheet_name="2_table_completeness")
    completeness.to_excel(xl, sheet_name="3_missing_values", index=False)
    uniqueness.to_excel(xl, sheet_name="4_uniqueness", index=False)
    referential.to_excel(xl, sheet_name="5_referential_integrity", index=False)
    coverage.to_excel(xl, sheet_name="6_order_coverage", index=False)
    consistency.to_excel(xl, sheet_name="7_business_rules", index=False)
    per_month.rename("orders").to_frame().to_excel(xl, sheet_name="8_orders_per_month")
print("Saved:", out_file)
