{{
    config(
        materialized='table',
        tags=['bronze', 'orders']
    )
}}

SELECT
    id, customer_id, order_date, status, payment_method, payment_status,
    subtotal, tax_amount, shipping_cost, discount_amount, total_amount,
    shipping_address, estimated_delivery, actual_delivery, notes,
    current_timestamp() as _ingested_at,
    'techstore.orders' as _source_table
FROM {{ source('techstore', 'orders') }}