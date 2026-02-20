CREATE OR REPLACE FUNCTION get_order_total(p_ord_id INTEGER)
RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT 
        ROUND(
            COALESCE(SUM(
                -- Base Price
                (op.num * op.unit_price * (1.0 - COALESCE(op.discount, 0) / 100.0)) 
                * -- Tax
                (1.0 + (GREATEST(0, 10 - COALESCE(p.tax_exem, 0) - COALESCE(c.tax_exem, 0)) / 100.0))
            ), 0) 
            -- Shipping Cost
            + COALESCE(o.send_cost, 0), 
        2) -- Round to 2 decimal places
    INTO v_total
    FROM orders o
    JOIN customer c ON o.cust_id = c.cust_id
    LEFT JOIN order_product op ON o.ord_id = op.ord_id
    LEFT JOIN product p ON op.prod_id = p.prod_id
    WHERE o.ord_id = p_ord_id
    GROUP BY o.ord_id, o.send_cost;

    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

-- add purchases
INSERT INTO wallet_transaction (tran_id, cust_id, tran_date, sub_type, amount, ord_id)
SELECT 
    ROW_NUMBER() OVER (ORDER BY reg_time) AS tran_id,
    cust_id,
    reg_time AS tran_date,
    'Withdrawal' AS sub_type,
    get_order_total(ord_id) AS amount,
    ord_id
FROM orders
WHERE pay_met = 'In-App Wallet'
  AND proc_stat IN ('Shipped', 'Stocking', 'Received');

-- add refunds
INSERT INTO wallet_transaction (tran_id, cust_id, tran_date, sub_type, amount, ord_id)
SELECT 
    (SELECT COALESCE(MAX(tran_id), 0) FROM wallet_transaction) + ROW_NUMBER() OVER (ORDER BY r.reg_time),
    o.cust_id,
    r.reg_time,
    'Deposit',
    -- calculate item price and tax
    ROUND(
        (op.num * op.unit_price * (1.0 - op.discount / 100.0)) * (1.0 + (GREATEST(0, 10 - p.tax_exem - c.tax_exem) / 100.0)), 
    2),
    o.ord_id
FROM refund r
JOIN order_product op ON r.ord_id = op.ord_id AND r.prod_id = op.prod_id
JOIN orders o ON r.ord_id = o.ord_id
JOIN product p ON op.prod_id = p.prod_id
JOIN customer c ON o.cust_id = c.cust_id
WHERE r.ref_status = 'Approved refund' 
  AND o.pay_met = 'In-App Wallet';


-- BNPL payments
INSERT INTO wallet_transaction (tran_id, cust_id, tran_date, sub_type, amount, ord_id)
SELECT 
    (SELECT COALESCE(MAX(tran_id), 0) FROM wallet_transaction) + ROW_NUMBER() OVER (ORDER BY bp.pay_date),
    o.cust_id,
    bp.pay_date,
    'Withdrawal',
    bp.amount,
    bp.ord_id
FROM bnpl_payment bp
JOIN orders o ON bp.ord_id = o.ord_id
WHERE bp.pay_met = 'Wallet';


-- make up for the missing data gap
INSERT INTO wallet_transaction (tran_id, cust_id, tran_date, sub_type, amount, ord_id)
SELECT 
    (SELECT COALESCE(MAX(tran_id), 0) FROM wallet_transaction) + ROW_NUMBER() OVER (),
    w.cust_id,
    '2000-01-01'::TIMESTAMPTZ, 
    'Deposit',
    -- gap calculationk
    (w.balance - COALESCE(net_calc.current_net, 0)) AS missing_amount,
    NULL
FROM wallet w
LEFT JOIN (
    SELECT 
        cust_id,
        SUM(CASE WHEN sub_type = 'Deposit' THEN amount ELSE -amount END) AS current_net
    FROM wallet_transaction
    GROUP BY cust_id
) net_calc ON w.cust_id = net_calc.cust_id
-- only insert if there is a positive gap to fill
WHERE (w.balance - COALESCE(net_calc.current_net, 0)) > 0;