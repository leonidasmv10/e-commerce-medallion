{{
    config(
        materialized='table',
        tags=['gold', 'operational']
    )
}}

SELECT
    CURRENT_DATE() as report_date,
    'Last 30 Days' as period,
    COUNT(*) as total_orders,
    SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) as cancelled_orders,
    ROUND((SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) as cancellation_rate,
    AVG(CASE WHEN actual_delivery_days IS NOT NULL THEN actual_delivery_days ELSE NULL END) as avg_delivery_days,
    SUM(total_amount) as total_revenue,
    current_timestamp() as _updated_at
FROM {{ ref('silver_orders') }}
WHERE order_date >= DATE_SUB(CURRENT_DATE(), 30)