# Power BI 3-Page Dashboard Design & Visual Specification

This document details the visual architecture, coordinate layouts, DAX bindings, and drill-through pathways for the 3-page executive reporting suite in Power BI.

---

## Page 1: Executive KPIs

**Canvas Dimension:** 1280 × 720 px (16:9 standard)  
**Target Audience:** C-Suite, VP of Sales, Operations Director  
**Purpose:** High-level executive pulse on top-line revenue, order volumes, customer acquisition, fulfillment speed, and geographic distribution.

### Layout Grid & Visual Elements

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│ Header: Olist Marketplace — Executive Performance Dashboard           [Year] [State] [Status]│
├──────────────┬──────────────────────────────────────────────┬───────────────────────────────┤
│ GMV          │ Revenue & Order Volume Timeline              │ Payment Method Breakdown      │
│ R$ 15.42M    │ (Dual-Axis Monthly Line & Clustered Column)  │ (Donut Chart: Credit, Boleto) │
├──────────────┤                                              │                               │
│ Total Orders │                                              │                               │
│ 96,477       │                                              │                               │
├──────────────┼──────────────────────────────────────────────┼───────────────────────────────┤
│ AOV          │ Geographic Order Volume                      │ Order Delivery Health         │
│ R$ 159.86    │ (Filled Map / Regional Bar: SP, RJ, MG, RS)  │ (Late Rate vs Rating Card)    │
├──────────────┤                                              │                               │
│ Avg Rating   │                                              │ Late Rate: 8.11%              │
│ 4.16 ★       │                                              │ On-Time: 91.89%               │
└──────────────┴──────────────────────────────────────────────┴───────────────────────────────┘
```

### Visual Specifications

| Visual ID | Type | Title | Position (X, Y, W, H) | Data Fields / DAX Measures | Formatting / Visual Rules |
|---|---|---|---|---|---|
| **P1-V0** | Textbox | Header Banner | (0, 0, 1280, 56) | Static title + timestamp | Dark navy background (`#1A2530`), White 18pt bold text |
| **P1-V1** | KPI Card | Gross Merchandise Value | (16, 68, 200, 110) | `[GMV]` | Format: `R$ #,##0.00`, Accent bar: `#0080FF` |
| **P1-V2** | KPI Card | Total Delivered Orders | (16, 190, 200, 110) | `[Total Orders]` | Format: `#,##0`, Accent bar: `#1AAB40` |
| **P1-V3** | KPI Card | Average Order Value | (16, 312, 200, 110) | `[AOV]` | Format: `R$ #,##0.00`, Sub-text: `GMV / Orders` |
| **P1-V4** | KPI Card | Customer Satisfaction | (16, 434, 200, 110) | `[Avg Rating]` | Format: `0.00 ★`, Target: `4.00+` |
| **P1-V5** | KPI Card | Late Delivery Rate | (16, 556, 200, 110) | `[Late Delivery Rate]` | Format: `0.00%`, Callout color: Red (`#D64550`) |
| **P1-V6** | Slicers | Global Page Filters | (230, 68, 1034, 48) | `DimDate[Year]` (All, 2016-2018), `customers[customer_state_full]` (All 27 States with full names e.g., São Paulo, Rio de Janeiro), `order_payments[payment_type]` | Dynamic multi-select slicers with instant dashboard recalculation |
| **P1-V7** | Combo Chart | Revenue & Order Trend | (230, 128, 660, 290) | X-Axis: `DimDate[YearMonth]`<br>Column Y: `[GMV]`<br>Line Y: `[Total Orders]` | Bar color: Soft Blue (`#4092FF`), Line: Coral (`#E66C37`) |
| **P1-V8** | Donut + Table | Payment Method Share (GMV) & Numbers List | (906, 128, 358, 290) | Legend: `order_payments[payment_type]`<br>Values: `SUM(payment_value)`<br>List: Orders, GMV (R$), Share % | Credit Card: 74,304 orders, R$ 12,101,094.88 (78.46%)<br>Boleto: 19,191 orders, R$ 2,769,932.58 (17.96%)<br>Voucher: 3,679 orders, R$ 343,013.19 (2.22%)<br>Debit Card: 1,485 orders, R$ 208,421.12 (1.35%) |
| **P1-V9** | Horizontal Bar | Top Customer States by Volume (Full Names) | (230, 430, 660, 274) | Y-Axis: `customers[state_full_name]`<br>X-Axis: `[Total Orders]`<br>Data Label: `[GMV]` | Full names displayed: São Paulo (SP), Rio de Janeiro (RJ), Minas Gerais (MG), Rio Grande do Sul (RS), Paraná (PR), Santa Catarina (SC), Bahia (BA), Distrito Federal (DF), Espírito Santo (ES), Goiás (GO) |
| **P1-V10** | Table Grid | State Order & GMV Breakdown | (906, 430, 358, 274) | Columns: Rank, Full State Name, State Code, Orders, GMV (R$) | Detailed data listing matching bar chart |

---

## Page 2: Category & Seller Concentration

**Canvas Dimension:** 1280 × 720 px  
**Target Audience:** Marketplace Category Managers, Merchant Acquisition Leads  
**Purpose:** Identify revenue drivers, 80/20 Pareto distribution, category profitability, and merchant quality concentration.

### Layout Grid & Visual Elements

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│ Header: Category & Seller Concentration — Pareto Analysis             [Category] [State]    │
├─────────────────────────────────────────────────────────────┬───────────────────────────────┤
│ Top 15 Product Categories with Cumulative Pareto % Curve    │ Seller Performance Matrix     │
│ (Combo: Revenue Bars + Cumulative % Second Axis Line at 80%)│ (Scatter: GMV vs Rating)      │
│                                                             │ High Rev / High Rating Quadrant│
├─────────────────────────────────────────────────────────────┼───────────────────────────────┤
│ Top 10 Marketplace Sellers                                  │ Category AOV Heatmap          │
│ (Table: Seller ID, State, GMV, Orders, Rating, Delay, Tier) │ (Matrix: Category × State)    │
│ [Right-Click -> Drill-Through to Seller Detail]             │                               │
└─────────────────────────────────────────────────────────────┴───────────────────────────────┘
```

### Visual Specifications

| Visual ID | Type | Title | Position (X, Y, W, H) | Data Fields / DAX Measures | Formatting / Visual Rules |
|---|---|---|---|---|---|
| **P2-V0** | Textbox | Header Banner | (0, 0, 1280, 56) | Category & Seller Intelligence | Dark navy background (`#1A2530`) |
| **P2-V1** | Combo Chart | Category Revenue & Pareto Curve | (16, 68, 760, 320) | Shared X: `products[category_english]` (Top 15)<br>Column Y: `[GMV]`<br>Line Y: `[Cumulative Category GMV %]`<br>Ref Line: `0.80` (80% Cutoff) | Column: Navy (`#12239E`), Pareto Line: Orange (`#FF6300`), 80% Threshold Dashed Line |
| **P2-V2** | Scatter Plot | Seller Revenue vs Rating | (792, 68, 472, 320) | X-Axis: `[GMV]`<br>Y-Axis: `[Avg Rating]`<br>Bubble Size: `[Total Orders]`<br>Category: `sellers[seller_id]`<br>Quadrant Lines: X=R$50k, Y=3.8★ | Upper-Right: Champions (High GMV, High Rating)<br>Lower-Right: At-Risk High Volume |
| **P2-V3** | Table | Top 10 Marketplace Sellers | (16, 400, 760, 304) | Columns: `seller_id`, `seller_state`, `[GMV]`, `[Total Orders]`, `[Avg Rating]`, `[Avg Delivery Delay Days]`, `seller_revenue_tier` | Conditional rating colors: Green (>=4.0), Amber (3.5-4.0), Red (<3.5). **Drill-through enabled**. |
| **P2-V4** | Matrix | Category AOV by Top Region | (792, 400, 472, 304) | Rows: `products[category_english]`<br>Columns: `customers[customer_state]` (SP, RJ, MG, RS, PR)<br>Values: `[AOV]` | Background color conditional heatmap: Light blue to dark navy |

---

## Page 3: Delivery vs Customer Satisfaction

**Canvas Dimension:** 1280 × 720 px  
**Target Audience:** VP of Logistics, Customer Experience Lead, Carrier Relations  
**Purpose:** Pinpoint the exact correlation between transit delays and review score collapse, analyze carrier SLA performance, and inspect cohort retention.

### Layout Grid & Visual Elements

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│ Header: Fulfillment SLA & Satisfaction Intelligence                    [Product Category]   │
├──────────────────────────────┬──────────────────────────────┬───────────────────────────────┤
│ Delivery Delay Severity vs   │ Customer Review Score Spread │ Monthly Late Order Trend      │
│ Average Review Rating        │ (1 to 5 Stars Distribution)  │ (Delivered vs Late Volume)    │
│ (Clustered Bar Chart)        │ (Column Histogram)           │                               │
├──────────────────────────────┼──────────────────────────────┴───────────────────────────────┤
│ Average Delay Days by State  │ Monthly Cohort Retention Matrix (Month 0 to Month 6)          │
│ (Bar / Map: SE vs NE / North)│ (Heatmap Grid: Cohort Size, Month 0 = 100%, Cliff to ~0.4%)   │
└──────────────────────────────┴───────────────────────────────────────────────────────────────┘
```

### Visual Specifications

| Visual ID | Type | Title | Position (X, Y, W, H) | Data Fields / DAX Measures | Formatting / Visual Rules |
|---|---|---|---|---|---|
| **P3-V0** | Textbox | Header Banner | (0, 0, 1280, 56) | Delivery & Customer Retention | Dark navy background (`#1A2530`) |
| **P3-V1** | Clustered Bar | Delay Bucket vs Review Score | (16, 68, 400, 310) | Y-Axis: `orders[delay_bucket]`<br>X-Axis: `[Avg Rating]`<br>Data Labels: Score (4.31 down to 1.70★) | Colors: Early/On-Time (Green `#1AAB40`), Slightly Late (Amber `#D9B300`), Late/Very Late (Red `#D64550`) |
| **P3-V2** | Column Chart | Review Score Distribution | (432, 68, 410, 310) | X-Axis: `order_reviews[review_score]` (1, 2, 3, 4, 5)<br>Y-Axis: `[Total Reviews]`<br>Tooltip: `% of Total Reviews` | 5★: 59.2%, 4★: 19.7%, 3★: 8.3%, 2★: 3.1%, 1★: 9.8% |
| **P3-V3** | Line Chart | Late Orders Monthly Trend | (858, 68, 406, 310) | X-Axis: `DimDate[YearMonth]`<br>Y-Axis: `[Late Deliveries]`, `[Delivered Orders]`<br>Secondary Y: `[Late Delivery Rate]` | Line showing delivery delay spikes in Feb-Mar 2018 postal strike |
| **P3-V4** | Bar Chart | Transit & Delay by State | (16, 394, 400, 310) | Y-Axis: `sellers[seller_state]`<br>X-Axis: `[Avg Delivery Days]` | Highlights fast transit in Southeast (SP ~8d) vs remote North/Northeast (20+ days) |
| **P3-V5** | Matrix Grid | Monthly Cohort Retention | (432, 394, 832, 310) | Rows: `v_cohort_retention[cohort_month]`<br>Columns: `v_cohort_retention[month_index]` (0, 1, 2, 3, 4, 5, 6)<br>Values: `MAX(retention_rate_pct)` | Diverging color scale heatmap: 100% dark green, <1% soft cream |

---

## Page 4: Seller Detail (Drill-Through Target)

**Canvas Dimension:** 1280 × 720 px  
**Activation:** Right-click any seller in Page 2 Top 10 Table or Scatter Plot -> **Drill-Through -> Seller Detail**  
**Filter Passed:** `sellers[seller_id]`

### Visual Specifications

| Visual ID | Type | Title | Position (X, Y, W, H) | Data Fields |
|---|---|---|---|---|
| **P4-V0** | Action Button | Back Button | (16, 16, 120, 36) | Action: Back to previous page |
| **P4-V1** | Textbox | Seller Header | (150, 16, 1114, 36) | Selected Seller Profile & Historic KPIs |
| **P4-V2** | Card | Seller GMV | (16, 68, 240, 100) | `[GMV]` |
| **P4-V3** | Card | Seller Orders | (272, 68, 240, 100) | `[Total Orders]` |
| **P4-V4** | Card | Seller Avg Rating | (528, 68, 240, 100) | `[Avg Rating]` |
| **P4-V5** | Card | Seller Late Rate % | (784, 68, 240, 100) | `[Late Delivery Rate]` |
| **P4-V6** | Card | Seller State | (1040, 68, 224, 100) | `FIRSTNONBLANK(sellers[seller_state], 1)` |
| **P4-V7** | Line Chart | Monthly Revenue History | (16, 184, 620, 250) | X: `DimDate[YearMonth]`, Y: `[GMV]` |
| **P4-V8** | Clustered Bar | Top Categories Sold | (652, 184, 612, 250) | Y: `products[category_english]`, X: `[GMV]` |
| **P4-V9** | Table | Recent Orders & Customer Reviews | (16, 450, 1248, 254) | `order_id`, `order_purchase_date`, `product_id`, `price`, `review_score` |

