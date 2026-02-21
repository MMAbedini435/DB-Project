CREATE OR REPLACE FUNCTION product_popularity_of_category(cat_id_param INT)
RETURNS TABLE (
    p_name TEXT,
    avg_rating NUMERIC
)
LANGUAGE sql
AS $$
SELECT
    p.p_name,
    AVG(r.score) AS avg_rating
FROM product p
LEFT JOIN review r ON r.prod_id = p.prod_id
WHERE p.cat_id = cat_id_param
GROUP BY p.p_name
ORDER BY avg_rating DESC NULLS LAST;
$$;
SELECT *
FROM product_popularity_of_category(1);