CREATE OR REPLACE FUNCTION new_valuable_customers(
    current_date_param DATE,
    threshold_count INT,
    threshold_amount NUMERIC
)
RETURNS TABLE (
    cust_name TEXT,
    cust_phone TEXT
)
LANGUAGE sql
AS $$
SELECT
    c.cust_name,
    c.cust_phone
FROM customer c
JOIN orders o ON o.cust_id = c.cust_id
JOIN order_product op ON op.ord_id = o.ord_id
JOIN branch_product_supplier bps
  ON bps.prod_id = op.prod_id
 AND bps.branch_id = o.branch_id
LEFT JOIN refund r
  ON r.ord_id = op.ord_id
 AND r.prod_id = op.prod_id
WHERE c.relationship = 'NEW'
  AND o.reg_time >= current_date_param - INTERVAL '1 month'
  AND o.reg_time <  current_date_param
  AND r.ord_id IS NULL
GROUP BY c.cust_id, c.cust_name, c.cust_phone
HAVING COUNT(DISTINCT o.ord_id) >= threshold_count
   AND SUM(
       op.num * bps.ret_price * (100 - bps.discount) / 100.0
   ) >= threshold_amount;
$$;
EXPLAIN ANALYSE
SELECT *
FROM new_valuable_customers('2020-02-01'::DATE, 2, 2);