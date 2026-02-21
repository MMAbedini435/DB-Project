-- ۴
CREATE OR REPLACE FUNCTION product_dependencies(subcat_name_param TEXT, support_threshold INT)
RETURNS TABLE (
    correlated_type TEXT,
    support_count BIGINT
)
LANGUAGE sql
AS $$
SELECT
    DISTINCT p2.subcat_name AS correlated_type,
    COUNT(DISTINCT op.ord_id) AS support_count
FROM order_product op
JOIN product p1 ON p1.prod_id = op.prod_id
JOIN order_product op2 ON op2.ord_id = op.ord_id
JOIN product p2 ON p2.prod_id = op2.prod_id
WHERE p1.subcat_name = subcat_name_param
  AND p2.subcat_name <> subcat_name_param
GROUP BY p2.subcat_name
HAVING COUNT(DISTINCT op.ord_id) >= support_threshold;
$$;
SELECT *
FROM product_dependencies('Laptops', 5);