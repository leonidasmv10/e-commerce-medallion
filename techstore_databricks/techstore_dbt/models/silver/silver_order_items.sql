{{
    config(
        materialized='table',
        tags=['silver', 'order_items']
    )
}}

WITH cleaned_order_items AS (
    SELECT
        id,
        order_id,
        product_id,
        quantity,
        CAST(unit_price AS DECIMAL(10,2)) as unit_price,
        CAST(unit_cost AS DECIMAL(10,2)) as unit_cost,
        CAST(line_total AS DECIMAL(10,2)) as line_total,
        COALESCE(discount_percent, 0) as discount_percent,
        created_at,
        _ingested_at,
        current_timestamp() as _processed_at
    FROM {{ ref('bronze_order_items') }}
    WHERE order_id IS NOT NULL
        AND product_id IS NOT NULL
        AND quantity > 0
        AND unit_price > 0
)

SELECT
    *,
    ROUND(quantity * unit_cost, 2) as total_cost,
    ROUND(line_total - (quantity * unit_cost), 2) as line_profit,
    ROUND(((line_total - (quantity * unit_cost)) / line_total) * 100, 2) as line_profit_margin_percent,
    ROUND(quantity * unit_price, 2) as original_line_total,
    ROUND((quantity * unit_price) - line_total, 2) as discount_amount,
    CASE 
        WHEN discount_percent > 0 THEN TRUE 
        ELSE FALSE 
    END as has_discount
FROM cleaned_order_items