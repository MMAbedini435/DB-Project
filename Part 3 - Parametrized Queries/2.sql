-- 2
CREATE OR REPLACE FUNCTION favorite_products(start_date TIMESTAMP, end_date TIMESTAMP)
RETURNS TABLE (
    p_name TEXT,
    avg_rating NUMERIC
)
LANGUAGE sql
AS $$
SELECT
    p.p_name,
    AVG(r.score) AS avg_rating
FROM orders o
JOIN order_product op ON op.ord_id = o.ord_id
JOIN product p ON p.prod_id = op.prod_id
LEFT JOIN review r ON r.ord_id = o.ord_id AND r.prod_id = p.prod_id
WHERE o.reg_time BETWEEN start_date AND end_date
GROUP BY p.p_name
ORDER BY avg_rating DESC NULLS LAST;
$$;

SELECT * FROM favorite_products('2024-01-01', '2024-12-31');