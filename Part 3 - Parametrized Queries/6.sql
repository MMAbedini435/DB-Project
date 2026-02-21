CREATE OR REPLACE FUNCTION payed_taxes_for_customer(cust_id_param INT)
RETURNS TABLE (
    total_taxes NUMERIC
)
LANGUAGE sql
AS $$
SELECT SUM(
    op.num * (bps.ret_price * (1 - bps.discount / 100)) *
    (COALESCE(p.tax_exem, 0) + COALESCE(c.tax_exem, 0)) / 100
) AS total_taxes
FROM orders o
JOIN order_product op ON op.ord_id = o.ord_id
JOIN branch_product_supplier bps ON bps.prod_id = op.prod_id
JOIN product p ON p.prod_id = op.prod_id
JOIN customer c ON c.cust_id = o.cust_id
LEFT JOIN refund r ON r.ord_id = op.ord_id AND r.prod_id = op.prod_id
WHERE o.cust_id = cust_id_param
  AND r.ord_id IS NULL;
$$;
SELECT *
FROM payed_taxes_for_customer(10);