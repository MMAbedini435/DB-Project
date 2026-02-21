CREATE OR REPLACE FUNCTION average_profit_margin(cat_id_param INT)
RETURNS TABLE (
    subcat_name TEXT,
    avg_profit_per_item NUMERIC
)
LANGUAGE sql
AS $$
SELECT
    p.subcat_name,
    SUM((bps.ret_price * (1 - bps.discount / 100) - bps.prod_cost) * op.num) / SUM(op.num) AS avg_profit_per_item
FROM product p
JOIN subcategory s ON p.cat_id = s.cat_id AND p.subcat_name = s.subcat_name
JOIN order_product op ON op.prod_id = p.prod_id
JOIN orders o ON o.ord_id = op.ord_id
JOIN branch_product_supplier bps ON bps.prod_id = p.prod_id
LEFT JOIN refund r ON r.ord_id = op.ord_id AND r.prod_id = op.prod_id
WHERE p.cat_id = cat_id_param
  AND r.ord_id IS NULL
GROUP BY p.subcat_name;
$$;
EXPLAIN ANALYSE
SELECT * FROM average_profit_margin(1);