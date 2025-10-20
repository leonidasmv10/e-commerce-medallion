{{
    config(
        materialized='table',
        tags=['silver', 'products']
    )
}}

WITH cleaned_products AS (
    SELECT
        id,
        TRIM(name) as name,
        TRIM(description) as description,
        TRIM(category) as category,
        TRIM(subcategory) as subcategory,
        TRIM(brand) as brand,
        TRIM(model) as model,
        CAST(price AS DECIMAL(10,2)) as price,
        CAST(cost AS DECIMAL(10,2)) as cost,
        CAST(stock AS INT) as stock,
        weight_kg,
        dimensions,
        launch_date,
        is_active,
        created_at,
        _ingested_at,
        current_timestamp() as _processed_at
    FROM {{ ref('bronze_products') }}
    WHERE name IS NOT NULL
        AND price > 0
        AND cost > 0
        AND category IS NOT NULL
)

SELECT
    *,
    ROUND(((price - cost) / price) * 100, 2) as profit_margin_percent,
    ROUND(price - cost, 2) as unit_profit,
    DATEDIFF(CURRENT_DATE(), launch_date) as days_since_launch,
    CASE
        WHEN stock = 0 THEN 'Out of Stock'
        WHEN stock < 10 THEN 'Critical'
        WHEN stock < 50 THEN 'Low'
        WHEN stock < 100 THEN 'Medium'
        ELSE 'High'
    END as stock_level,
    CASE
        WHEN price < 100 THEN 'Budget'
        WHEN price < 500 THEN 'Mid-Range'
        WHEN price < 1000 THEN 'Premium'
        ELSE 'Luxury'
    END as price_tier,
    CASE
        WHEN DATEDIFF(CURRENT_DATE(), launch_date) < 90 THEN 'New Launch'
        WHEN DATEDIFF(CURRENT_DATE(), launch_date) < 365 THEN 'Current'
        WHEN DATEDIFF(CURRENT_DATE(), launch_date) < 730 THEN 'Mature'
        ELSE 'Legacy'
    END as lifecycle_stage
FROM cleaned_products