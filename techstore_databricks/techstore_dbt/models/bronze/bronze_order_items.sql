
{{
    config(
        materialized='table',
        tags=['bronze', 'order_items']
    )
}}

SELECT
    id, order_id, product_id, quantity, unit_price, unit_cost,
    line_total, discount_percent, created_at,
    current_timestamp() as _ingested_at,
    'techstore.order_items' as _source_table
FROM {{ source('techstore', 'order_items') }}
