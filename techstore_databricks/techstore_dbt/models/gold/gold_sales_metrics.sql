{{
    config(
        materialized='table',
        tags=['gold', 'sales_metrics']
    )
}}

WITH daily_sales AS (
    SELECT
        DATE(order_date) as sale_date,
        COUNT(DISTINCT id) as daily_orders,
        COUNT(DISTINCT customer_id) as daily_customers,
        SUM(total_amount) as daily_revenue,
        AVG(total_amount) as daily_aov,
        order_day_name,
        is_weekend
    FROM {{ ref('silver_orders') }}
    WHERE status IN ('delivered', 'shipped', 'confirmed')
    GROUP BY DATE(order_date), order_day_name, is_weekend
),

monthly_sales AS (
    SELECT
        DATE_TRUNC('month', order_date) as month_start,
        YEAR(order_date) as year,
        MONTH(order_date) as month,
        COUNT(DISTINCT id) as monthly_orders,
        COUNT(DISTINCT customer_id) as monthly_customers,
        SUM(total_amount) as monthly_revenue,
        AVG(total_amount) as monthly_aov
    FROM {{ ref('silver_orders') }}
    WHERE status IN ('delivered', 'shipped', 'confirmed')
    GROUP BY DATE_TRUNC('month', order_date), YEAR(order_date), MONTH(order_date)
)

SELECT DISTINCT
    ds.sale_date,
    ds.daily_orders,
    ds.daily_customers,
    ds.daily_revenue,
    ds.daily_aov,
    ds.order_day_name,
    ds.is_weekend,
    ms.month_start,
    ms.year,
    ms.month,
    ms.monthly_orders,
    ms.monthly_customers,
    ms.monthly_revenue,
    ms.monthly_aov,
    LAG(ms.monthly_revenue) OVER (ORDER BY ms.month_start) as prev_month_revenue,
    ROUND(
        ((ms.monthly_revenue - LAG(ms.monthly_revenue) OVER (ORDER BY ms.month_start)) / 
         NULLIF(LAG(ms.monthly_revenue) OVER (ORDER BY ms.month_start), 0)) * 100, 
        2
    ) as mom_revenue_growth_percent,
    current_timestamp() as _updated_at
FROM daily_sales ds
LEFT JOIN monthly_sales ms ON DATE_TRUNC('month', ds.sale_date) = ms.month_start