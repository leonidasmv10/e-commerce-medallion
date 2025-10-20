{{
    config(
        materialized='table',
        tags=['bronze', 'reviews']
    )
}}

SELECT
    id, product_id, customer_id, order_id, rating, title, comment,
    review_date, is_verified_purchase, helpful_votes, total_votes,
    current_timestamp() as _ingested_at,
    'techstore.reviews' as _source_table
FROM {{ source('techstore', 'reviews') }}