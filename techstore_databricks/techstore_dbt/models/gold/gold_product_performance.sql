{{
    config(
        materialized='table',
        tags=['gold', 'product_performance']
    )
}}

WITH product_sales AS (
    SELECT
        oi.product_id,
        COUNT(DISTINCT o.id) as total_orders,
        SUM(oi.quantity) as total_units_sold,
        SUM(oi.line_total) as total_revenue,
        SUM(oi.total_cost) as total_cost,
        SUM(oi.line_profit) as total_profit,
        AVG(oi.line_profit_margin_percent) as avg_profit_margin
    FROM {{ ref('silver_order_items') }} oi
    JOIN {{ ref('silver_orders') }} o ON oi.order_id = o.id
    WHERE o.status IN ('delivered', 'shipped')
    GROUP BY oi.product_id
),

product_reviews AS (
    SELECT
        product_id,
        COUNT(*) as total_reviews,
        AVG(rating) as avg_rating,
        SUM(CASE WHEN rating >= 4 THEN 1 ELSE 0 END) as positive_reviews
    FROM {{ ref('silver_reviews') }}
    GROUP BY product_id
)

SELECT
    p.id as product_id,
    p.name as product_name,
    p.category,
    p.subcategory,
    p.brand,
    p.price as current_price,
    p.stock as current_stock,
    p.stock_level,
    p.price_tier,
    p.is_active,
    COALESCE(ps.total_orders, 0) as total_orders,
    COALESCE(ps.total_units_sold, 0) as total_units_sold,
    COALESCE(ps.total_revenue, 0) as total_revenue,
    COALESCE(ps.total_profit, 0) as total_profit,
    COALESCE(ps.avg_profit_margin, 0) as actual_avg_margin,
    CASE
        WHEN COALESCE(ps.total_units_sold, 0) >= 100 THEN 'Best Seller'
        WHEN COALESCE(ps.total_units_sold, 0) >= 50 THEN 'Good'
        WHEN COALESCE(ps.total_units_sold, 0) >= 10 THEN 'Average'
        WHEN COALESCE(ps.total_units_sold, 0) > 0 THEN 'Slow'
        ELSE 'No Sales'
    END as sales_performance,
    COALESCE(pr.total_reviews, 0) as total_reviews,
    COALESCE(pr.avg_rating, 0) as avg_rating,
    ROUND(
        (COALESCE(pr.avg_rating, 0) / 5.0 * 30) +
        (LEAST(COALESCE(ps.total_units_sold, 0) / 100.0, 1) * 40) +
        (COALESCE(ps.avg_profit_margin, 0) / 100.0 * 30),
        1
    ) as product_health_score,
    current_timestamp() as _updated_at
FROM {{ ref('silver_products') }} p
LEFT JOIN product_sales ps ON p.id = ps.product_id
LEFT JOIN product_reviews pr ON p.id = pr.product_id