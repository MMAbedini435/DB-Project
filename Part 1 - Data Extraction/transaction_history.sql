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



INSERT INTO wallet_transaction (tran_id, cust_id, tran_date, sub_type, amount, ord_id)
WITH 
-- List all the wallet orders
all_withdrawals AS (
    SELECT 
        cust_id, 
        reg_time as tran_date, 
        'Withdrawal'::VARCHAR(10) as sub_type, 
        get_order_total(ord_id) as amount, 
        ord_id
    FROM orders
    WHERE pay_met = 'In-App Wallet' 
      AND proc_stat IN ('Shipped', 'Stocking', 'Received')
),

-- Made up starting deposit for consistency
initial_deposits AS (
    SELECT 
        w.cust_id, 
        '2000-01-01'::TIMESTAMPTZ as tran_date, 
        'Deposit'::VARCHAR(10) as sub_type,
        (w.balance + COALESCE(SUM(aw.amount), 0)) as amount,
        NULL::INTEGER as ord_id
    FROM wallet w
    LEFT JOIN all_withdrawals aw ON w.cust_id = aw.cust_id
    GROUP BY w.cust_id, w.balance
)

-- Combine all
SELECT 
    ROW_NUMBER() OVER (ORDER BY tran_date) as tran_id,
    cust_id, 
    tran_date, 
    sub_type, 
    amount, 
    ord_id
FROM (
    SELECT * FROM initial_deposits
    UNION ALL
    SELECT * FROM all_withdrawals
) combined_data;