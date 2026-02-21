--------- AVERAGE PROFIT MARGIN
-- Inputs: $1 = cat_id
SELECT
    p.subcat_name,
    SUM((bps.ret_price * (1 - bps.discount) - bps.prod_cost) * op.num) / SUM(op.num) AS avg_profit_per_item
FROM product p
JOIN subcategory s ON p.cat_id = s.cat_id AND p.subcat_name = s.subcat_name
JOIN order_product op ON op.prod_id = p.prod_id
JOIN orders o ON o.ord_id = op.ord_id
JOIN branch_product_supplier bps ON bps.prod_id = p.prod_id
LEFT JOIN refund r ON r.ord_id = op.ord_id AND r.prod_id = op.prod_id
WHERE p.cat_id = $1
  AND r.ord_id IS NULL  -- exclude refunded items
GROUP BY p.subcat_name;



--------- FAVORITE PRODUCTS
-- Inputs: $1 = start_date, $2 = end_date
SELECT
    p.p_name,
    AVG(r.score) AS avg_rating
FROM orders o
JOIN order_product op ON op.ord_id = o.ord_id
JOIN product p ON p.prod_id = op.prod_id
LEFT JOIN review r ON r.ord_id = o.ord_id AND r.prod_id = p.prod_id
WHERE o.reg_time BETWEEN $1 AND $2
GROUP BY p.p_name
ORDER BY avg_rating DESC NULLS LAST;



--------- NEW VALUABLE CUSTOMERS
-- Inputs: $1 = current_date, $2 = threshold_count, $3 = threshold_amount
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
  AND o.reg_time >= $1 - INTERVAL '1 month'
  AND o.reg_time <  $1
  AND r.ord_id IS NULL
GROUP BY c.cust_id, c.cust_name, c.cust_phone
HAVING COUNT(DISTINCT o.ord_id) >= $2
   AND SUM(
       op.num * bps.ret_price * (100 - bps.discount) / 100.0
   ) >= $3;



--------- PRODUCT DEPENDENCIES
-- Inputs: $1 = subcat_name, $2 = support_threshold
SELECT
    DISTINCT p2.subcat_name AS correlated_type,
    COUNT(DISTINCT op.ord_id) AS support_count
FROM order_product op
JOIN product p1 ON p1.prod_id = op.prod_id
JOIN order_product op2 ON op2.ord_id = op.ord_id
JOIN product p2 ON p2.prod_id = op2.prod_id
WHERE p1.subcat_name = $1
  AND p2.subcat_name <> $1
GROUP BY p2.subcat_name
HAVING COUNT(DISTINCT op.ord_id) >= $2;



--------- DELAYED PRODUCTS
SELECT o.ord_id
FROM orders o
WHERE (o.send_type = 'Same day delivery' AND DATE(o.send_time) <> DATE(o.reg_time))
   OR (o.send_type = 'Normal' AND o.send_time > o.reg_time + INTERVAL '2 days');



--------- PAYED TAXES FOR A CUSTOMER
-- Inputs: $1 = cust_id
SELECT SUM(
    op.num * (bps.ret_price * (1 - bps.discount)) * (COALESCE(p.tax_exem, 0) + COALESCE(c.tax_exem, 0)) / 100
) AS total_taxes
FROM orders o
JOIN order_product op ON op.ord_id = o.ord_id
JOIN branch_product_supplier bps ON bps.prod_id = op.prod_id
JOIN product p ON p.prod_id = op.prod_id
JOIN customer c ON c.cust_id = o.cust_id
LEFT JOIN refund r ON r.ord_id = op.ord_id AND r.prod_id = op.prod_id
WHERE o.cust_id = $1
  AND r.ord_id IS NULL;




--------- INTERBRANCH CUSTOMERS
-- Inputs: $1 = branch_id1, $2 = branch_id2
WITH cust1 AS (
    SELECT o.cust_id, COUNT(*) AS cnt1 FROM orders o WHERE o.branch_id = $1 GROUP BY o.cust_id
),
cust2 AS (
    SELECT o.cust_id, COUNT(*) AS cnt2 FROM orders o WHERE o.branch_id = $2 GROUP BY o.cust_id
)
SELECT
    c.cust_name,
    c.cust_phone,
    COALESCE(c1.cnt1,0) AS orders_branch1,
    COALESCE(c2.cnt2,0) AS orders_branch2,
    CASE WHEN COALESCE(c1.cnt1,0) >= COALESCE(c2.cnt2,0) THEN $1 ELSE $2 END AS branch_more_orders
FROM customer c
JOIN cust1 c1 ON c.cust_id = c1.cust_id
JOIN cust2 c2 ON c.cust_id = c2.cust_id;



--------- WALLET TURNOVER RATE
-- No inputs
SELECT
    c.sex,
    FLOOR(c.salary / 10000) * 10000 AS salary_range,
    AVG(COALESCE(wt.amount,0)) AS avg_turnover
FROM customer c
LEFT JOIN wallet_transaction wt ON wt.cust_id = c.cust_id
GROUP BY c.sex, FLOOR(c.salary / 10000)
ORDER BY c.sex, salary_range;




--------- BNPL AVAILABLE DEBT
-- Inputs: $1 = cust_id, $2 = purchase_amount
WITH owed AS (
    SELECT SUM(op.num * (bps.ret_price * (1 - bps.discount)) * (1 + (COALESCE(p.tax_exem,0)+COALESCE(c.tax_exem,0))/100)) AS total_owed
    FROM orders o
    JOIN order_product op ON op.ord_id = o.ord_id
    JOIN branch_product_supplier bps ON bps.prod_id = op.prod_id
    JOIN product p ON p.prod_id = op.prod_id
    JOIN customer c ON c.cust_id = o.cust_id
    LEFT JOIN refund r ON r.ord_id = op.ord_id AND r.prod_id = op.prod_id
    WHERE o.cust_id = $1
      AND r.ord_id IS NULL
), paid_bnpl AS (
    SELECT COALESCE(SUM(amount),0) AS paid_amount
    FROM bnpl_payment bp
    JOIN bnpl_contract bc ON bc.ord_id = bp.ord_id
    JOIN orders o ON o.ord_id = bp.ord_id
    WHERE o.cust_id = $1
)
SELECT
    w.debt_limit AS bnpl_limit,
    owed.total_owed - paid_bnpl.paid_amount AS current_debt,
    CASE WHEN w.debt_limit >= $2 THEN TRUE ELSE FALSE END AS can_pay
FROM wallet w, owed, paid_bnpl
WHERE w.cust_id = $1;




--------- PRODUCT POPULARITY OF A CATEGORY
-- Inputs: $1 = cat_id
SELECT
    p.p_name,
    AVG(r.score) AS avg_rating
FROM product p
LEFT JOIN review r ON r.prod_id = p.prod_id
WHERE p.cat_id = $1
GROUP BY p.p_name
ORDER BY avg_rating DESC NULLS LAST;



--------- BEST SUPPLIERS
WITH sales AS (
    SELECT bps.sup_id, o.branch_id, SUM(op.num) AS total_sold
    FROM order_product op
    JOIN orders o ON o.ord_id = op.ord_id
    JOIN branch_product_supplier bps ON bps.prod_id = op.prod_id AND bps.branch_id = o.branch_id
    LEFT JOIN refund r ON r.ord_id = op.ord_id AND r.prod_id = op.prod_id
    WHERE r.ord_id IS NULL
    GROUP BY bps.sup_id, o.branch_id
), avg_lead AS (
    SELECT branch_id, AVG(lead_time_days) AS avg_lead_time FROM branch_product_supplier GROUP BY branch_id
)
SELECT s.branch_id, s.sup_id
FROM sales s
JOIN avg_lead a ON a.branch_id = s.branch_id
JOIN branch_product_supplier bps ON bps.sup_id = s.sup_id AND bps.branch_id = s.branch_id
WHERE s.total_sold >= 0.5 * SUM(s.total_sold) OVER(PARTITION BY s.branch_id)
   OR bps.lead_time_days < a.avg_lead_time;



--------- TRUE CUSTOMER VALUE
SELECT
    c.cust_id,
    -- Wallet transactions
    COALESCE(SUM(wt.amount),0)
    +
    -- Standard order payments (excluding refunds)
    COALESCE(SUM(op.num * (bps.ret_price * (1 - bps.discount))),0)
    +
    -- Taxes paid
    COALESCE(SUM(op.num * (bps.ret_price * (1 - bps.discount)) *
          (COALESCE(p.tax_exem,0) + COALESCE(c.tax_exem,0))/100),0)
    +
    -- BNPL payments
    COALESCE(SUM(bp.amount),0)
    -
    -- Value of refunded items
    COALESCE(SUM(op_r.num * (bps_r.ret_price * (1 - bps_r.discount))),0)
    AS true_value
FROM customer c
LEFT JOIN wallet_transaction wt 
       ON wt.cust_id = c.cust_id
LEFT JOIN orders o 
       ON o.cust_id = c.cust_id
LEFT JOIN order_product op 
       ON op.ord_id = o.ord_id
LEFT JOIN branch_product_supplier bps 
       ON bps.prod_id = op.prod_id AND bps.branch_id = o.branch_id
LEFT JOIN product p 
       ON p.prod_id = op.prod_id
-- Refunded items
LEFT JOIN refund r 
       ON r.ord_id = o.ord_id AND r.prod_id = op.prod_id
LEFT JOIN order_product op_r 
       ON op_r.ord_id = r.ord_id AND op_r.prod_id = r.prod_id
LEFT JOIN branch_product_supplier bps_r 
       ON bps_r.prod_id = op_r.prod_id AND bps_r.branch_id = o.branch_id
-- BNPL payments
LEFT JOIN bnpl_payment bp 
       ON bp.ord_id = o.ord_id
GROUP BY c.cust_id;




--------- POSSIBLE ATTRIBUTE VALUES
-- Inputs: $1 = attribute_name, $2 = cat_id, $3 = subcat_name
SELECT DISTINCT other_details ->> $1 AS attr_value
FROM product
WHERE cat_id = $2
  AND subcat_name = $3
  AND other_details ->> $1 IS NOT NULL;