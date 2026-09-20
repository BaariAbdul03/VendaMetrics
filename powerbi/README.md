# Power BI Analytics Architecture & Implementation Guide

## 1. Executive Summary

This directory contains the complete Power BI data modeling layer for the **Olist Brazilian E-Commerce Analytics Suite**, connecting to MySQL 8.0 (`olist_ecommerce`).

### Deliverables Included
- **Modern Power BI Project (`olist_analytics.pbip`)**: Turnkey project with complete TMSL semantic model (`model.bim`), relationships, M partitions, and DAX measures. Double-click to open in Power BI Desktop.
- **Data Model Architecture (`model/DATA_MODEL.md`)**: Complete Star Schema documentation, entity profiles, cardinality, and relationship matrix.
- **Power Query ETL Suite (`power_query/`)**:
  - `dim_date.m` — Calendar dimension spanning 2016-01-01 to 2018-12-31.
  - `clean_customers.m` — Accent-stripped city normalization and typing.
  - `clean_products.m` — Left join with English translation and formatting.
  - `clean_orders.m` — Datetime splitting and delivery performance flags.
  - `clean_sellers.m` — City normalization and state typing.
  - `clean_geolocation.m` — Deduplicated 19,015 zip centroids from 1M rows.
  - `load_fact_sales.m` — Item-level fact table (110,197 delivered rows).
  - `load_all_tables.m` — Master copy-paste script.
- **DAX Repository (`dax/`)**:
  - `dax_measures.dax` — Production DAX measures organized by folder with verified benchmarks.
  - `calculated_columns.dax` — Repeat buyer flags, delivery delay buckets, and seller tiers.
- **Validation Schemas (`model/`)**:
  - `relationships.csv` — Exact relationship definitions (1:*, *:1, active/inactive).
  - `verification_benchmarks.csv` — SQL actuals vs DAX target benchmarks.

---

## 2. Star Schema Design

```
                    ┌───────────────────────────┐
                    │        fact_sales         │
                    │───────────────────────────│
              ┌────▶│ order_id (FK)             │◀────┐
              │     │ order_item_id             │     │
              │     │ product_id (FK)           │     │
              │     │ seller_id (FK)            │     │
              │     │ customer_id (FK)          │     │
              │     │ order_date (FK)           │     │
              │     │ revenue (price + freight) │     │
              │     │ is_late, delay_days       │     │
              │     │ review_score              │     │
              │     └─────────────┬─────────────┘     │
              │                   │                   │
    ┌─────────┴─────────┐         │         ┌─────────┴─────────┐
    │    olist_orders   │         │         │   olist_products  │
    │───────────────────│         │         │───────────────────│
    │ order_id (PK)     │         │         │ product_id (PK)   │
    │ customer_id (FK)  │         │         │ category_english  │
    │ purchase_date (FK)│         │         │ weight, dimensions│
    │ order_status      │         │         └───────────────────┘
    └─────────┬─────────┘         │
              │                   ▼
              │         ┌───────────────────┐
              │         │      DimDate      │
              │         │───────────────────│
              │         │ Date (PK)         │
              │         │ DateKey, Year     │
              │         │ MonthName, Quarter│
              │         │ YearMonth         │
              │         └───────────────────┘
              ▼
    ┌───────────────────┐                   ┌───────────────────┐
    │  olist_customers  │                   │   olist_sellers   │
    │───────────────────│                   │───────────────────│
    │ customer_id (PK)  │                   │ seller_id (PK)    │
    │ customer_unique_id│                   │ seller_city       │
    │ zip_prefix (FK)   │                   │ seller_state      │
    │ customer_city     │                   │ seller_tier       │
    │ Repeat_Purchases  │                   └─────────┬─────────┘
    └─────────┬─────────┘                             │
              │                                       │ (Inactive)
              ▼                                       ▼
    ┌───────────────────────────────────────────────────────────┐
    │                     olist_geolocation                     │
    │───────────────────────────────────────────────────────────│
    │ zip_code_prefix (PK) | latitude | longitude | city | state│
    └───────────────────────────────────────────────────────────┘
```

---

## 3. Verified Business Metrics & Benchmarks

Every measure was verified against the native MySQL database:

| Measure | SQL Actual | Target Benchmark | Formula / DAX Reference |
|---|---|---|---|
| **GMV** | **R$ 15,422,461.77** | R$ 15.4M | `CALCULATE(SUM(order_payments[payment_value]), orders[order_status]="delivered")` |
| **Total Orders** | **96,477** | 96.5K | `CALCULATE(COUNTROWS(orders), orders[order_status]="delivered")` |
| **AOV** | **R$ 159.86** | R$ 159.85 | `DIVIDE([GMV], [Total Orders], 0)` |
| **Unique Buyers** | **93,358** | 93.4K | `DISTINCTCOUNT(customers[customer_unique_id])` |
| **Repeat Buyers** | **2,801** | ~2,800 | `CALCULATE(DISTINCTCOUNT(...), Repeat_Purchases = 1)` |
| **Repeat Rate %** | **3.00%** | 3.0% | `DIVIDE([Repeat Customers], [Total Unique Customers], 0)` |
| **Late Delivery Rate %** | **8.11%** | ~8% | `DIVIDE([Late Deliveries], [Delivered Orders], 0)` (7,826 / 96,470) |
| **On-Time Rate %** | **91.89%** | ~92% | `1 - [Late Delivery Rate]` |
| **Avg Transit Days** | **12.5 days** | 12-13d | `AVERAGEX(..., DATEDIFF(purchase_date, delivered_date))` |
| **Active Sellers** | **2,970** | 2,970 | `CALCULATE(DISTINCTCOUNT(order_items[seller_id]), orders[order_status]="delivered")` |
| **Average Rating** | **4.16 / 5.00** | 4.15-4.2 | `AVERAGE(order_reviews[review_score])` |
| **Top 20% Seller Share** | **82.29%** | 80% (Pareto) | Confirms classical 80/20 marketplace revenue distribution |

---

## 4. How to Open & Use in Power BI Desktop

### Option A: Open PBIP Directly (Recommended)
1. Open Power BI Desktop (May 2023 release or newer).
2. Go to **File -> Open Report** -> Navigate to `powerbi/olist_analytics.pbip`.
3. Power BI loads all 10 tables, 9 relationships, and DAX measures automatically.
4. Click **Home -> Refresh** to load data from MySQL `localhost:3306/olist_ecommerce`.

### Option B: Manual Import via MySQL Connector
1. **Get Data -> MySQL Database**:
   - Server: `localhost:3306`
   - Database: `olist_ecommerce`
2. Select tables: `customers`, `orders`, `order_items`, `order_payments`, `order_reviews`, `products`, `sellers`, `geolocation`, `product_category_translation`, and view `fact_sales`.
3. In **Power Query Editor**:
   - Paste M scripts from `powerbi/power_query/` into the Advanced Editor of each query.
   - Add `DimDate` using `powerbi/power_query/dim_date.m`.
4. Click **Close & Apply**.
5. Switch to **Model View** and verify relationships match `model/relationships.csv`.
6. Switch to **Data View** and import DAX measures from `dax/dax_measures.dax`.
