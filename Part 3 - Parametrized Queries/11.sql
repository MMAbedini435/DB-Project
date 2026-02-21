CREATE OR REPLACE FUNCTION best_suppliers()
RETURNS TABLE (
    branch_id INT,
    sup_id INT
)
LANGUAGE sql
AS $$
WITH sales AS (
    SELECT 
        bps.sup_id, 
        o.branch_id, 
        SUM(op.num) AS total_sold
    FROM order_product op
    JOIN orders o 
        ON o.ord_id = op.ord_id
    JOIN branch_product_supplier bps 
        ON bps.prod_id = op.prod_id AND bps.branch_id = o.branch_id
    LEFT JOIN refund r 
        ON r.ord_id = op.ord_id AND r.prod_id = op.prod_id
    WHERE r.ord_id IS NULL
    GROUP BY bps.sup_id, o.branch_id
),
sales_with_branch_total AS (
    SELECT 
        s.*,
        SUM(s.total_sold) OVER (PARTITION BY s.branch_id) AS branch_total
    FROM sales s
),
avg_lead AS (
    SELECT branch_id, AVG(lead_time_days) AS avg_lead_time
    FROM branch_product_supplier
    GROUP BY branch_id
)
SELECT s.branch_id, s.sup_id
FROM sales_with_branch_total s
JOIN avg_lead a 
    ON a.branch_id = s.branch_id
JOIN branch_product_supplier bps 
    ON bps.sup_id = s.sup_id AND bps.branch_id = s.branch_id
WHERE s.total_sold >= 0.5 * s.branch_total
   OR bps.lead_time_days < a.avg_lead_time;
$$;
DROP INDEX IF EXISTS idx_order_product_ordid_prod;
CREATE INDEX idx_order_product_ordid_prod ON order_product (ord_id, prod_id);
EXPLAIN ANALYSE SELECT *
FROM best_suppliers();