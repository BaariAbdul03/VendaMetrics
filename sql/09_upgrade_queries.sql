-- ============================================================
-- FILE: 09_upgrade_queries.sql
-- PURPOSE: Advanced Upgrade Queries for Olist Marketplace Analytics
-- Questions:
--   1. Delivery delay severity vs Customer Satisfaction & Rating Drop
--   2. Unique Customer Repeat Rate & Spend Multiplier
--   3. Marketplace Seller Revenue Concentration (Pareto Deciles)
-- Author: Abdul Baari
-- ============================================================

USE olist_ecommerce;

-- ── QUERY 1: DELIVERY DELAY SEVERITY vs REVIEW SCORE & RATING COLLAPSE ──
-- Business Question: Exactly how fast does review score collapse when delivery is late?
WITH delivery_gap AS (
    SELECT
        o.order_id,
        DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) AS delay_days,
        r.review_score
    FROM orders o
    JOIN order_reviews r ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
)
SELECT
    CASE
        WHEN delay_days <= -7 THEN '1. Early (>7d)'
        WHEN delay_days <= 0  THEN '2. Early/On-time (0-7d)'
        WHEN delay_days <= 3  THEN '3. Slightly Late (1-3d)'
        WHEN delay_days <= 7  THEN '4. Late (4-7d)'
        ELSE '5. Very Late (>7d)'
    END                                                                 AS delivery_bucket,
    COUNT(*)                                                            AS total_orders,
    ROUND(AVG(review_score), 2)                                         AS avg_review_score,
    ROUND(SUM(CASE WHEN review_score = 5 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_5_star,
    ROUND(SUM(CASE WHEN review_score = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_1_star
FROM delivery_gap
GROUP BY delivery_bucket
ORDER BY delivery_bucket;


-- ── QUERY 2: REPEAT CUSTOMER RATE & VALUE MULTIPLIER ──────────
-- Business Question: What % of buyers return, and how much more do repeat buyers spend?
-- Note: Must use customer_unique_id because customer_id changes per transaction.
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id)  AS order_count,
        SUM(p.payment_value)        AS total_spend
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_payments p ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT
    COUNT(*)                                                                    AS total_unique_customers,
    SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END)                            AS repeat_customers,
    ROUND(SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS repeat_customer_rate_pct,
    SUM(CASE WHEN order_count = 1 THEN 1 ELSE 0 END)                            AS one_time_customers,
    ROUND(SUM(CASE WHEN order_count = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS one_time_customer_pct,
    ROUND(SUM(CASE WHEN order_count > 1 THEN total_spend ELSE 0 END), 2)        AS repeat_revenue,
    ROUND(SUM(total_spend), 2)                                                  AS total_revenue,
    ROUND(SUM(CASE WHEN order_count > 1 THEN total_spend ELSE 0 END) * 100.0 / SUM(total_spend), 2) AS repeat_revenue_pct,
    ROUND(AVG(CASE WHEN order_count > 1 THEN total_spend END), 2)               AS avg_repeat_customer_spend,
    ROUND(AVG(CASE WHEN order_count = 1 THEN total_spend END), 2)               AS avg_one_time_spend,
    ROUND(AVG(CASE WHEN order_count > 1 THEN total_spend END) /
          AVG(CASE WHEN order_count = 1 THEN total_spend END), 2)               AS spend_multiplier
FROM customer_orders;


-- ── QUERY 3: SELLER REVENUE CONCENTRATION (PARETO DECILES) ────
-- Business Question: Are marketplace sellers subject to power-law revenue concentration?
WITH seller_rev AS (
    SELECT
        oi.seller_id,
        s.seller_state,
        COUNT(DISTINCT oi.order_id) AS total_orders,
        SUM(oi.price)               AS seller_revenue
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    JOIN sellers s ON oi.seller_id = s.seller_id
    WHERE o.order_status = 'delivered'
    GROUP BY oi.seller_id, s.seller_state
),
seller_ranked AS (
    SELECT
        seller_id,
        seller_state,
        total_orders,
        seller_revenue,
        ROW_NUMBER() OVER (ORDER BY seller_revenue DESC) AS seller_rank,
        COUNT(*) OVER () AS total_sellers,
        SUM(seller_revenue) OVER () AS total_marketplace_revenue,
        SUM(seller_revenue) OVER (ORDER BY seller_revenue DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_revenue,
        NTILE(10) OVER (ORDER BY seller_revenue DESC) AS decile
    FROM seller_rev
)
SELECT
    decile,
    COUNT(*)                                                                AS sellers_in_decile,
    ROUND(SUM(seller_revenue), 2)                                           AS decile_revenue,
    ROUND(SUM(seller_revenue) * 100.0 / MAX(total_marketplace_revenue), 2)  AS decile_revenue_pct,
    ROUND(MAX(running_revenue) * 100.0 / MAX(total_marketplace_revenue), 2) AS cumulative_revenue_pct,
    ROUND(AVG(total_orders), 1)                                             AS avg_orders_per_seller
FROM seller_ranked
GROUP BY decile
ORDER BY decile;

