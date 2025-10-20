{{
    config(
        materialized='table',
        tags=['silver', 'customers']
    )
}}

WITH cleaned_customers AS (
    SELECT
        id,
        INITCAP(TRIM(name)) as name,
        LOWER(TRIM(email)) as email,
        registration_date,
        birth_date,
        CASE 
            WHEN birth_date IS NOT NULL AND registration_date IS NOT NULL 
            THEN YEAR(registration_date) - YEAR(birth_date)
            ELSE NULL 
        END as age_at_registration,
        phone,
        INITCAP(TRIM(city)) as city,
        UPPER(TRIM(country)) as country,
        is_active,
        DATEDIFF(CURRENT_DATE(), DATE(registration_date)) as customer_tenure_days,
        _ingested_at,
        current_timestamp() as _processed_at
    FROM {{ ref('bronze_customers') }}
    WHERE email IS NOT NULL
        AND name IS NOT NULL
        AND registration_date IS NOT NULL
)

SELECT
    *,
    CASE 
        WHEN customer_tenure_days < 30 THEN 'New'
        WHEN customer_tenure_days < 180 THEN 'Recent'
        WHEN customer_tenure_days < 365 THEN 'Regular'
        ELSE 'Veteran'
    END as customer_lifetime_stage,
    CASE
        WHEN age_at_registration < 25 THEN '18-24'
        WHEN age_at_registration < 35 THEN '25-34'
        WHEN age_at_registration < 45 THEN '35-44'
        WHEN age_at_registration < 55 THEN '45-54'
        WHEN age_at_registration < 65 THEN '55-64'
        ELSE '65+'
    END as age_group
FROM cleaned_customers