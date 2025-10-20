{{
    config(
        materialized='table',
        tags=['bronze', 'customers']
    )
}}

SELECT
    id,
    name,
    email,
    registration_date,
    birth_date,
    phone,
    city,
    country,
    is_active,
    current_timestamp() as _ingested_at,
    'techstore.customers' as _source_table
FROM {{ source('techstore', 'customers') }}