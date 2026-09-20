-- ============================================================
-- FILE: 10_powerbi_views.sql
-- PURPOSE: Analytics Views for Direct Power BI Import and Reporting
-- Views Created:
--   1. fact_sales (and v_fact_sales)
--   2. v_kpi_summary
--   3. v_category_revenue
--   4. v_seller_performance
--   5. v_delivery_satisfaction
--   6. v_cohort_retention
-- Author: Abdul Baari
-- ============================================================

USE olist_ecommerce;

-- ── 1. FACT SALES VIEW (Granularity: 1 row per order item) ───
CREATE OR REPLACE VIEW fact_sales AS
SELECT
    oi.order_id,
    oi.order_item_id,
    oi.product_id,
    oi.seller_id,
    o.customer_id,
    c.customer_unique_id,
    o.order_status,
    o.order_purchase_timestamp,
    DATE(o.order_purchase_timestamp)                                                    AS order_date,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    oi.price,
    oi.freight_value,
    ROUND(oi.price + oi.freight_value, 2)                                               AS revenue,
    DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date)          AS delay_days,
    CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
         THEN 1 ELSE 0 END                                                              AS is_late,
    COALESCE(r.avg_review_score, 0)                                                     AS review_score
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN (
    SELECT order_id, ROUND(AVG(review_score), 2) AS avg_review_score
    FROM order_reviews
    GROUP BY order_id
) r ON oi.order_id = r.order_id
WHERE o.order_status = 'delivered';

CREATE OR REPLACE VIEW v_fact_sales AS SELECT * FROM fact_sales;


-- ── 2. KPI SUMMARY VIEW ──────────────────────────────────────
CREATE OR REPLACE VIEW v_kpi_summary AS
SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')            AS month,
    COUNT(DISTINCT o.order_id)                                  AS total_orders,
    COUNT(DISTINCT c.customer_unique_id)                        AS unique_customers,
    ROUND(SUM(p.payment_value), 2)                              AS total_revenue,
    ROUND(SUM(p.payment_value) / COUNT(DISTINCT o.order_id), 2) AS aov,
    ROUND(AVG(DATEDIFF(o.order_delivered_customer_date,
                       o.order_purchase_timestamp)), 1)         AS avg_delivery_days,
    ROUND(SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                   THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT o.order_id), 2) AS late_order_rate_pct,
    ROUND(AVG(r.review_score), 2)                               AS avg_review_score
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_payments p ON o.order_id = p.order_id
LEFT JOIN (
    SELECT order_id, AVG(review_score) AS review_score
    FROM order_reviews
    GROUP BY order_id
) r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY month;


-- ── 3. CATEGORY REVENUE & PARETO VIEW ────────────────────────
CREATE OR REPLACE VIEW v_category_revenue AS
WITH cat_base AS (
    SELECT
        COALESCE(t.product_category_name_english,
                 p.product_category_name, 'Unknown')            AS category,
        COUNT(DISTINCT oi.order_id)                             AS order_count,
        ROUND(SUM(oi.price), 2)                                 AS total_revenue,
        ROUND(AVG(oi.price), 2)                                 AS avg_price
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    JOIN products p ON oi.product_id = p.product_id
    LEFT JOIN product_category_translation t ON p.product_category_name = t.product_category_name
    WHERE o.order_status = 'delivered'
    GROUP BY category
)
SELECT
    category,
    order_count,
    total_revenue,
    avg_price,
    RANK() OVER (ORDER BY total_revenue DESC)                   AS revenue_rank,
    ROUND(SUM(total_revenue) OVER (ORDER BY total_revenue DESC
          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) * 100.0 /
          SUM(total_revenue) OVER (), 2)                        AS cumulative_pct,
    CASE WHEN (SUM(total_revenue) OVER (ORDER BY total_revenue DESC
               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) * 100.0 /
               SUM(total_revenue) OVER ()) <= 80
         THEN 'Top 80% (Pareto)' ELSE 'Tail 20%' END            AS pareto_segment
FROM cat_base;


-- ── 4. SELLER PERFORMANCE SCORECARD VIEW ─────────────────────
CREATE OR REPLACE VIEW v_seller_performance AS
SELECT
    oi.seller_id,
    s.seller_state,
    COUNT(DISTINCT oi.order_id)                                 AS total_orders,
    ROUND(SUM(oi.price), 2)                                     AS total_revenue,
    ROUND(AVG(oi.price), 2)                                     AS avg_item_price,
    ROUND(AVG(r.review_score), 2)                               AS avg_rating,
    ROUND(AVG(DATEDIFF(o.order_delivered_customer_date,
                       o.order_estimated_delivery_date)), 1)    AS avg_delay_days,
    ROUND(SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                   THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT oi.order_id), 2) AS late_delivery_rate_pct,
    DENSE_RANK() OVER (ORDER BY SUM(oi.price) DESC)             AS revenue_rank,
    CASE
        WHEN SUM(oi.price) > 50000 AND AVG(r.review_score) >= 4.0 THEN 'Top Performer'
        WHEN SUM(oi.price) > 20000 AND AVG(r.review_score) >= 3.5 THEN 'Good Performer'
        WHEN AVG(r.review_score) < 3.0 OR
             (SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                       THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT oi.order_id)) > 20
             THEN 'Underperformer'
        ELSE 'Average'
    END                                                         AS seller_segment
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN sellers s ON oi.seller_id = s.seller_id
LEFT JOIN (
    SELECT order_id, AVG(review_score) AS review_score
    FROM order_reviews
    GROUP BY order_id
) r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY oi.seller_id, s.seller_state;


-- ── 5. DELIVERY SATISFACTION VIEW ────────────────────────────
CREATE OR REPLACE VIEW v_delivery_satisfaction AS
WITH gap_data AS (
    SELECT
        o.order_id,
        DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) AS delay_days,
        r.review_score
    FROM orders o
    JOIN (
        SELECT order_id, AVG(review_score) AS review_score
        FROM order_reviews
        GROUP BY order_id
    ) r ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
)
SELECT
    CASE
        WHEN delay_days <= -7 THEN 'Early (>7d)'
        WHEN delay_days <= 0  THEN 'On-time (0-7d early)'
        WHEN delay_days <= 3  THEN 'Slightly Late (1-3d)'
        WHEN delay_days <= 7  THEN 'Late (4-7d)'
        ELSE 'Very Late (>7d)'
    END                                                                 AS delay_bucket,
    COUNT(*)                                                            AS order_count,
    ROUND(AVG(review_score), 2)                                         AS avg_review_score,
    ROUND(SUM(CASE WHEN review_score >= 4 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS satisfaction_rate_pct
FROM gap_data
GROUP BY delay_bucket;


-- ── 6. COHORT RETENTION VIEW ─────────────────────────────────
CREATE OR REPLACE VIEW v_cohort_retention AS
WITH first_purchase AS (
    SELECT
        c.customer_unique_id                            AS customer_id,
        MIN(DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')) AS cohort_month
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
all_purchases AS (
    SELECT
        c.customer_unique_id                            AS customer_id,
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
),
cohort_calc AS (
    SELECT
        f.cohort_month,
        a.order_month,
        a.customer_id,
        PERIOD_DIFF(REPLACE(a.order_month, '-', ''), REPLACE(f.cohort_month, '-', '')) AS month_index
    FROM all_purchases a
    JOIN first_purchase f ON a.customer_id = f.customer_id
),
cohort_base AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT customer_id)                     AS cohort_size
    FROM cohort_calc
    WHERE month_index = 0
    GROUP BY cohort_month
)
SELECT
    c.cohort_month,
    b.cohort_size,
    c.month_index,
    COUNT(DISTINCT c.customer_id)                      AS active_customers,
    ROUND(COUNT(DISTINCT c.customer_id) * 100.0 / b.cohort_size, 2) AS retention_rate_pct
FROM cohort_calc c
JOIN cohort_base b ON c.cohort_month = b.cohort_month
WHERE c.month_index <= 6
GROUP BY c.cohort_month, b.cohort_size, c.month_index;

SELECT 'All views created successfully.' AS status;

