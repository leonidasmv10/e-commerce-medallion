{{
    config(
        materialized='table',
        tags=['silver', 'reviews']
    )
}}

WITH cleaned_reviews AS (
    SELECT
        id,
        product_id,
        customer_id,
        order_id,
        rating,
        TRIM(title) as title,
        TRIM(comment) as comment,
        review_date,
        is_verified_purchase,
        COALESCE(helpful_votes, 0) as helpful_votes,
        COALESCE(total_votes, 0) as total_votes,
        _ingested_at,
        current_timestamp() as _processed_at
    FROM {{ ref('bronze_reviews') }}
    WHERE product_id IS NOT NULL
        AND customer_id IS NOT NULL
        AND rating BETWEEN 1 AND 5
        AND review_date IS NOT NULL
)

SELECT
    *,
    CASE 
        WHEN total_votes > 0 THEN 
            ROUND((helpful_votes / total_votes) * 100, 2)
        ELSE 0
    END as helpfulness_ratio,
    CASE
        WHEN rating >= 4 THEN 'Positive'
        WHEN rating = 3 THEN 'Neutral'
        ELSE 'Negative'
    END as sentiment,
    LENGTH(comment) as comment_length,
    DATE(review_date) as review_date_only,
    YEAR(review_date) as review_year,
    MONTH(review_date) as review_month
FROM cleaned_reviews