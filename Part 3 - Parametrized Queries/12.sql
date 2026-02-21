CREATE OR REPLACE FUNCTION true_customer_value()
RETURNS TABLE (
    cust_id INT,
    true_value NUMERIC
)
LANGUAGE sql
AS $$
SELECT
    c.cust_id,
    COALESCE(SUM(wt.amount),0)
    +
    COALESCE(SUM(op.num * (bps.ret_price * (1 - bps.discount))),0)
    +
    COALESCE(SUM(op.num * (bps.ret_price * (1 - bps.discount)) *
          (COALESCE(p.tax_exem,0) + COALESCE(c.tax_exem,0))/100),0)
    +
    COALESCE(SUM(bp.amount),0)
    -
    COALESCE(SUM(op_r.num * (bps_r.ret_price * (1 - bps_r.discount))),0)
    AS true_value
FROM customer c
LEFT JOIN wallet_transaction wt ON wt.cust_id = c.cust_id
LEFT JOIN orders o ON o.cust_id = c.cust_id
LEFT JOIN order_product op ON op.ord_id = o.ord_id
LEFT JOIN branch_product_supplier bps ON bps.prod_id = op.prod_id AND bps.branch_id = o.branch_id
LEFT JOIN product p ON p.prod_id = op.prod_id
LEFT JOIN refund r ON r.ord_id = o.ord_id AND r.prod_id = op.prod_id
LEFT JOIN order_product op_r ON op_r.ord_id = r.ord_id AND op_r.prod_id = r.prod_id
LEFT JOIN branch_product_supplier bps_r ON bps_r.prod_id = op_r.prod_id AND bps_r.branch_id = o.branch_id
LEFT JOIN bnpl_payment bp ON bp.ord_id = o.ord_id
GROUP BY c.cust_id;
$$;
DROP INDEX IF EXISTS idx_refund_ord_prod;
CREATE INDEX idx_refund_ord_prod ON refund (ord_id, prod_id);
EXPLAIN ANALYZE SELECT *
FROM true_customer_value();