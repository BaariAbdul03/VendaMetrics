# Marketplace Business Insights & Strategic Recommendations

**Dataset:** 100K+ Delivered Orders (2016–2018) | **Stack:** MySQL 8.0 & Power BI Star Schema  
**Validated GMV:** R$ 15,422,461.77 | **Total Delivered Orders:** 96,477  

---

## Insight 1: Extreme Category Revenue Concentration (Pareto 80/20 Rule)

**Finding:** The top 17 product categories (out of 74 total, or 23.0%) generate R$ 10,535,883.37, representing 79.69% of all marketplace product sales, while the bottom 57 categories account for only ~20%.

**Evidence:** Query output from `v_category_revenue`:
| Category (English) | Delivered Orders | Total GMV (R$) | Cumulative GMV % | Pareto Segment |
|---|---|---|---|---|
| **Health & Beauty** | 8,647 | R$ 1,233,131.72 | 9.33% | Top 80% (Pareto) |
| **Watches & Gifts** | 5,495 | R$ 1,166,176.98 | 18.15% | Top 80% (Pareto) |
| **Bed, Bath & Table** | 9,272 | R$ 1,023,434.76 | 25.89% | Top 80% (Pareto) |
| **Sports & Leisure** | 7,530 | R$ 954,852.55 | 33.11% | Top 80% (Pareto) |
| **Computers & Accessories** | 6,530 | R$ 888,724.61 | 39.83% | Top 80% (Pareto) |
| **Furniture & Decor** | 6,333 | R$ 711,114.65 | 45.21% | Top 80% (Pareto) |
| **Housewares** | 5,743 | R$ 613,991.68 | 49.85% | Top 80% (Pareto) |
| *Top 17 Categories Combined* | *73,812* | *R$ 10,535,883.37* | *79.69%* | *Top 80% (Pareto)* |

**Recommendation:** Concentrate vendor acquisition, co-marketing budgets, and featured catalog placement on the top 17 revenue engines, while transitioning long-tail categories to automated self-service seller onboarding.

---

## Insight 2: Delivery Delays Trigger a Precipitous Customer Rating Collapse

**Finding:** Customer review ratings remain buoyant above 4.15★ when orders arrive on-time or early, but collapse by 21.1% to 3.29★ for minor delays (1–3 days) and drop by 60.6% to 1.70★ for delays exceeding one week.

**Evidence:** Cross-analysis from `v_delivery_satisfaction` and `results/09_upgrade_q1.csv`:
| Delivery Bucket | Delivered Orders | Avg Review Score | Positive Rate (4–5★) | 1-Star Rating Share |
|---|---|---|---|---|
| **Early (>7 days early)** | 75,744 (78.5%) | **4.31 ★** | 83.4% | 6.5% |
| **On-Time (0–7 days early)** | 13,699 (14.2%) | **4.17 ★** | 78.4% | 7.4% |
| **Slightly Late (1–3 days late)** | 1,852 (1.9%) | **3.29 ★** | 53.2% | 25.2% |
| **Late (4–7 days late)** | 1,748 (1.8%) | **2.11 ★** | 22.5% | 58.5% |
| **Very Late (>7 days late)** | 2,781 (2.9%) | **1.70 ★** | 11.8% | 69.7% |

**Recommendation:** Deploy proactive carrier tracking webhooks that issue automated customer notifications and courtesy compensation vouchers (e.g., R$ 15 freight discount) on Day 1 of delay before the customer writes a negative 1-star review.

---

## Insight 3: The Repeat Purchase Paradox — High Lifetime Value Trapped in Single Orders

**Finding:** Only 3.00% of buyers (2,801 out of 93,358 unique delivered customers) make repeat purchases, yet repeat buyers spend an average of R$ 308.59 versus R$ 160.76 for one-time buyers—a 1.92x spend multiplier.

**Evidence:** Query analysis from `results/09_upgrade_q2.csv`:
| Customer Segment | Unique Customers | Order Count | Total GMV (R$) | Avg Spend / Customer |
|---|---|---|---|---|
| **Single-Order Buyers** | 90,556 (97.00%) | 90,556 | R$ 14,558,074.83 | R$ 160.76 |
| **Repeat Buyers (>1 Order)** | 2,801 (3.00%) | 5,921 | R$ 864,386.94 | R$ 308.59 |
| **Total Marketplace** | **93,358** | **96,477** | **R$ 15,422,461.77** | **R$ 165.19** |

**Recommendation:** Institute an automated lifecycle re-engagement engine (personalized SMS/email campaigns offering free shipping on second orders within 30 days of delivery) to lift repeat purchase rate from 3% to 6%, unlocking an estimated R$ 860K+ in high-margin GMV.

---

## Insight 4: Severe Merchant Revenue Inequality & Underperformer Churn Risk

**Finding:** The top 20% of merchants (594 sellers) generate 82.29% of total delivered revenue, whereas 472 underperforming merchants (with ratings <3.0★ or late delivery rates >20%) drive R$ 862,447.34 in volume while disproportionately generating 34.2% of all 1-star customer complaints.

**Evidence:** Decile and performance analysis from `results/09_upgrade_q3.csv` and `v_seller_performance`:
| Seller Tier | Active Sellers | Delivered Orders | Total Revenue (R$) | GMV Share | Avg Rating |
|---|---|---|---|---|---|
| **Decile 1 (Top 10%)** | 297 | 58,913 | R$ 8,872,994.75 | 67.11% | 4.15 ★ |
| **Decile 2 (Top 10–20%)** | 297 | 15,532 | R$ 2,006,851.32 | 15.18% | 4.12 ★ |
| **Deciles 3–5 (Mid 30%)** | 891 | 24,196 | R$ 1,904,064.21 | 14.40% | 4.08 ★ |
| **Deciles 6–10 (Bottom 50%)** | 1,485 | 11,556 | R$ 437,587.83 | 3.31% | 3.96 ★ |
| **Identified Underperformers** | 472 | 7,105 | R$ 862,447.34 | 6.52% | 2.74 ★ |

**Recommendation:** Assign dedicated partner success managers to the top 300 merchants while placing chronic underperformers (late rate >20%) on a 30-day fulfillment probation with automatic catalog suppression if SLA targets are missed.

---

## Insight 5: Post-Purchase Cohort Cliff — Retention Collapses Below 0.5% in Month 1

**Finding:** Across all monthly customer cohorts from 2017, active customer retention plunges from 100% at acquisition (Month 0) to between 0.28% and 0.62% in Month 1, remaining flat between 0.15% and 0.45% through Month 6.

**Evidence:** Retention grid analysis from `v_cohort_retention`:
| Cohort Month | Cohort Size (M0) | Month 1 Retention % | Month 2 Retention % | Month 3 Retention % | Month 4 Retention % | Month 5 Retention % | Month 6 Retention % |
|---|---|---|---|---|---|---|---|
| **2017-01** | 717 | 0.28% (2 users) | 0.28% (2 users) | 0.14% (1 user) | 0.42% (3 users) | 0.14% (1 user) | 0.42% (3 users) |
| **2017-02** | 1,628 | 0.18% (3 users) | 0.31% (5 users) | 0.12% (2 users) | 0.43% (7 users) | 0.12% (2 users) | 0.25% (4 users) |
| **2017-03** | 2,503 | 0.44% (11 users) | 0.36% (9 users) | 0.40% (10 users) | 0.36% (9 users) | 0.16% (4 users) | 0.16% (4 users) |
| **2017-04** | 2,256 | 0.62% (14 users) | 0.22% (5 users) | 0.18% (4 users) | 0.27% (6 users) | 0.27% (6 users) | 0.31% (7 users) |
| **2017-05** | 3,451 | 0.46% (16 users) | 0.46% (16 users) | 0.29% (10 users) | 0.29% (10 users) | 0.32% (11 users) | 0.41% (14 users) |
| **2017-06** | 3,037 | 0.49% (15 users) | 0.40% (12 users) | 0.43% (13 users) | 0.30% (9 users) | 0.40% (12 users) | 0.36% (11 users) |

**Recommendation:** Shift platform positioning from transactional discovery to a subscription delivery model (similar to Mercado Livre Meli+ or Amazon Prime) with subscription replenishment cadences for consumable categories (health & beauty, pet shop, food & drink).

