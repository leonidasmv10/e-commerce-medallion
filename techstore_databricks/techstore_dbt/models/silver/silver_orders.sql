{{
    config(
        materialized='table',
        tags=['silver', 'orders']
    )
}}

WITH cleaned_orders AS (
    SELECT
        id,
        customer_id,
        order_date,
        LOWER(TRIM(status)) as status,
        LOWER(TRIM(payment_method)) as payment_method,
        LOWER(TRIM(payment_status)) as payment_status,
        COALESCE(subtotal, 0) as subtotal,
        COALESCE(tax_amount, 0) as tax_amount,
        COALESCE(shipping_cost, 0) as shipping_cost,
        COALESCE(discount_amount, 0) as discount_amount,
        total_amount,
        estimated_delivery,
        actual_delivery,
        notes,
        _ingested_at,
        current_timestamp() as _processed_at
    FROM {{ ref('bronze_orders') }}
    WHERE customer_id IS NOT NULL
        AND order_date IS NOT NULL
        AND total_amount IS NOT NULL
        AND total_amount > 0
)

SELECT
    *,
    DATE(order_date) as order_date_only,
    YEAR(order_date) as order_year,
    MONTH(order_date) as order_month,
    DAYOFWEEK(order_date) as order_day_of_week,
    QUARTER(order_date) as order_quarter,
    CASE 
        WHEN actual_delivery IS NOT NULL THEN
            DATEDIFF(actual_delivery, order_date)
        ELSE NULL
    END as actual_delivery_days,
    CASE WHEN discount_amount > 0 THEN TRUE ELSE FALSE END as has_discount,
    CASE WHEN shipping_cost = 0 THEN TRUE ELSE FALSE END as free_shipping,
    CASE
        WHEN total_amount < 100 THEN 'Small'
        WHEN total_amount < 500 THEN 'Medium'
        WHEN total_amount < 1000 THEN 'Large'
        ELSE 'Enterprise'
    END as order_size,
    CASE DAYOFWEEK(order_date)
        WHEN 1 THEN 'Sunday'
        WHEN 2 THEN 'Monday'
        WHEN 3 THEN 'Tuesday'
        WHEN 4 THEN 'Wednesday'
        WHEN 5 THEN 'Thursday'
        WHEN 6 THEN 'Friday'
        WHEN 7 THEN 'Saturday'
    END as order_day_name,
    CASE 
        WHEN DAYOFWEEK(order_date) IN (1, 7) THEN TRUE 
        ELSE FALSE 
    END as is_weekend
FROM cleaned_orders