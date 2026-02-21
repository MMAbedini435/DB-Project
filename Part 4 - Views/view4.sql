-- 4- Marketing
CREATE OR REPLACE VIEW marketing_customer_loyalty AS
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
SELECT * FROM marketing_customer_loyalty;