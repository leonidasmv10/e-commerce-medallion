{{
    config(
        materialized='table',
        tags=['bronze', 'categories']
    )
}}

SELECT
    id, name, parent_category_id, description, is_active,
    current_timestamp() as _ingested_at,
    'techstore.product_categories' as _source_table
FROM {{ source('techstore', 'product_categories') }}