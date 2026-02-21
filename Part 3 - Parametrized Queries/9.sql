CREATE OR REPLACE FUNCTION bnpl_available_debt(cust_id_param INT, purchase_amount NUMERIC)
RETURNS TABLE (
    bnpl_limit NUMERIC,
    current_debt NUMERIC,
    can_pay BOOLEAN
)
LANGUAGE sql
AS $$
WITH owed AS (
    SELECT SUM(op.num * (bps.ret_price * (1 - bps.discount / 100)) *
        (1 + (COALESCE(p.tax_exem,0)+COALESCE(c.tax_exem,0))/100)) AS total_owed
    FROM orders o
    JOIN order_product op ON op.ord_id = o.ord_id
    JOIN branch_product_supplier bps ON bps.prod_id = op.prod_id
    JOIN product p ON p.prod_id = op.prod_id
    JOIN customer c ON c.cust_id = o.cust_id
    LEFT JOIN refund r ON r.ord_id = op.ord_id AND r.prod_id = op.prod_id
    WHERE o.cust_id = cust_id_param
      AND r.ord_id IS NULL
), paid_bnpl AS (
    SELECT COALESCE(SUM(amount),0) AS paid_amount
    FROM bnpl_payment bp
    JOIN bnpl_contract bc ON bc.ord_id = bp.ord_id
    JOIN orders o ON o.ord_id = bp.ord_id
    WHERE o.cust_id = cust_id_param
)
SELECT
    w.debt_limit AS bnpl_limit,
    owed.total_owed - paid_bnpl.paid_amount AS current_debt,
    CASE WHEN w.debt_limit >= purchase_amount THEN TRUE ELSE FALSE END AS can_pay
FROM wallet w, owed, paid_bnpl
WHERE w.cust_id = cust_id_param;
$$;
SELECT *
FROM bnpl_available_debt(10, 500);