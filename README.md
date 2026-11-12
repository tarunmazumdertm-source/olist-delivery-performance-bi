# GR05 — From Order to Review

**HFU AIM | Business Intelligence & Big Data | WiSe 2026/27**

## 1. Project Overview

This project analyses how delivery performance affects customer satisfaction and sales using the Brazilian Olist e-commerce dataset.

### Main Research Question

**How does delivery performance affect customer satisfaction and sales?**

The project combines data engineering, business intelligence, exploratory data analysis and predictive analytics.

## 2. Dataset

Source: [Brazilian E-Commerce Public Dataset by Olist — Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

The dataset contains nine related CSV files covering customers, orders, order items, payments, reviews, products, sellers, geolocation and product category translations.

**Project analysis period:** 1 January 2017 – 31 August 2018.

| Population | Records |
|---|---:|
| Original source dataset | Approximately 1.55 million rows |
| Orders in project scope | 99,092 |
| Eligible orders | 97,910 |
| Valid delivered orders | 96,203 |
| Valid in-scope review rows | 98,879 |

Raw source files are not stored in this GitHub repository.

## 3. Key Business Findings

The following are the validated project KPI baselines.

| KPI | Result |
|---|---:|
| GMV | R$13,449,529.68 |
| Average Order Value | R$160.22 |
| On-time Delivery Rate | 93.21% |
| Average Delivery Time | 12.54 days |
| Average Late Delay | 10.62 days |
| Seller Dispatch Compliance | 91.06% |
| Delivery Estimate Buffer | 11.81 days |
| Average Latest Review Score | 4.09 / 5 |
| Poor Review Rate | 14.63% |
| On-time vs Late Review Score Gap | 2.02 stars |
| Repeat Customer Rate | 3.04% |

Late orders have an average latest review score of 2.27, compared with 4.29 for on-time orders.

These findings show an association, not proof of causation.

## 4. Data Architecture

The project follows a layered MySQL architecture.

```text
Olist CSV Source Files
        |
        v
PSA — Persistent Staging Area
9 raw source tables
        |
        v
DWH — Data Warehouse
10 cleansed tables in 3NF
        |
        v
Data Mart
10 dimensions
4 analytical fact tables
1 model score table
3 analytical views
        |
        v
Streamlit BI Dashboard
Python + Plotly
