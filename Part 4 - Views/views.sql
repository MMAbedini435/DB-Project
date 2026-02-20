-- 1. Warehouse: unshipped items summary (no customer details)
CREATE VIEW warehouse_unshipped_items AS
SELECT
    op.prod_id,
    p.p_name,
    SUM(op.num) AS total_quantity,
    COUNT(DISTINCT o.ord_id) AS pending_orders_count
FROM order_product op
JOIN orders o ON op.ord_id = o.ord_id
JOIN product p ON op.prod_id = p.prod_id
WHERE o.proc_stat IN ('Pending Payment', 'Stocking')
GROUP BY op.prod_id, p.p_name;


-- 2. Accounting: daily sales and profit (materialized view)
CREATE MATERIALIZED VIEW accounting_daily_sales AS
SELECT
    DATE(o.reg_time) AS order_date,
    SUM(op.num * op.unit_price) AS total_sales,
    SUM(op.num * (op.unit_price - op.production_cost)) AS total_profit
FROM orders o
JOIN order_product op ON o.ord_id = op.ord_id
GROUP BY DATE(o.reg_time)
ORDER BY DATE(o.reg_time);


-- 3. Branch heads: customer details per branch
CREATE VIEW branch_customers AS
SELECT DISTINCT
    b.branch_id,
    b.b_name,
    c.cust_id,
    c.cust_name,
    c.age,
    c.sex,
    c.cust_phone,
    c.email,
    c.salary,
    c.relationship,
    c.tax_exem,
    c.subtype
FROM orders o
JOIN branch b ON o.branch_id = b.branch_id
JOIN customer c ON o.cust_id = c.cust_id;


-- 4. Marketing: customer loyalty information
-- Assuming a simple loyalty point system: 1 point per $10 spent
CREATE VIEW marketing_customer_loyalty AS
SELECT
    c.cust_id,
    c.cust_name,
    COALESCE(SUM(op.num * op.unit_price), 0) AS total_purchases,
    FLOOR(COALESCE(SUM(op.num * op.unit_price), 0) / 10) AS loyalty_points,
    CASE
        WHEN c.relationship = 'VIP' THEN 'VIP'
        WHEN c.relationship = 'LOYAL' THEN 'Loyal'
        ELSE 'New'
    END AS membership_level
FROM customer c
LEFT JOIN orders o ON c.cust_id = o.cust_id
LEFT JOIN order_product op ON o.ord_id = op.ord_id
GROUP BY c.cust_id, c.cust_name, c.relationship;


-- 5. Support: orders with pending refund requests
CREATE VIEW support_pending_refunds AS
SELECT
    r.ord_id,
    r.prod_id,
    o.cust_id,
    o.branch_id,
    r.reason,
    r.reg_time,
    r.dec_time,
    r.ref_status
FROM refund r
JOIN orders o ON r.ord_id = o.ord_id
WHERE r.ref_status = 'Awaiting refund review';