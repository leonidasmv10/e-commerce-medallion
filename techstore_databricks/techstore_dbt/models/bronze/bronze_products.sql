{{
    config(
        materialized='table',
        tags=['bronze', 'products']
    )
}}

SELECT
    id, name, description, category, subcategory, brand, model,
    price, cost, stock, weight_kg, dimensions, launch_date,
    is_active, created_at,
    current_timestamp() as _ingested_at,
    'techstore.products' as _source_table
FROM {{ source('techstore', 'products') }}