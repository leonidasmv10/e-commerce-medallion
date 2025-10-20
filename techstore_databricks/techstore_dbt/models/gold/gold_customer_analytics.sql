{{
    config(
        materialized='table',
        tags=['gold', 'customer_analytics']
    )
}}

WITH customer_orders AS (
    SELECT
        o.customer_id,
        COUNT(DISTINCT o.id) as total_orders,
        SUM(o.total_amount) as total_revenue,
        AVG(o.total_amount) as avg_order_value,
        MIN(o.order_date) as first_order_date,
        MAX(o.order_date) as last_order_date
    FROM {{ ref('silver_orders') }} o
    WHERE o.status IN ('delivered', 'shipped')
    GROUP BY o.customer_id
),

rfm_calculation AS (
    SELECT
        customer_id,
        DATEDIFF(CURRENT_DATE(), DATE(last_order_date)) as recency_days,
        total_orders as frequency,
        total_revenue as monetary
    FROM customer_orders
),

rfm_scores AS (
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary,
        CASE
            WHEN recency_days <= 30 THEN 5
            WHEN recency_days <= 90 THEN 4
            WHEN recency_days <= 180 THEN 3
            WHEN recency_days <= 365 THEN 2
            ELSE 1
        END as r_score,
        CASE
            WHEN frequency >= 10 THEN 5
            WHEN frequency >= 5 THEN 4
            WHEN frequency >= 3 THEN 3
            WHEN frequency >= 2 THEN 2
            ELSE 1
        END as f_score,
        CASE
            WHEN monetary >= 5000 THEN 5
            WHEN monetary >= 2000 THEN 4
            WHEN monetary >= 1000 THEN 3
            WHEN monetary >= 500 THEN 2
            ELSE 1
        END as m_score
    FROM rfm_calculation
),

rfm_segments AS (
    SELECT
        *,
        CONCAT(r_score, f_score, m_score) as rfm_score,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'VIP'
            WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal'
            WHEN r_score >= 4 AND f_score = 1 THEN 'New'
            WHEN r_score <= 2 AND f_score >= 2 THEN 'At Risk'
            WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost'
            ELSE 'Regular'
        END as customer_segment
    FROM rfm_scores
),

clv_calculation AS (
    SELECT
        co.customer_id,
        co.avg_order_value,
        ROUND(DATEDIFF(CURRENT_DATE(), DATE(co.first_order_date)) / 30.0, 1) as customer_lifetime_months,
        CASE 
            WHEN DATEDIFF(CURRENT_DATE(), DATE(co.first_order_date)) > 0 THEN
                ROUND(co.total_orders / (DATEDIFF(CURRENT_DATE(), DATE(co.first_order_date)) / 30.0), 2)
            ELSE 0
        END as purchase_frequency_per_month,
        ROUND((co.avg_order_value * co.total_orders) - 50, 2) as customer_lifetime_value
    FROM customer_orders co
)

SELECT
    c.id as customer_id,
    c.name,
    c.email,
    c.city,
    c.country,
    c.age_group,
    c.customer_lifetime_stage,
    c.is_active,
    COALESCE(co.total_orders, 0) as total_orders,
    COALESCE(co.total_revenue, 0) as total_revenue,
    COALESCE(co.avg_order_value, 0) as avg_order_value,
    co.first_order_date,
    co.last_order_date,
    rfm.recency_days,
    rfm.frequency,
    rfm.monetary,
    rfm.r_score,
    rfm.f_score,
    rfm.m_score,
    rfm.rfm_score,
    rfm.customer_segment,
    COALESCE(clv.customer_lifetime_value, 0) as customer_lifetime_value,
    current_timestamp() as _updated_at
FROM {{ ref('silver_customers') }} c
LEFT JOIN customer_orders co ON c.id = co.customer_id
LEFT JOIN rfm_segments rfm ON c.id = rfm.customer_id
LEFT JOIN clv_calculation clv ON c.id = clv.customer_id