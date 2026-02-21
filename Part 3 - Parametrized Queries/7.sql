CREATE OR REPLACE FUNCTION interbranch_customers(branch_id1 INT, branch_id2 INT)
RETURNS TABLE (
    cust_name TEXT,
    cust_phone TEXT,
    orders_branch1 BIGINT,
    orders_branch2 BIGINT,
    branch_more_orders INT
)
LANGUAGE sql
AS $$
WITH cust1 AS (
    SELECT o.cust_id, COUNT(*) AS cnt1 FROM orders o WHERE o.branch_id = branch_id1 GROUP BY o.cust_id
),
cust2 AS (
    SELECT o.cust_id, COUNT(*) AS cnt2 FROM orders o WHERE o.branch_id = branch_id2 GROUP BY o.cust_id
)
SELECT
    c.cust_name,
    c.cust_phone,
    COALESCE(c1.cnt1,0) AS orders_branch1,
    COALESCE(c2.cnt2,0) AS orders_branch2,
    CASE WHEN COALESCE(c1.cnt1,0) >= COALESCE(c2.cnt2,0) THEN branch_id1 ELSE branch_id2 END AS branch_more_orders
FROM customer c
JOIN cust1 c1 ON c.cust_id = c1.cust_id
JOIN cust2 c2 ON c.cust_id = c2.cust_id;
$$;
SELECT *
FROM interbranch_customers(1, 2);
