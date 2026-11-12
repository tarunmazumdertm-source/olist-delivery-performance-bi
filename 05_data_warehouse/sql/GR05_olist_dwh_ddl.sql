-- =====================================================================================
-- GR05 Olist From Order to Review BI project: data warehouse DDL (PSA, DWH core, data marts, meta)
-- Notation ...... Diagrams for these tables use Information Engineering (IE) notation only.
-- Re-runnable ... Drops and recreates all four schemas, so every loaded row is lost.
-- Scope ........ DDL and seed rows only; PSA -> DWH -> DM ETL/load queries are not included.
-- Alignment .... K07, K10 and ZIP-prefix + state geolocation keys aligned to the validated EDA.
--
-- Contents
--   0  Schemas
--   1  olist_meta  ETL run log, DQ rule catalog and results, KPI catalog, row counts, fn_clean_city
--   2  olist_psa   9 raw tables, one per CSV file (persistent staging area, insert-only)
--   3  olist_dwh   ref_state + 9 cleansed, typed tables in 3NF (rules Q01-Q29 applied)
--   4  olist_dm    10 dimensions (1 snowflaked), 4 facts, 1 score table, 3 views for Power BI
--   5  Seed rows   meta catalogs, ref_state, static dimensions, Unknown members (-1), dim_date
--
-- Conventions
--   *_key        integer surrogate key; -1 = Unknown / not applicable member in every dimension
--   *_date_key   YYYYMMDD integer referencing dim_date (role-playing)
--   is_* / dq_*  0/1 flags; NULL = flag does not apply (e.g. is_on_time for undelivered orders)
--   dq_*         data-quality flag; the comment names the issue-log rule (Qnn)
-- =====================================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =====================================================================================
-- 0  Schemas
-- =====================================================================================
DROP DATABASE IF EXISTS olist_dm;
DROP DATABASE IF EXISTS olist_dwh;
DROP DATABASE IF EXISTS olist_psa;
DROP DATABASE IF EXISTS olist_meta;

CREATE DATABASE olist_meta DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
CREATE DATABASE olist_psa  DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
CREATE DATABASE olist_dwh  DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
CREATE DATABASE olist_dm   DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;

SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================================================
-- 1  olist_meta: ETL control and quality management
-- =====================================================================================
CREATE TABLE olist_meta.etl_run (
  etl_run_id      INT          NOT NULL AUTO_INCREMENT,
  started_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  finished_at     DATETIME     NULL,
  run_status      VARCHAR(10)  NOT NULL DEFAULT 'RUNNING',
  scope_from      DATE         NOT NULL DEFAULT '2017-01-01' COMMENT 'Q01 scope start (purchase date)',
  scope_to        DATE         NOT NULL DEFAULT '2018-08-31' COMMENT 'Q01 scope end (purchase date)',
  run_note        VARCHAR(255) NULL,
  PRIMARY KEY (etl_run_id),
  CONSTRAINT ck_etl_run_status CHECK (run_status IN ('RUNNING', 'SUCCESS', 'FAILED'))
) ENGINE=InnoDB COMMENT='One row per ETL run; PSA rows reference it';

CREATE TABLE olist_meta.dq_rule (
  rule_id         CHAR(3)      NOT NULL COMMENT 'Q01-Q29 from the issue log',
  priority        VARCHAR(6)   NOT NULL,
  source_table    VARCHAR(60)  NOT NULL,
  issue           VARCHAR(255) NOT NULL,
  treatment       VARCHAR(255) NOT NULL COMMENT 'ETL rule or KPI rule',
  applied_in      VARCHAR(20)  NOT NULL COMMENT 'ETL or KPI / analysis',
  baseline_rows   INT          NULL COMMENT 'Rows affected in the profiling',
  PRIMARY KEY (rule_id),
  CONSTRAINT ck_dq_rule_priority CHECK (priority IN ('High', 'Medium', 'Low'))
) ENGINE=InnoDB COMMENT='Data-quality rule catalog (issue log Q01-Q29)';

CREATE TABLE olist_meta.dq_result (
  etl_run_id      INT          NOT NULL,
  rule_id         CHAR(3)      NOT NULL,
  rows_affected   INT          NOT NULL,
  checked_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (etl_run_id, rule_id),
  KEY ix_dq_result_rule (rule_id),
  CONSTRAINT fk_dq_result_run  FOREIGN KEY (etl_run_id) REFERENCES olist_meta.etl_run (etl_run_id),
  CONSTRAINT fk_dq_result_rule FOREIGN KEY (rule_id)    REFERENCES olist_meta.dq_rule (rule_id)
) ENGINE=InnoDB COMMENT='Rows found per DQ rule and run; compared with dq_rule.baseline_rows';

CREATE TABLE olist_meta.kpi_catalog (
  kpi_id          CHAR(3)       NOT NULL COMMENT 'K01-K12',
  kpi_group       VARCHAR(20)   NOT NULL,
  kpi_name        VARCHAR(60)   NOT NULL,
  formula         VARCHAR(255)  NOT NULL,
  unit            VARCHAR(20)   NOT NULL,
  aggregation     VARCHAR(20)   NOT NULL,
  baseline_value  DECIMAL(14,2) NOT NULL COMMENT 'Value Jan 2017-Aug 2018; used for KPI regression tests',
  target_text     VARCHAR(20)   NOT NULL,
  PRIMARY KEY (kpi_id)
) ENGINE=InnoDB COMMENT='KPI catalog K01-K12 with baselines';

CREATE TABLE olist_meta.table_row_count (
  etl_run_id      INT          NOT NULL,
  layer_name      VARCHAR(4)   NOT NULL,
  table_name      VARCHAR(64)  NOT NULL,
  row_count       INT          NOT NULL,
  expected_rows   INT          NULL,
  counted_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (etl_run_id, layer_name, table_name),
  CONSTRAINT fk_table_row_count_run FOREIGN KEY (etl_run_id) REFERENCES olist_meta.etl_run (etl_run_id),
  CONSTRAINT ck_table_row_count_layer CHECK (layer_name IN ('PSA', 'DWH', 'DM'))
) ENGINE=InnoDB COMMENT='Row reconciliation PSA -> DWH -> DM per run';

-- Q17: lower case, Portuguese accents removed, spaces collapsed ('São  Paulo' -> 'sao paulo')
CREATE FUNCTION olist_meta.fn_clean_city(p_city VARCHAR(100))
RETURNS VARCHAR(100)
DETERMINISTIC NO SQL
RETURN NULLIF(TRIM(REGEXP_REPLACE(
  REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
    LOWER(p_city),
    'á', 'a'), 'à', 'a'), 'â', 'a'), 'ã', 'a'), 'ä', 'a'), 'é', 'e'), 'ê', 'e'), 'í', 'i'),
    'ó', 'o'), 'ô', 'o'), 'õ', 'o'), 'ú', 'u'), 'ü', 'u'), 'ç', 'c'),
  '[[:space:]]+', ' ')), '');

-- =====================================================================================
-- 2  olist_psa: persistent staging area (one table per CSV file, raw text, insert-only)
--    Load with LOAD DATA LOCAL INFILE ... FIELDS TERMINATED BY ',' ENCLOSED BY '"'
--    IGNORE 1 LINES; keep every load (etl_run_id); never update or delete rows.
-- =====================================================================================
CREATE TABLE olist_psa.psa_orders (
  psa_row_id      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Technical key; ascending = file order',
  etl_run_id      INT          NOT NULL,
  source_file     VARCHAR(120) NOT NULL,
  loaded_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  row_hash        CHAR(64)     NULL COMMENT 'SHA-256 of all source columns, for change detection',
  order_id                        VARCHAR(64)  NULL,
  customer_id                     VARCHAR(64)  NULL,
  order_status                    VARCHAR(32)  NULL,
  order_purchase_timestamp        VARCHAR(32)  NULL,
  order_approved_at               VARCHAR(32)  NULL,
  order_delivered_carrier_date    VARCHAR(32)  NULL,
  order_delivered_customer_date   VARCHAR(32)  NULL,
  order_estimated_delivery_date   VARCHAR(32)  NULL,
  PRIMARY KEY (psa_row_id),
  KEY ix_psa_orders_run (etl_run_id),
  KEY ix_psa_orders_bk (order_id),
  CONSTRAINT fk_psa_orders_run FOREIGN KEY (etl_run_id) REFERENCES olist_meta.etl_run (etl_run_id)
) ENGINE=InnoDB COMMENT='PSA copy of olist_orders_dataset.csv (99,441 rows expected); all columns raw text; insert-only';

CREATE TABLE olist_psa.psa_order_items (
  psa_row_id      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Technical key; ascending = file order',
  etl_run_id      INT          NOT NULL,
  source_file     VARCHAR(120) NOT NULL,
  loaded_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  row_hash        CHAR(64)     NULL COMMENT 'SHA-256 of all source columns, for change detection',
  order_id                        VARCHAR(64)  NULL,
  order_item_id                   VARCHAR(32)  NULL,
  product_id                      VARCHAR(64)  NULL,
  seller_id                       VARCHAR(64)  NULL,
  shipping_limit_date             VARCHAR(32)  NULL,
  price                           VARCHAR(32)  NULL,
  freight_value                   VARCHAR(32)  NULL,
  PRIMARY KEY (psa_row_id),
  KEY ix_psa_order_items_run (etl_run_id),
  KEY ix_psa_order_items_bk (order_id, order_item_id),
  CONSTRAINT fk_psa_order_items_run FOREIGN KEY (etl_run_id) REFERENCES olist_meta.etl_run (etl_run_id)
) ENGINE=InnoDB COMMENT='PSA copy of olist_order_items_dataset.csv (112,650 rows expected); all columns raw text; insert-only';

CREATE TABLE olist_psa.psa_payments (
  psa_row_id      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Technical key; ascending = file order',
  etl_run_id      INT          NOT NULL,
  source_file     VARCHAR(120) NOT NULL,
  loaded_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  row_hash        CHAR(64)     NULL COMMENT 'SHA-256 of all source columns, for change detection',
  order_id                        VARCHAR(64)  NULL,
  payment_sequential              VARCHAR(32)  NULL,
  payment_type                    VARCHAR(32)  NULL,
  payment_installments            VARCHAR(32)  NULL,
  payment_value                   VARCHAR(32)  NULL,
  PRIMARY KEY (psa_row_id),
  KEY ix_psa_payments_run (etl_run_id),
  KEY ix_psa_payments_bk (order_id, payment_sequential),
  CONSTRAINT fk_psa_payments_run FOREIGN KEY (etl_run_id) REFERENCES olist_meta.etl_run (etl_run_id)
) ENGINE=InnoDB COMMENT='PSA copy of olist_order_payments_dataset.csv (103,886 rows expected); all columns raw text; insert-only';

CREATE TABLE olist_psa.psa_reviews (
  psa_row_id      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Technical key; ascending = file order',
  etl_run_id      INT          NOT NULL,
  source_file     VARCHAR(120) NOT NULL,
  loaded_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  row_hash        CHAR(64)     NULL COMMENT 'SHA-256 of all source columns, for change detection',
  review_id                       VARCHAR(64)  NULL,
  order_id                        VARCHAR(64)  NULL,
  review_score                    VARCHAR(32)  NULL,
  review_comment_title            VARCHAR(255) NULL,
  review_comment_message          TEXT         NULL,
  review_creation_date            VARCHAR(32)  NULL,
  review_answer_timestamp         VARCHAR(32)  NULL,
  PRIMARY KEY (psa_row_id),
  KEY ix_psa_reviews_run (etl_run_id),
  KEY ix_psa_reviews_bk (review_id, order_id),
  CONSTRAINT fk_psa_reviews_run FOREIGN KEY (etl_run_id) REFERENCES olist_meta.etl_run (etl_run_id)
) ENGINE=InnoDB COMMENT='PSA copy of olist_order_reviews_dataset.csv (99,224 rows expected); all columns raw text; insert-only';

CREATE TABLE olist_psa.psa_customers (
  psa_row_id      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Technical key; ascending = file order',
  etl_run_id      INT          NOT NULL,
  source_file     VARCHAR(120) NOT NULL,
  loaded_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  row_hash        CHAR(64)     NULL COMMENT 'SHA-256 of all source columns, for change detection',
  customer_id                     VARCHAR(64)  NULL,
  customer_unique_id              VARCHAR(64)  NULL,
  customer_zip_code_prefix        VARCHAR(16)  NULL,
  customer_city                   VARCHAR(100) NULL,
  customer_state                  VARCHAR(16)  NULL,
  PRIMARY KEY (psa_row_id),
  KEY ix_psa_customers_run (etl_run_id),
  KEY ix_psa_customers_bk (customer_id),
  CONSTRAINT fk_psa_customers_run FOREIGN KEY (etl_run_id) REFERENCES olist_meta.etl_run (etl_run_id)
) ENGINE=InnoDB COMMENT='PSA copy of olist_customers_dataset.csv (99,441 rows expected); all columns raw text; insert-only';

CREATE TABLE olist_psa.psa_sellers (
  psa_row_id      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Technical key; ascending = file order',
  etl_run_id      INT          NOT NULL,
  source_file     VARCHAR(120) NOT NULL,
  loaded_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  row_hash        CHAR(64)     NULL COMMENT 'SHA-256 of all source columns, for change detection',
  seller_id                       VARCHAR(64)  NULL,
  seller_zip_code_prefix          VARCHAR(16)  NULL,
  seller_city                     VARCHAR(100) NULL,
  seller_state                    VARCHAR(16)  NULL,
  PRIMARY KEY (psa_row_id),
  KEY ix_psa_sellers_run (etl_run_id),
  KEY ix_psa_sellers_bk (seller_id),
  CONSTRAINT fk_psa_sellers_run FOREIGN KEY (etl_run_id) REFERENCES olist_meta.etl_run (etl_run_id)
) ENGINE=InnoDB COMMENT='PSA copy of olist_sellers_dataset.csv (3,095 rows expected); all columns raw text; insert-only';

CREATE TABLE olist_psa.psa_products (
  psa_row_id      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Technical key; ascending = file order',
  etl_run_id      INT          NOT NULL,
  source_file     VARCHAR(120) NOT NULL,
  loaded_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  row_hash        CHAR(64)     NULL COMMENT 'SHA-256 of all source columns, for change detection',
  product_id                      VARCHAR(64)  NULL,
  product_category_name           VARCHAR(100) NULL,
  product_name_lenght             VARCHAR(32)  NULL,
  product_description_lenght      VARCHAR(32)  NULL,
  product_photos_qty              VARCHAR(32)  NULL,
  product_weight_g                VARCHAR(32)  NULL,
  product_length_cm               VARCHAR(32)  NULL,
  product_height_cm               VARCHAR(32)  NULL,
  product_width_cm                VARCHAR(32)  NULL,
  PRIMARY KEY (psa_row_id),
  KEY ix_psa_products_run (etl_run_id),
  KEY ix_psa_products_bk (product_id),
  CONSTRAINT fk_psa_products_run FOREIGN KEY (etl_run_id) REFERENCES olist_meta.etl_run (etl_run_id)
) ENGINE=InnoDB COMMENT='PSA copy of olist_products_dataset.csv (32,951 rows expected); all columns raw text; insert-only';

CREATE TABLE olist_psa.psa_category_translation (
  psa_row_id      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Technical key; ascending = file order',
  etl_run_id      INT          NOT NULL,
  source_file     VARCHAR(120) NOT NULL,
  loaded_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  row_hash        CHAR(64)     NULL COMMENT 'SHA-256 of all source columns, for change detection',
  product_category_name           VARCHAR(100) NULL,
  product_category_name_english   VARCHAR(100) NULL,
  PRIMARY KEY (psa_row_id),
  KEY ix_psa_category_translation_run (etl_run_id),
  KEY ix_psa_category_translation_bk (product_category_name),
  CONSTRAINT fk_psa_category_translation_run FOREIGN KEY (etl_run_id) REFERENCES olist_meta.etl_run (etl_run_id)
) ENGINE=InnoDB COMMENT='PSA copy of product_category_name_translation.csv (71 rows expected); all columns raw text; insert-only';

CREATE TABLE olist_psa.psa_geolocation (
  psa_row_id      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Technical key; ascending = file order',
  etl_run_id      INT          NOT NULL,
  source_file     VARCHAR(120) NOT NULL,
  loaded_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  row_hash        CHAR(64)     NULL COMMENT 'SHA-256 of all source columns, for change detection',
  geolocation_zip_code_prefix     VARCHAR(16)  NULL,
  geolocation_lat                 VARCHAR(40)  NULL,
  geolocation_lng                 VARCHAR(40)  NULL,
  geolocation_city                VARCHAR(100) NULL,
  geolocation_state               VARCHAR(16)  NULL,
  PRIMARY KEY (psa_row_id),
  KEY ix_psa_geolocation_run (etl_run_id),
  KEY ix_psa_geolocation_bk (geolocation_zip_code_prefix),
  CONSTRAINT fk_psa_geolocation_run FOREIGN KEY (etl_run_id) REFERENCES olist_meta.etl_run (etl_run_id)
) ENGINE=InnoDB COMMENT='PSA copy of olist_geolocation_dataset.csv (1,000,163 rows expected); all columns raw text; insert-only';

-- =====================================================================================
-- 3  olist_dwh: DWH core (cleansed, typed, integrated, 3NF, all periods with scope flag)
-- =====================================================================================
CREATE TABLE olist_dwh.ref_state (
  state_code      CHAR(2)      NOT NULL,
  state_name      VARCHAR(30)  NOT NULL,
  region_name     VARCHAR(15)  NOT NULL,
  PRIMARY KEY (state_code),
  CONSTRAINT ck_ref_state_region CHECK (region_name IN ('Norte', 'Nordeste', 'Centro-Oeste', 'Sudeste', 'Sul'))
) ENGINE=InnoDB COMMENT='27 Brazilian states with macro-region (seed data)';

CREATE TABLE olist_dwh.dwh_geolocation (
  zip_prefix          CHAR(5)        NOT NULL COMMENT 'Q15: text, leading zeros kept',
  latitude            DECIMAL(10,7)  NULL COMMENT 'Q10: average of kept points for this ZIP prefix + state; NULL if none (Q13, Q14)',
  longitude           DECIMAL(10,7)  NULL,
  city_name           VARCHAR(60)    NULL COMMENT 'Q17: most frequent cleaned city within this ZIP prefix + state',
  state_code          CHAR(2)        NOT NULL COMMENT 'State component of the composite key (ZIP prefix + state)',
  point_count         INT            NOT NULL DEFAULT 0 COMMENT 'Distinct points kept after Q09 and Q11',
  dropped_point_count INT            NOT NULL DEFAULT 0 COMMENT 'Q11: points outside Brazil',
  has_coordinates     TINYINT        NOT NULL,
  dq_multi_state      TINYINT        NOT NULL DEFAULT 0 COMMENT 'Q12',
  zip_origin          VARCHAR(12)    NOT NULL COMMENT 'GEOLOCATION, or CUSTOMER / SELLER for ZIPs missing in geolocation',
  etl_run_id      INT          NOT NULL COMMENT 'olist_meta.etl_run that wrote the row',
  loaded_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (zip_prefix, state_code),
  KEY ix_dwh_geolocation_state (state_code),
  CONSTRAINT fk_dwh_geolocation_state FOREIGN KEY (state_code) REFERENCES olist_dwh.ref_state (state_code),
  CONSTRAINT ck_dwh_geolocation_coords CHECK (has_coordinates IN (0, 1)),
  CONSTRAINT ck_dwh_geolocation_lat CHECK (latitude IS NULL OR latitude BETWEEN -34 AND 6),
  CONSTRAINT ck_dwh_geolocation_lng CHECK (longitude IS NULL OR longitude BETWEEN -74 AND -34),
  CONSTRAINT ck_dwh_geolocation_origin CHECK (zip_origin IN ('GEOLOCATION', 'CUSTOMER', 'SELLER'))
) ENGINE=InnoDB COMMENT='One row per ZIP prefix + state combination (Q09-Q14); preserves multi-state ZIP prefixes';

CREATE TABLE olist_dwh.dwh_category (
  category_name_pt     VARCHAR(60)  NOT NULL,
  category_name_en     VARCHAR(60)  NOT NULL,
  is_translation_added TINYINT      NOT NULL DEFAULT 0 COMMENT 'Q08: 2 English names added by the project',
  is_unknown           TINYINT      NOT NULL DEFAULT 0 COMMENT 'Q07: category unknown for 610 products',
  etl_run_id      INT          NOT NULL COMMENT 'olist_meta.etl_run that wrote the row',
  loaded_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (category_name_pt)
) ENGINE=InnoDB COMMENT='71 source categories + 2 added translations + unknown';

CREATE TABLE olist_dwh.dwh_customer (
  customer_id         CHAR(32)     NOT NULL COMMENT 'Source key; one per order',
  customer_unique_id  CHAR(32)     NOT NULL COMMENT 'Real person across orders',
  zip_prefix          CHAR(5)      NOT NULL,
  city_name           VARCHAR(60)  NOT NULL COMMENT 'Q17',
  state_code          CHAR(2)      NOT NULL,
  dq_zip_not_in_geolocation TINYINT NOT NULL DEFAULT 0 COMMENT 'Q13',
  etl_run_id      INT          NOT NULL COMMENT 'olist_meta.etl_run that wrote the row',
  loaded_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (customer_id),
  KEY ix_dwh_customer_unique (customer_unique_id),
  KEY ix_dwh_customer_geo (zip_prefix, state_code),
  KEY ix_dwh_customer_state (state_code),
  CONSTRAINT fk_dwh_customer_geolocation FOREIGN KEY (zip_prefix, state_code)
    REFERENCES olist_dwh.dwh_geolocation (zip_prefix, state_code),
  CONSTRAINT fk_dwh_customer_state FOREIGN KEY (state_code) REFERENCES olist_dwh.ref_state (state_code)
) ENGINE=InnoDB COMMENT='Customer per order (customer_id), with the real person in customer_unique_id';

CREATE TABLE olist_dwh.dwh_seller (
  seller_id           CHAR(32)     NOT NULL,
  zip_prefix          CHAR(5)      NOT NULL,
  city_name           VARCHAR(60)  NOT NULL COMMENT 'Q17',
  state_code          CHAR(2)      NOT NULL,
  dq_zip_not_in_geolocation TINYINT NOT NULL DEFAULT 0 COMMENT 'Q14',
  etl_run_id      INT          NOT NULL COMMENT 'olist_meta.etl_run that wrote the row',
  loaded_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (seller_id),
  KEY ix_dwh_seller_geo (zip_prefix, state_code),
  KEY ix_dwh_seller_state (state_code),
  CONSTRAINT fk_dwh_seller_geolocation FOREIGN KEY (zip_prefix, state_code)
    REFERENCES olist_dwh.dwh_geolocation (zip_prefix, state_code),
  CONSTRAINT fk_dwh_seller_state FOREIGN KEY (state_code) REFERENCES olist_dwh.ref_state (state_code)
) ENGINE=InnoDB COMMENT='One row per seller';

CREATE TABLE olist_dwh.dwh_product (
  product_id          CHAR(32)     NOT NULL,
  category_name_pt    VARCHAR(60)  NOT NULL COMMENT 'Q07: unknown when missing',
  name_length         SMALLINT     NULL COMMENT 'Q16: source product_name_lenght',
  description_length  SMALLINT     NULL COMMENT 'Q16: source product_description_lenght',
  photos_qty          TINYINT      NULL,
  weight_g            INT          NULL,
  length_cm           SMALLINT     NULL,
  height_cm           SMALLINT     NULL,
  width_cm            SMALLINT     NULL,
  dq_missing_category TINYINT      NOT NULL DEFAULT 0 COMMENT 'Q07',
  dq_missing_size     TINYINT      NOT NULL DEFAULT 0 COMMENT 'Q25',
  dq_zero_weight      TINYINT      NOT NULL DEFAULT 0 COMMENT 'Q25',
  etl_run_id      INT          NOT NULL COMMENT 'olist_meta.etl_run that wrote the row',
  loaded_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (product_id),
  KEY ix_dwh_product_category (category_name_pt),
  CONSTRAINT fk_dwh_product_category FOREIGN KEY (category_name_pt) REFERENCES olist_dwh.dwh_category (category_name_pt),
  CONSTRAINT ck_dwh_product_weight CHECK (weight_g IS NULL OR weight_g >= 0)
) ENGINE=InnoDB COMMENT='One row per product';

CREATE TABLE olist_dwh.dwh_order (
  order_id                    CHAR(32)     NOT NULL,
  order_key                   INT          NOT NULL AUTO_INCREMENT COMMENT 'Integer surrogate reused by the data marts',
  customer_id                 CHAR(32)     NOT NULL,
  order_status                VARCHAR(12)  NOT NULL,
  purchase_ts                 DATETIME     NOT NULL,
  approved_ts                 DATETIME     NULL COMMENT 'Q23: 160 NULL kept',
  carrier_ts                  DATETIME     NULL,
  delivered_ts                DATETIME     NULL,
  estimated_delivery_date     DATE         NOT NULL COMMENT 'Source time is always 00:00:00',
  is_in_scope                 TINYINT      NOT NULL COMMENT 'Q01: purchase 2017-01-01 to 2018-08-31',
  item_count                  SMALLINT     NOT NULL DEFAULT 0,
  has_items                   TINYINT      NOT NULL DEFAULT 0 COMMENT 'Q20',
  has_payment                 TINYINT      NOT NULL DEFAULT 0,
  has_review                  TINYINT      NOT NULL DEFAULT 0 COMMENT 'Q21',
  dq_delivered_without_date   TINYINT      NOT NULL DEFAULT 0 COMMENT 'Q03',
  dq_date_without_delivered   TINYINT      NOT NULL DEFAULT 0 COMMENT 'Q04',
  dq_carrier_before_purchase  TINYINT      NOT NULL DEFAULT 0 COMMENT 'Q18',
  dq_delivered_before_carrier TINYINT      NOT NULL DEFAULT 0 COMMENT 'Q19',
  dq_payment_mismatch         TINYINT      NOT NULL DEFAULT 0 COMMENT 'Q22: payments differ from items + freight by > 1 BRL',
  etl_run_id      INT          NOT NULL COMMENT 'olist_meta.etl_run that wrote the row',
  loaded_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (order_id),
  UNIQUE KEY uq_dwh_order_key (order_key),
  KEY ix_dwh_order_customer (customer_id),
  KEY ix_dwh_order_purchase (purchase_ts),
  CONSTRAINT fk_dwh_order_customer FOREIGN KEY (customer_id) REFERENCES olist_dwh.dwh_customer (customer_id),
  CONSTRAINT ck_dwh_order_status CHECK (order_status IN
    ('created', 'approved', 'invoiced', 'processing', 'shipped', 'delivered', 'canceled', 'unavailable'))
) ENGINE=InnoDB COMMENT='One row per order, all periods; is_in_scope marks Q01';

CREATE TABLE olist_dwh.dwh_order_item (
  order_id            CHAR(32)       NOT NULL,
  order_item_seq      TINYINT        NOT NULL COMMENT 'Source order_item_id (1-21)',
  product_id          CHAR(32)       NOT NULL,
  seller_id           CHAR(32)       NOT NULL,
  shipping_limit_ts   DATETIME       NOT NULL,
  price               DECIMAL(10,2)  NOT NULL,
  freight_value       DECIMAL(10,2)  NOT NULL,
  dq_free_freight     TINYINT        NOT NULL DEFAULT 0 COMMENT 'Q29: freight 0, kept as valid',
  etl_run_id      INT          NOT NULL COMMENT 'olist_meta.etl_run that wrote the row',
  loaded_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (order_id, order_item_seq),
  KEY ix_dwh_order_item_product (product_id),
  KEY ix_dwh_order_item_seller (seller_id),
  CONSTRAINT fk_dwh_order_item_order   FOREIGN KEY (order_id)   REFERENCES olist_dwh.dwh_order (order_id),
  CONSTRAINT fk_dwh_order_item_product FOREIGN KEY (product_id) REFERENCES olist_dwh.dwh_product (product_id),
  CONSTRAINT fk_dwh_order_item_seller  FOREIGN KEY (seller_id)  REFERENCES olist_dwh.dwh_seller (seller_id),
  CONSTRAINT ck_dwh_order_item_price   CHECK (price > 0),
  CONSTRAINT ck_dwh_order_item_freight CHECK (freight_value >= 0)
) ENGINE=InnoDB COMMENT='One row per order item';

CREATE TABLE olist_dwh.dwh_payment (
  order_id              CHAR(32)       NOT NULL,
  payment_seq           TINYINT        NOT NULL COMMENT 'Source payment_sequential (1-29)',
  payment_type          VARCHAR(12)    NOT NULL COMMENT 'Q28: not_defined mapped to unknown',
  installments          TINYINT        NOT NULL COMMENT 'Q27: 0 set to 1',
  payment_value         DECIMAL(10,2)  NOT NULL,
  dq_zero_value         TINYINT        NOT NULL DEFAULT 0 COMMENT 'Q26',
  dq_installments_fixed TINYINT        NOT NULL DEFAULT 0 COMMENT 'Q27',
  dq_type_unknown       TINYINT        NOT NULL DEFAULT 0 COMMENT 'Q28',
  etl_run_id      INT          NOT NULL COMMENT 'olist_meta.etl_run that wrote the row',
  loaded_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (order_id, payment_seq),
  CONSTRAINT fk_dwh_payment_order FOREIGN KEY (order_id) REFERENCES olist_dwh.dwh_order (order_id),
  CONSTRAINT ck_dwh_payment_type  CHECK (payment_type IN ('credit_card', 'boleto', 'voucher', 'debit_card', 'unknown')),
  CONSTRAINT ck_dwh_payment_inst  CHECK (installments >= 1),
  CONSTRAINT ck_dwh_payment_value CHECK (payment_value >= 0)
) ENGINE=InnoDB COMMENT='One row per payment line';

CREATE TABLE olist_dwh.dwh_review (
  review_id            CHAR(32)      NOT NULL,
  order_id             CHAR(32)      NOT NULL,
  review_score         TINYINT       NOT NULL,
  comment_title        VARCHAR(100)  NULL,
  comment_message      TEXT          NULL COMMENT 'Q24: empty text stored as NULL',
  review_sent_date     DATE          NOT NULL COMMENT 'Source review_creation_date (time always 00:00:00)',
  review_answer_ts     DATETIME      NOT NULL,
  is_latest_for_order  TINYINT       NOT NULL COMMENT 'Q06: latest answer per order (tie-break: review_id)',
  dq_shared_review_id  TINYINT       NOT NULL DEFAULT 0 COMMENT 'Q05: review_id also linked to other orders',
  etl_run_id      INT          NOT NULL COMMENT 'olist_meta.etl_run that wrote the row',
  loaded_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (review_id, order_id) COMMENT 'Q05: review_id alone is not unique',
  KEY ix_dwh_review_order (order_id),
  CONSTRAINT fk_dwh_review_order FOREIGN KEY (order_id) REFERENCES olist_dwh.dwh_order (order_id),
  CONSTRAINT ck_dwh_review_score CHECK (review_score BETWEEN 1 AND 5)
) ENGINE=InnoDB COMMENT='One row per review-order pair';

-- =====================================================================================
-- 4  olist_dm: data marts (fact constellation, conformed dimensions, in-scope orders only)
-- =====================================================================================

-- ---------- 4.1 Dimensions -----------------------------------------------------------
CREATE TABLE olist_dm.dim_date (
  date_key               INT          NOT NULL COMMENT 'YYYYMMDD; -1 = Unknown / not applicable',
  full_date              DATE         NULL,
  day_of_month           TINYINT      NULL,
  day_name               VARCHAR(10)  NOT NULL,
  day_of_week_iso        TINYINT      NULL COMMENT '1 = Monday',
  is_weekend             TINYINT      NULL,
  iso_week               TINYINT      NULL,
  month_num              TINYINT      NULL,
  month_name             VARCHAR(10)  NOT NULL,
  year_month_label       CHAR(7)      NOT NULL COMMENT 'e.g. 2017-11',
  quarter_num            TINYINT      NULL,
  year_quarter_label     CHAR(7)      NOT NULL COMMENT 'e.g. 2017-Q4',
  year_num               SMALLINT     NULL,
  is_in_scope            TINYINT      NOT NULL DEFAULT 0 COMMENT 'Q01: 2017-01-01 to 2018-08-31',
  is_br_national_holiday TINYINT      NOT NULL DEFAULT 0,
  PRIMARY KEY (date_key),
  UNIQUE KEY uq_dim_date_full_date (full_date)
) ENGINE=InnoDB COMMENT='Calendar 2016-2019, one row per day; role-playing';

CREATE TABLE olist_dm.dim_customer (
  customer_key          INT          NOT NULL AUTO_INCREMENT,
  customer_unique_id    CHAR(32)     NOT NULL COMMENT 'Business key: real person',
  first_purchase_date   DATE         NULL,
  last_purchase_date    DATE         NULL,
  eligible_order_count  SMALLINT     NOT NULL DEFAULT 0 COMMENT 'In-scope orders, not canceled/unavailable',
  customer_segment      VARCHAR(20)  NOT NULL COMMENT 'One-time, Repeat, No eligible order, Unknown',
  is_repeat_customer    TINYINT      NOT NULL DEFAULT 0 COMMENT 'K12: 2+ eligible orders',
  etl_run_id      INT          NOT NULL COMMENT 'olist_meta.etl_run that wrote the row',
  loaded_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (customer_key),
  UNIQUE KEY uq_dim_customer_bk (customer_unique_id)
) ENGINE=InnoDB COMMENT='One row per real person (customer_unique_id); SCD type 1';

CREATE TABLE olist_dm.dim_location (
  location_key     INT            NOT NULL AUTO_INCREMENT,
  zip_prefix       CHAR(5)        NOT NULL,
  city_name        VARCHAR(60)    NOT NULL,
  state_code       CHAR(2)        NOT NULL,
  state_name       VARCHAR(30)    NOT NULL,
  region_name      VARCHAR(15)    NOT NULL,
  latitude         DECIMAL(10,7)  NULL COMMENT 'ZIP-prefix + state average from dwh_geolocation',
  longitude        DECIMAL(10,7)  NULL,
  has_coordinates  TINYINT        NOT NULL DEFAULT 0 COMMENT 'Q13, Q14: 0 when the ZIP-prefix + state combination is not in geolocation',
  etl_run_id      INT          NOT NULL COMMENT 'olist_meta.etl_run that wrote the row',
  loaded_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (location_key),
  UNIQUE KEY uq_dim_location_bk (zip_prefix, city_name, state_code),
  KEY ix_dim_location_state (state_code)
) ENGINE=InnoDB COMMENT='One row per ZIP prefix + city + state seen in customers or sellers; role-playing (customer, seller)';

CREATE TABLE olist_dm.dim_seller (
  seller_key       INT        NOT NULL AUTO_INCREMENT,
  seller_id        CHAR(32)   NOT NULL,
  first_sale_date  DATE       NULL,
  last_sale_date   DATE       NULL,
  sold_item_count  INT        NOT NULL DEFAULT 0 COMMENT 'In-scope items',
  etl_run_id      INT          NOT NULL COMMENT 'olist_meta.etl_run that wrote the row',
  loaded_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (seller_key),
  UNIQUE KEY uq_dim_seller_bk (seller_id)
) ENGINE=InnoDB COMMENT='One row per seller; location via fact_sales_item.seller_location_key';

CREATE TABLE olist_dm.dim_category (
  category_key          SMALLINT     NOT NULL AUTO_INCREMENT,
  category_name_pt      VARCHAR(60)  NOT NULL,
  category_name_en      VARCHAR(60)  NOT NULL,
  is_translation_added  TINYINT      NOT NULL DEFAULT 0 COMMENT 'Q08',
  is_unknown            TINYINT      NOT NULL DEFAULT 0 COMMENT 'Q07',
  etl_run_id      INT          NOT NULL COMMENT 'olist_meta.etl_run that wrote the row',
  loaded_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (category_key),
  UNIQUE KEY uq_dim_category_bk (category_name_pt)
) ENGINE=InnoDB COMMENT='Snowflaked from dim_product: one row per category';

CREATE TABLE olist_dm.dim_product (
  product_key         INT          NOT NULL AUTO_INCREMENT,
  product_id          CHAR(32)     NOT NULL,
  category_key        SMALLINT     NOT NULL COMMENT 'Snowflake link to dim_category',
  name_length         SMALLINT     NULL,
  description_length  SMALLINT     NULL,
  photos_qty          TINYINT      NULL,
  weight_g            INT          NULL,
  length_cm           SMALLINT     NULL,
  height_cm           SMALLINT     NULL,
  width_cm            SMALLINT     NULL,
  volume_cm3          INT          NULL,
  weight_band         VARCHAR(12)  NOT NULL COMMENT '< 0.5 kg, 0.5-2 kg, 2-10 kg, > 10 kg, Unknown',
  dq_missing_size     TINYINT      NOT NULL DEFAULT 0 COMMENT 'Q25',
  dq_zero_weight      TINYINT      NOT NULL DEFAULT 0 COMMENT 'Q25',
  etl_run_id      INT          NOT NULL COMMENT 'olist_meta.etl_run that wrote the row',
  loaded_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (product_key),
  UNIQUE KEY uq_dim_product_bk (product_id),
  KEY ix_dim_product_category (category_key),
  CONSTRAINT fk_dim_product_category FOREIGN KEY (category_key) REFERENCES olist_dm.dim_category (category_key)
) ENGINE=InnoDB COMMENT='One row per product; SCD type 1';

CREATE TABLE olist_dm.dim_order_status (
  order_status_key   TINYINT      NOT NULL,
  status_code        VARCHAR(12)  NOT NULL,
  status_label       VARCHAR(20)  NOT NULL,
  status_group       VARCHAR(16)  NOT NULL COMMENT 'Completed, In progress, Not fulfilled',
  is_sales_eligible  TINYINT      NOT NULL COMMENT 'K01-K03: not canceled / unavailable',
  PRIMARY KEY (order_status_key),
  UNIQUE KEY uq_dim_order_status_bk (status_code)
) ENGINE=InnoDB COMMENT='Static lookup, seeded';

CREATE TABLE olist_dm.dim_payment_type (
  payment_type_key    TINYINT      NOT NULL,
  payment_type_code   VARCHAR(12)  NOT NULL,
  payment_type_label  VARCHAR(40)  NOT NULL,
  PRIMARY KEY (payment_type_key),
  UNIQUE KEY uq_dim_payment_type_bk (payment_type_code)
) ENGINE=InnoDB COMMENT='Static lookup, seeded';

CREATE TABLE olist_dm.dim_delivery_status (
  delivery_status_key  TINYINT      NOT NULL,
  status_code          VARCHAR(16)  NOT NULL,
  status_label         VARCHAR(60)  NOT NULL,
  is_delivered         TINYINT      NOT NULL,
  is_kpi_eligible      TINYINT      NOT NULL COMMENT 'Denominator of K04-K08',
  PRIMARY KEY (delivery_status_key),
  UNIQUE KEY uq_dim_delivery_status_bk (status_code)
) ENGINE=InnoDB COMMENT='Conformed mini-dimension: On time, Late, Not delivered, Inconsistent (Q02-Q04)';

CREATE TABLE olist_dm.dim_review_score (
  review_score_key  TINYINT      NOT NULL,
  review_score      TINYINT      NULL,
  score_label       VARCHAR(10)  NOT NULL,
  score_band        VARCHAR(16)  NOT NULL,
  is_poor           TINYINT      NOT NULL COMMENT 'K10: score 1-2',
  PRIMARY KEY (review_score_key)
) ENGINE=InnoDB COMMENT='Static lookup, seeded';

-- ---------- 4.2 Facts ----------------------------------------------------------------
CREATE TABLE olist_dm.fact_order_fulfillment (
  order_key                    INT            NOT NULL COMMENT 'Degenerate dimension (dwh_order.order_key)',
  order_id                     CHAR(32)       NOT NULL,
  customer_key                 INT            NOT NULL,
  customer_location_key        INT            NOT NULL,
  order_status_key             TINYINT        NOT NULL,
  delivery_status_key          TINYINT        NOT NULL,
  purchase_date_key            INT            NOT NULL,
  approved_date_key            INT            NOT NULL,
  carrier_date_key             INT            NOT NULL,
  delivered_date_key           INT            NOT NULL,
  estimated_delivery_date_key  INT            NOT NULL,
  purchase_ts                  DATETIME       NOT NULL,
  approved_ts                  DATETIME       NULL,
  carrier_ts                   DATETIME       NULL,
  delivered_ts                 DATETIME       NULL,
  estimated_delivery_date      DATE           NOT NULL,
  item_count                   SMALLINT       NOT NULL DEFAULT 0,
  seller_count                 SMALLINT       NOT NULL DEFAULT 0,
  items_value                  DECIMAL(12,2)  NOT NULL DEFAULT 0 COMMENT 'Sum of item prices (GMV basis)',
  freight_value                DECIMAL(12,2)  NOT NULL DEFAULT 0,
  payment_value                DECIMAL(12,2)  NOT NULL DEFAULT 0,
  approval_hours               DECIMAL(8,2)   NULL,
  handling_days                DECIMAL(8,2)   NULL COMMENT 'Purchase -> carrier; NULL if Q18',
  transit_days                 DECIMAL(8,2)   NULL COMMENT 'Carrier -> customer; NULL if Q19',
  delivery_days                DECIMAL(8,2)   NULL COMMENT 'K05: purchase -> customer delivery',
  delay_days                   SMALLINT       NULL COMMENT 'K06: delivered date - estimated date (date level)',
  estimate_buffer_days         SMALLINT       NULL COMMENT 'K08: estimated date - delivered date (date level)',
  seller_overrun_days          SMALLINT       NULL COMMENT 'Handover date - latest shipping deadline date (signed); NULL unless K07-eligible',
  carrier_overrun_days         SMALLINT       NULL COMMENT '(Delivered - handover) - (estimated - latest deadline), in dates; delay_days = seller + carrier',
  delay_cause                  VARCHAR(7)     NULL COMMENT 'Late orders only: seller, carrier or both (stages with a positive overrun)',
  is_sales_eligible            TINYINT        NOT NULL COMMENT 'Status not canceled/unavailable and 1+ item',
  is_delivery_kpi_eligible     TINYINT        NOT NULL COMMENT 'Delivered status with a delivery date (Q02-Q04)',
  is_on_time                   TINYINT        NULL COMMENT 'K04: delivered date <= estimated date; NULL if not eligible',
  is_late                      TINYINT        NULL,
  is_dispatch_on_time          TINYINT        NULL COMMENT 'K07: carrier_ts <= earliest_shipping_limit_ts; NULL unless eligible after Q18 and Q19 exclusions',
  earliest_shipping_limit_ts   DATETIME       NULL COMMENT 'Earliest item shipping deadline (MIN); NULL if no items',
  latest_shipping_limit_ts     DATETIME       NULL COMMENT 'Latest item shipping deadline (MAX); retained for deadline-range and delay-attribution analysis',
  shipping_deadline_count      TINYINT        NOT NULL DEFAULT 0 COMMENT 'Distinct item shipping deadlines in the order',
  latest_review_score          TINYINT        NULL COMMENT 'Score of the latest review per order (Q06); NULL if no review',
  dq_carrier_before_purchase   TINYINT        NOT NULL DEFAULT 0 COMMENT 'Q18',
  dq_delivered_before_carrier  TINYINT        NOT NULL DEFAULT 0 COMMENT 'Q19',
  dq_payment_mismatch          TINYINT        NOT NULL DEFAULT 0 COMMENT 'Q22',
  etl_run_id      INT          NOT NULL COMMENT 'olist_meta.etl_run that wrote the row',
  loaded_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (order_key),
  UNIQUE KEY uq_fact_order_fulfillment_order_id (order_id),
  CONSTRAINT fk_fof_customer        FOREIGN KEY (customer_key)          REFERENCES olist_dm.dim_customer (customer_key),
  CONSTRAINT fk_fof_location        FOREIGN KEY (customer_location_key) REFERENCES olist_dm.dim_location (location_key),
  CONSTRAINT fk_fof_order_status    FOREIGN KEY (order_status_key)      REFERENCES olist_dm.dim_order_status (order_status_key),
  CONSTRAINT fk_fof_delivery_status FOREIGN KEY (delivery_status_key)   REFERENCES olist_dm.dim_delivery_status (delivery_status_key),
  CONSTRAINT fk_fof_purchase_date   FOREIGN KEY (purchase_date_key)     REFERENCES olist_dm.dim_date (date_key),
  CONSTRAINT fk_fof_approved_date   FOREIGN KEY (approved_date_key)     REFERENCES olist_dm.dim_date (date_key),
  CONSTRAINT fk_fof_carrier_date    FOREIGN KEY (carrier_date_key)      REFERENCES olist_dm.dim_date (date_key),
  CONSTRAINT fk_fof_delivered_date  FOREIGN KEY (delivered_date_key)    REFERENCES olist_dm.dim_date (date_key),
  CONSTRAINT fk_fof_estimated_date  FOREIGN KEY (estimated_delivery_date_key) REFERENCES olist_dm.dim_date (date_key),
  CONSTRAINT ck_fof_on_time  CHECK (is_on_time IN (0, 1)),
  CONSTRAINT ck_fof_late     CHECK (is_on_time IS NULL OR is_late = 1 - is_on_time),
  CONSTRAINT ck_fof_eligible CHECK (is_delivery_kpi_eligible = 1 OR is_on_time IS NULL),
  CONSTRAINT ck_fof_review   CHECK (latest_review_score IS NULL OR latest_review_score BETWEEN 1 AND 5),
  CONSTRAINT ck_fof_dispatch CHECK (is_dispatch_on_time IN (0, 1)),
  CONSTRAINT ck_fof_dispatch_eligible CHECK (
    is_dispatch_on_time IS NULL
    OR (
      is_delivery_kpi_eligible = 1
      AND dq_carrier_before_purchase = 0
      AND dq_delivered_before_carrier = 0
      AND earliest_shipping_limit_ts IS NOT NULL
    )
  ),
  CONSTRAINT ck_fof_deadlines CHECK (earliest_shipping_limit_ts IS NULL OR earliest_shipping_limit_ts <= latest_shipping_limit_ts),
  CONSTRAINT ck_fof_overrun_split CHECK (seller_overrun_days IS NULL OR carrier_overrun_days IS NULL
                                        OR delay_days = seller_overrun_days + carrier_overrun_days),
  CONSTRAINT ck_fof_delay_cause CHECK (delay_cause IN ('seller', 'carrier', 'both')),
  CONSTRAINT ck_fof_cause_late  CHECK (delay_cause IS NULL OR is_late = 1)
) ENGINE=InnoDB COMMENT='Accumulating snapshot: one row per in-scope order (99,092); KPIs K02-K08, K12';

CREATE TABLE olist_dm.fact_sales_item (
  order_key                INT            NOT NULL COMMENT 'Degenerate dimension',
  order_item_seq           TINYINT        NOT NULL,
  order_id                 CHAR(32)       NOT NULL,
  purchase_date_key        INT            NOT NULL,
  shipping_limit_date_key  INT            NOT NULL,
  customer_key             INT            NOT NULL,
  customer_location_key    INT            NOT NULL,
  seller_key               INT            NOT NULL,
  seller_location_key      INT            NOT NULL,
  product_key              INT            NOT NULL,
  order_status_key         TINYINT        NOT NULL,
  delivery_status_key      TINYINT        NOT NULL COMMENT 'Copied from the order, for K04 by seller or category',
  item_price               DECIMAL(10,2)  NOT NULL COMMENT 'K01 GMV basis',
  freight_value            DECIMAL(10,2)  NOT NULL,
  is_sales_eligible        TINYINT        NOT NULL,
  is_free_freight          TINYINT        NOT NULL DEFAULT 0 COMMENT 'Q29',
  is_dispatch_on_time      TINYINT        NULL COMMENT 'K07 verdict copied from the order using the earliest shipping deadline; for seller, product and category analysis',
  is_same_state            TINYINT        NULL COMMENT 'Customer state = seller state',
  etl_run_id      INT          NOT NULL COMMENT 'olist_meta.etl_run that wrote the row',
  loaded_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (order_key, order_item_seq),
  KEY ix_fsi_order_id (order_id),
  CONSTRAINT fk_fsi_purchase_date   FOREIGN KEY (purchase_date_key)       REFERENCES olist_dm.dim_date (date_key),
  CONSTRAINT fk_fsi_shiplimit_date  FOREIGN KEY (shipping_limit_date_key) REFERENCES olist_dm.dim_date (date_key),
  CONSTRAINT fk_fsi_customer        FOREIGN KEY (customer_key)            REFERENCES olist_dm.dim_customer (customer_key),
  CONSTRAINT fk_fsi_cust_location   FOREIGN KEY (customer_location_key)   REFERENCES olist_dm.dim_location (location_key),
  CONSTRAINT fk_fsi_seller          FOREIGN KEY (seller_key)              REFERENCES olist_dm.dim_seller (seller_key),
  CONSTRAINT fk_fsi_seller_location FOREIGN KEY (seller_location_key)     REFERENCES olist_dm.dim_location (location_key),
  CONSTRAINT fk_fsi_product         FOREIGN KEY (product_key)             REFERENCES olist_dm.dim_product (product_key),
  CONSTRAINT fk_fsi_order_status    FOREIGN KEY (order_status_key)        REFERENCES olist_dm.dim_order_status (order_status_key),
  CONSTRAINT fk_fsi_delivery_status FOREIGN KEY (delivery_status_key)     REFERENCES olist_dm.dim_delivery_status (delivery_status_key),
  CONSTRAINT ck_fsi_price CHECK (item_price > 0)
) ENGINE=InnoDB COMMENT='Transaction fact: one row per in-scope order item; K01; K04 and K07 by seller, product, category';

CREATE TABLE olist_dm.fact_payment (
  order_key              INT            NOT NULL,
  payment_seq            TINYINT        NOT NULL,
  order_id               CHAR(32)       NOT NULL,
  purchase_date_key      INT            NOT NULL,
  customer_key           INT            NOT NULL,
  customer_location_key  INT            NOT NULL,
  order_status_key       TINYINT        NOT NULL,
  payment_type_key       TINYINT        NOT NULL,
  payment_value          DECIMAL(10,2)  NOT NULL COMMENT 'K03 numerator (incl. freight and interest)',
  installments           TINYINT        NOT NULL,
  is_sales_eligible      TINYINT        NOT NULL,
  dq_zero_value          TINYINT        NOT NULL DEFAULT 0 COMMENT 'Q26',
  dq_installments_fixed  TINYINT        NOT NULL DEFAULT 0 COMMENT 'Q27',
  etl_run_id      INT          NOT NULL COMMENT 'olist_meta.etl_run that wrote the row',
  loaded_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (order_key, payment_seq),
  CONSTRAINT fk_fp_purchase_date FOREIGN KEY (purchase_date_key)     REFERENCES olist_dm.dim_date (date_key),
  CONSTRAINT fk_fp_customer      FOREIGN KEY (customer_key)          REFERENCES olist_dm.dim_customer (customer_key),
  CONSTRAINT fk_fp_location      FOREIGN KEY (customer_location_key) REFERENCES olist_dm.dim_location (location_key),
  CONSTRAINT fk_fp_order_status  FOREIGN KEY (order_status_key)      REFERENCES olist_dm.dim_order_status (order_status_key),
  CONSTRAINT fk_fp_payment_type  FOREIGN KEY (payment_type_key)      REFERENCES olist_dm.dim_payment_type (payment_type_key),
  CONSTRAINT ck_fp_value CHECK (payment_value >= 0)
) ENGINE=InnoDB COMMENT='Transaction fact: one row per payment line of an in-scope order; K03';

CREATE TABLE olist_dm.fact_review (
  review_id               CHAR(32)      NOT NULL,
  order_key               INT           NOT NULL,
  order_id                CHAR(32)      NOT NULL,
  review_sent_date_key    INT           NOT NULL,
  review_answer_date_key  INT           NOT NULL,
  purchase_date_key       INT           NOT NULL,
  customer_key            INT           NOT NULL,
  customer_location_key   INT           NOT NULL,
  order_status_key        TINYINT       NOT NULL,
  delivery_status_key     TINYINT       NOT NULL COMMENT 'K11: on-time vs late',
  review_score_key        TINYINT       NOT NULL,
  review_score            TINYINT       NOT NULL,
  is_latest_for_order     TINYINT       NOT NULL COMMENT 'Q06: K09 and K11 use latest review per order; K10 uses all valid reviews',
  has_title               TINYINT       NOT NULL,
  has_comment             TINYINT       NOT NULL COMMENT 'Q24',
  response_hours          DECIMAL(8,2)  NULL COMMENT 'Answer timestamp - survey sent date',
  dq_shared_review_id     TINYINT       NOT NULL DEFAULT 0 COMMENT 'Q05',
  etl_run_id      INT          NOT NULL COMMENT 'olist_meta.etl_run that wrote the row',
  loaded_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (review_id, order_key),
  KEY ix_fr_order (order_key),
  CONSTRAINT fk_fr_sent_date       FOREIGN KEY (review_sent_date_key)   REFERENCES olist_dm.dim_date (date_key),
  CONSTRAINT fk_fr_answer_date     FOREIGN KEY (review_answer_date_key) REFERENCES olist_dm.dim_date (date_key),
  CONSTRAINT fk_fr_purchase_date   FOREIGN KEY (purchase_date_key)      REFERENCES olist_dm.dim_date (date_key),
  CONSTRAINT fk_fr_customer        FOREIGN KEY (customer_key)           REFERENCES olist_dm.dim_customer (customer_key),
  CONSTRAINT fk_fr_location        FOREIGN KEY (customer_location_key)  REFERENCES olist_dm.dim_location (location_key),
  CONSTRAINT fk_fr_order_status    FOREIGN KEY (order_status_key)       REFERENCES olist_dm.dim_order_status (order_status_key),
  CONSTRAINT fk_fr_delivery_status FOREIGN KEY (delivery_status_key)    REFERENCES olist_dm.dim_delivery_status (delivery_status_key),
  CONSTRAINT fk_fr_score           FOREIGN KEY (review_score_key)       REFERENCES olist_dm.dim_review_score (review_score_key),
  CONSTRAINT ck_fr_score  CHECK (review_score BETWEEN 1 AND 5),
  CONSTRAINT ck_fr_latest CHECK (is_latest_for_order IN (0, 1))
) ENGINE=InnoDB COMMENT='Transaction fact: one row per review-order pair of an in-scope order; K09-K11';

CREATE TABLE olist_dm.fact_review_risk_score (
  order_key              INT            NOT NULL,
  model_version          VARCHAR(20)    NOT NULL,
  scored_at              DATETIME       NOT NULL,
  purchase_date_key      INT            NOT NULL,
  customer_location_key  INT            NOT NULL,
  p_low_review           DECIMAL(5,4)   NOT NULL COMMENT 'Predicted probability of a 1-2 star review',
  risk_band              VARCHAR(6)     NOT NULL,
  PRIMARY KEY (order_key, model_version),
  CONSTRAINT fk_frrs_purchase_date FOREIGN KEY (purchase_date_key)     REFERENCES olist_dm.dim_date (date_key),
  CONSTRAINT fk_frrs_location      FOREIGN KEY (customer_location_key) REFERENCES olist_dm.dim_location (location_key),
  CONSTRAINT ck_frrs_p    CHECK (p_low_review BETWEEN 0 AND 1),
  CONSTRAINT ck_frrs_band CHECK (risk_band IN ('Low', 'Medium', 'High'))
) ENGINE=InnoDB COMMENT='Python output: one row per scored order and model version';

-- ---------- 4.3 Views for Power BI ---------------------------------------------------
CREATE VIEW olist_dm.v_dim_product_flat AS
SELECT p.product_key, p.product_id,
       c.category_key, c.category_name_pt, c.category_name_en, c.is_unknown AS is_category_unknown,
       p.name_length, p.description_length, p.photos_qty,
       p.weight_g, p.length_cm, p.height_cm, p.width_cm, p.volume_cm3, p.weight_band,
       p.dq_missing_size, p.dq_zero_weight
FROM olist_dm.dim_product p
JOIN olist_dm.dim_category c ON c.category_key = p.category_key;

CREATE VIEW olist_dm.v_dim_customer_location AS
SELECT location_key AS customer_location_key, zip_prefix AS customer_zip_prefix,
       city_name AS customer_city, state_code AS customer_state, state_name AS customer_state_name,
       region_name AS customer_region, latitude AS customer_latitude, longitude AS customer_longitude,
       has_coordinates AS customer_has_coordinates
FROM olist_dm.dim_location;

CREATE VIEW olist_dm.v_dim_seller_location AS
SELECT location_key AS seller_location_key, zip_prefix AS seller_zip_prefix,
       city_name AS seller_city, state_code AS seller_state, state_name AS seller_state_name,
       region_name AS seller_region, latitude AS seller_latitude, longitude AS seller_longitude,
       has_coordinates AS seller_has_coordinates
FROM olist_dm.dim_location;

-- =====================================================================================
-- 5  Seed rows (re-run section 5.3-5.5 after any TRUNCATE of the data-mart dimensions)
-- =====================================================================================

-- 5.1 Meta catalogs, taken from Data Dictionary & Profiling.xlsx (sheets 8 and 9)
INSERT INTO olist_meta.dq_rule
  (rule_id, priority, source_table, issue, treatment, applied_in, baseline_rows) VALUES
  ('Q01', 'High', 'orders', 'Orders outside scope (2016, Sep-Oct 2018)', 'Keep only orders purchased 2017-01-01 to 2018-08-31 (99,092 kept)', 'ETL', 349),
  ('Q02', 'High', 'orders', 'No customer delivery date', 'Delivery KPIs use only delivered orders with a date; keep others for sales/cancellation', 'KPI / analysis', 2965),
  ('Q03', 'High', 'orders', 'Status ''delivered'' but no delivery date', 'Flag; exclude from delivery KPIs', 'ETL', 8),
  ('Q04', 'High', 'orders', 'Status not ''delivered'' but has delivery date', 'Flag; keep status as recorded', 'ETL', 6),
  ('Q05', 'High', 'reviews', 'review_id not unique (same review linked to several orders)', 'Key = review_id + order_id', 'ETL', 814),
  ('Q06', 'High', 'reviews', 'Orders with more than one review (547 orders)', 'Keep the latest answer per order for analysis', 'KPI / analysis', 551),
  ('Q07', 'High', 'products', 'No category (also no name/description length, photos)', 'Set category to ''unknown''', 'ETL', 610),
  ('Q08', 'High', 'products', 'Categories without English translation: pc_gamer, portateis_cozinha_e_preparadores_de_alimentos', 'Add the 2 English names to the translation table', 'ETL', 13),
  ('Q09', 'High', 'geolocation', 'Exact duplicate rows', 'Remove duplicates', 'ETL', 261831),
  ('Q10', 'High', 'geolocation', 'No unique key: 1,000,163 rows for 19,018 ZIP prefix + state combinations', 'Aggregate to one average latitude and longitude per ZIP prefix + state', 'ETL', 981145),
  ('Q11', 'High', 'geolocation', '47 source geolocation rows outside Brazil before duplicate removal', 'Remove invalid points before ZIP prefix + state aggregation', 'ETL', 47),
  ('Q12', 'High', 'geolocation', 'ZIP prefixes appearing in more than one state', 'Preserve separate ZIP prefix + state combinations', 'ETL', 8),
  ('Q13', 'High', 'customers', 'Customer records whose ZIP prefix + state combination is not found in geolocation', 'Keep; create location entry with coordinates NULL', 'ETL', 279),
  ('Q14', 'High', 'sellers', 'Seller records whose ZIP prefix + state combination is not found in geolocation', 'Keep; create location entry with coordinates NULL', 'ETL', 42),
  ('Q15', 'High', 'customers, sellers, geolocation', 'ZIP codes with leading zeros (e.g. 01037)', 'Load ZIP as text: CHAR(5)', 'ETL', NULL),
  ('Q16', 'High', 'products', 'Misspelled column names (product_name_lenght, product_description_lenght)', 'Rename to *_length', 'ETL', NULL),
  ('Q17', 'High', 'customers, sellers, geolocation', 'City names with and without accents (sao paulo / são paulo)', 'Lowercase and remove accents', 'ETL', NULL),
  ('Q18', 'Medium', 'orders', 'Handed to carrier before purchase', 'Flag; exclude from seller dispatch KPI', 'ETL', 166),
  ('Q19', 'Medium', 'orders', 'Delivered to customer before handed to carrier', 'Flag; exclude from seller dispatch KPI', 'ETL', 23),
  ('Q20', 'Medium', 'orders', 'Orders without any item (mostly ''unavailable''/''canceled'')', 'Exclude from sales KPIs; keep for cancellation analysis', 'KPI / analysis', 775),
  ('Q21', 'Medium', 'orders', 'Orders without any review', 'Review KPIs use reviewed orders only', 'KPI / analysis', 768),
  ('Q22', 'Medium', 'payments', 'Paid amount differs from items + freight by more than 1 BRL', 'GMV from order_items.price; average order value from payments', 'KPI / analysis', 249),
  ('Q23', 'Low', 'orders', 'No payment approval date', 'Keep NULL; not used in KPIs', 'ETL', 160),
  ('Q24', 'Low', 'reviews', 'Empty review comment message', 'Keep NULL; analysis uses review_score', 'ETL', 58247),
  ('Q25', 'Low', 'products', 'Missing size/weight (2) or weight = 0 g (4)', 'Keep; flag', 'ETL', 6),
  ('Q26', 'Low', 'payments', 'Payment value = 0 BRL', 'Keep; flag', 'ETL', 9),
  ('Q27', 'Low', 'payments', 'Installments = 0', 'Set to 1', 'ETL', 2),
  ('Q28', 'Low', 'payments', 'Payment type ''not_defined''', 'Map to ''unknown''', 'ETL', 3),
  ('Q29', 'Low', 'order_items', 'Freight value = 0', 'Keep (valid business case)', 'ETL', 383);

INSERT INTO olist_meta.kpi_catalog
  (kpi_id, kpi_group, kpi_name, formula, unit, aggregation, baseline_value, target_text) VALUES
  ('K01', 'Sales', 'GMV (gross merchandise value)', 'SUM(order_items.price), orders not canceled/unavailable', 'BRL', 'Sum', 13449529.68, '+10% YoY'),
  ('K02', 'Sales', 'Number of orders', 'COUNT(order_id) where status not canceled/unavailable', 'orders', 'Count distinct', 97910, '+10% YoY'),
  ('K03', 'Sales', 'Average order value', 'SUM(payment_value) / number of orders', 'BRL', 'Ratio', 160.22, '>= 165 BRL'),
  ('K04', 'Delivery', 'On-time delivery rate', 'delivered orders with delivered_date <= estimated_date / delivered orders', '%', 'Ratio', 93.21, '>= 95%'),
  ('K05', 'Delivery', 'Average delivery time', 'AVG(delivered_customer_date - purchase_timestamp)', 'days', 'Average', 12.54, '<= 10 days'),
  ('K06', 'Delivery', 'Average delay of late orders', 'AVG(delivered_date - estimated_date) for late orders', 'days', 'Average', 10.62, '<= 7 days'),
  ('K07', 'Delivery', 'Seller dispatch compliance', 'Delivered orders with carrier_date <= earliest item shipping_limit_date / delivered orders with valid event dates, excluding Q18 and Q19 (order level, D3)', '%', 'Ratio', 91.06, '>= 95%'),
  ('K08', 'Delivery', 'Delivery estimate buffer', 'AVG(estimated_date - delivered_date)', 'days', 'Average', 11.81, '5-8 days'),
  ('K09', 'Satisfaction', 'Average review score', 'AVG(review_score), latest review per order', 'stars (1-5)', 'Average', 4.09, '>= 4.2'),
  ('K10', 'Satisfaction', 'Poor review rate', 'Reviews with score <= 2 / all valid reviews (D4)', '%', 'Ratio', 14.63, '<= 12%'),
  ('K11', 'Satisfaction', 'Review gap on-time vs late', 'AVG score on-time - AVG score late', 'stars', 'Difference', 2.02, 'monitor'),
  ('K12', 'Customer', 'Repeat customer rate', 'customer_unique_id with 2+ orders / all customer_unique_id, excl. canceled/unavailable orders', '%', 'Ratio', 3.04, '>= 5%');

-- 5.2 Reference data
INSERT INTO olist_dwh.ref_state (state_code, state_name, region_name) VALUES
  ('AC', 'Acre', 'Norte'),
  ('AL', 'Alagoas', 'Nordeste'),
  ('AM', 'Amazonas', 'Norte'),
  ('AP', 'Amapá', 'Norte'),
  ('BA', 'Bahia', 'Nordeste'),
  ('CE', 'Ceará', 'Nordeste'),
  ('DF', 'Distrito Federal', 'Centro-Oeste'),
  ('ES', 'Espírito Santo', 'Sudeste'),
  ('GO', 'Goiás', 'Centro-Oeste'),
  ('MA', 'Maranhão', 'Nordeste'),
  ('MG', 'Minas Gerais', 'Sudeste'),
  ('MS', 'Mato Grosso do Sul', 'Centro-Oeste'),
  ('MT', 'Mato Grosso', 'Centro-Oeste'),
  ('PA', 'Pará', 'Norte'),
  ('PB', 'Paraíba', 'Nordeste'),
  ('PE', 'Pernambuco', 'Nordeste'),
  ('PI', 'Piauí', 'Nordeste'),
  ('PR', 'Paraná', 'Sul'),
  ('RJ', 'Rio de Janeiro', 'Sudeste'),
  ('RN', 'Rio Grande do Norte', 'Nordeste'),
  ('RO', 'Rondônia', 'Norte'),
  ('RR', 'Roraima', 'Norte'),
  ('RS', 'Rio Grande do Sul', 'Sul'),
  ('SC', 'Santa Catarina', 'Sul'),
  ('SE', 'Sergipe', 'Nordeste'),
  ('SP', 'São Paulo', 'Sudeste'),
  ('TO', 'Tocantins', 'Norte');

-- 5.3 Static dimensions (fixed keys) and Unknown members (-1)
INSERT INTO olist_dm.dim_order_status
  (order_status_key, status_code, status_label, status_group, is_sales_eligible) VALUES
  (-1, 'unknown',     'Unknown',     'Unknown',       0),
  ( 1, 'created',     'Created',     'In progress',   1),
  ( 2, 'approved',    'Approved',    'In progress',   1),
  ( 3, 'invoiced',    'Invoiced',    'In progress',   1),
  ( 4, 'processing',  'Processing',  'In progress',   1),
  ( 5, 'shipped',     'Shipped',     'In progress',   1),
  ( 6, 'delivered',   'Delivered',   'Completed',     1),
  ( 7, 'canceled',    'Canceled',    'Not fulfilled', 0),
  ( 8, 'unavailable', 'Unavailable', 'Not fulfilled', 0);

INSERT INTO olist_dm.dim_payment_type (payment_type_key, payment_type_code, payment_type_label) VALUES
  (-1, 'n/a',         'Not applicable'),
  ( 1, 'credit_card', 'Credit card'),
  ( 2, 'boleto',      'Boleto'),
  ( 3, 'voucher',     'Voucher'),
  ( 4, 'debit_card',  'Debit card'),
  ( 5, 'unknown',     'Unknown (not_defined in source, Q28)');

INSERT INTO olist_dm.dim_delivery_status
  (delivery_status_key, status_code, status_label, is_delivered, is_kpi_eligible) VALUES
  (-1, 'N/A',           'Not applicable',                         0, 0),
  ( 1, 'ON_TIME',       'On time',                                1, 1),
  ( 2, 'LATE',          'Late',                                   1, 1),
  ( 3, 'NOT_DELIVERED', 'Not delivered',                          0, 0),
  ( 4, 'INCONSISTENT',  'Status and delivery date conflict (Q03, Q04)', 0, 0);

INSERT INTO olist_dm.dim_review_score (review_score_key, review_score, score_label, score_band, is_poor) VALUES
  (-1, NULL, 'Unknown', 'Unknown',        0),
  ( 1, 1,    '1 star',  'Poor (1-2)',     1),
  ( 2, 2,    '2 stars', 'Poor (1-2)',     1),
  ( 3, 3,    '3 stars', 'Neutral (3)',    0),
  ( 4, 4,    '4 stars', 'Positive (4-5)', 0),
  ( 5, 5,    '5 stars', 'Positive (4-5)', 0);

-- Unknown members. An explicit -1 is stored as given; 0 would draw a new AUTO_INCREMENT value.
INSERT INTO olist_dm.dim_customer (customer_key, customer_unique_id, customer_segment, etl_run_id)
  VALUES (-1, 'UNKNOWN', 'Unknown', 0);
INSERT INTO olist_dm.dim_location (location_key, zip_prefix, city_name, state_code, state_name, region_name, has_coordinates, etl_run_id)
  VALUES (-1, '00000', 'unknown', 'XX', 'Unknown', 'Unknown', 0, 0);
INSERT INTO olist_dm.dim_seller (seller_key, seller_id, etl_run_id)
  VALUES (-1, 'UNKNOWN', 0);
INSERT INTO olist_dm.dim_category (category_key, category_name_pt, category_name_en, etl_run_id)
  VALUES (-1, 'n/a', 'Not applicable', 0);
INSERT INTO olist_dm.dim_product (product_key, product_id, category_key, weight_band, etl_run_id)
  VALUES (-1, 'UNKNOWN', -1, 'Unknown', 0);

-- 5.4 dim_date: 2016-01-01 to 2019-12-31 (covers all purchase, delivery, estimate and review dates)
INSERT INTO olist_dm.dim_date
  (date_key, full_date, day_of_month, day_name, day_of_week_iso, is_weekend, iso_week, month_num,
   month_name, year_month_label, quarter_num, year_quarter_label, year_num, is_in_scope)
  VALUES (-1, NULL, NULL, 'Unknown', NULL, NULL, NULL, NULL, 'Unknown', 'Unknown', NULL, 'Unknown', NULL, 0);

SET SESSION cte_max_recursion_depth = 2000;
INSERT INTO olist_dm.dim_date
  (date_key, full_date, day_of_month, day_name, day_of_week_iso, is_weekend, iso_week, month_num,
   month_name, year_month_label, quarter_num, year_quarter_label, year_num, is_in_scope)
WITH RECURSIVE cal AS (
  SELECT DATE '2016-01-01' AS d
  UNION ALL
  SELECT d + INTERVAL 1 DAY FROM cal WHERE d < DATE '2019-12-31'
)
SELECT CAST(DATE_FORMAT(d, '%Y%m%d') AS UNSIGNED), d, DAY(d), DAYNAME(d), WEEKDAY(d) + 1,
       WEEKDAY(d) >= 5, WEEK(d, 3), MONTH(d), MONTHNAME(d), DATE_FORMAT(d, '%Y-%m'),
       QUARTER(d), CONCAT(YEAR(d), '-Q', QUARTER(d)), YEAR(d),
       d BETWEEN DATE '2017-01-01' AND DATE '2018-08-31'
FROM cal;

-- 5.5 Brazilian national holidays (fixed dates + Good Friday)
UPDATE olist_dm.dim_date
SET is_br_national_holiday = 1
WHERE date_key > 0
  AND (DATE_FORMAT(full_date, '%m-%d') IN ('01-01', '04-21', '05-01', '09-07', '10-12', '11-02', '11-15', '12-25')
       OR full_date IN (DATE '2016-03-25', DATE '2017-04-14', DATE '2018-03-30', DATE '2019-04-19'));

-- End of script
