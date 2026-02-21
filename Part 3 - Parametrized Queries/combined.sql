CREATE OR REPLACE FUNCTION average_profit_margin(cat_id_param INT)
RETURNS TABLE (
    subcat_name TEXT,
    avg_profit_per_item NUMERIC
)
LANGUAGE sql
AS $$
SELECT
    p.subcat_name,
    SUM((bps.ret_price * (1 - bps.discount / 100) - bps.prod_cost) * op.num) / SUM(op.num) AS avg_profit_per_item
FROM product p
JOIN subcategory s ON p.cat_id = s.cat_id AND p.subcat_name = s.subcat_name
JOIN order_product op ON op.prod_id = p.prod_id
JOIN orders o ON o.ord_id = op.ord_id
JOIN branch_product_supplier bps ON bps.prod_id = p.prod_id
LEFT JOIN refund r ON r.ord_id = op.ord_id AND r.prod_id = op.prod_id
WHERE p.cat_id = cat_id_param
  AND r.ord_id IS NULL
GROUP BY p.subcat_name;
$$;
EXPLAIN ANALYSE
SELECT * FROM average_profit_margin(1);
-- =================

CREATE OR REPLACE FUNCTION product_popularity_of_category(cat_id_param INT)
RETURNS TABLE (
    p_name TEXT,
    avg_rating NUMERIC
)
LANGUAGE sql
AS $$
SELECT
    p.p_name,
    AVG(r.score) AS avg_rating
FROM product p
LEFT JOIN review r ON r.prod_id = p.prod_id
WHERE p.cat_id = cat_id_param
GROUP BY p.p_name
ORDER BY avg_rating DESC NULLS LAST;
$$;
SELECT *
FROM product_popularity_of_category(1);
-- =================

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
-- =================

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
    COALESCE(SUM(op.num * (bps.ret_price * (1 - bps.discount / 100))),0)
    +
    COALESCE(SUM(op.num * (bps.ret_price * (1 - bps.discount / 100)) *
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
-- =================

CREATE OR REPLACE FUNCTION possible_attribute_values(attribute_name TEXT, cat_id_param INT, subcat_name_param TEXT)
RETURNS TABLE (
    attr_value TEXT
)
LANGUAGE sql
AS $$
SELECT DISTINCT other_details ->> attribute_name AS attr_value
FROM product
WHERE cat_id = cat_id_param
  AND subcat_name = subcat_name_param
  AND other_details ->> attribute_name IS NOT NULL;
$$;
SELECT *
FROM possible_attribute_values('camera', 2, 'Mobile Phones');
-- =================

-- 2
CREATE OR REPLACE FUNCTION favorite_products(start_date TIMESTAMP, end_date TIMESTAMP)
RETURNS TABLE (
    p_name TEXT,
    avg_rating NUMERIC
)
LANGUAGE sql
AS $$
SELECT
    p.p_name,
    AVG(r.score) AS avg_rating
FROM orders o
JOIN order_product op ON op.ord_id = o.ord_id
JOIN product p ON p.prod_id = op.prod_id
LEFT JOIN review r ON r.ord_id = o.ord_id AND r.prod_id = p.prod_id
WHERE o.reg_time BETWEEN start_date AND end_date
GROUP BY p.p_name
ORDER BY avg_rating DESC NULLS LAST;
$$;

SELECT * FROM favorite_products('2024-01-01', '2024-12-31');
-- =================

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
-- =================

-- ۴
CREATE OR REPLACE FUNCTION product_dependencies(subcat_name_param TEXT, support_threshold INT)
RETURNS TABLE (
    correlated_type TEXT,
    support_count BIGINT
)
LANGUAGE sql
AS $$
SELECT
    DISTINCT p2.subcat_name AS correlated_type,
    COUNT(DISTINCT op.ord_id) AS support_count
FROM order_product op
JOIN product p1 ON p1.prod_id = op.prod_id
JOIN order_product op2 ON op2.ord_id = op.ord_id
JOIN product p2 ON p2.prod_id = op2.prod_id
WHERE p1.subcat_name = subcat_name_param
  AND p2.subcat_name <> subcat_name_param
GROUP BY p2.subcat_name
HAVING COUNT(DISTINCT op.ord_id) >= support_threshold;
$$;
SELECT *
FROM product_dependencies('Laptops', 5);
-- =================

-- 5
CREATE OR REPLACE FUNCTION delayed_products()
RETURNS TABLE (
    ord_id INT
)
LANGUAGE sql
AS $$
SELECT o.ord_id
FROM orders o
WHERE (o.send_type = 'Same-Day' AND DATE(o.send_time) <> DATE(o.reg_time))
   OR (o.send_type = 'Normal' AND o.send_time > o.reg_time + INTERVAL '2 days');
$$;
SELECT *
FROM delayed_products();
-- =================

CREATE OR REPLACE FUNCTION payed_taxes_for_customer(cust_id_param INT)
RETURNS TABLE (
    total_taxes NUMERIC
)
LANGUAGE sql
AS $$
SELECT SUM(
    op.num * (bps.ret_price * (1 - bps.discount / 100)) *
    (COALESCE(p.tax_exem, 0) + COALESCE(c.tax_exem, 0)) / 100
) AS total_taxes
FROM orders o
JOIN order_product op ON op.ord_id = o.ord_id
JOIN branch_product_supplier bps ON bps.prod_id = op.prod_id
JOIN product p ON p.prod_id = op.prod_id
JOIN customer c ON c.cust_id = o.cust_id
LEFT JOIN refund r ON r.ord_id = op.ord_id AND r.prod_id = op.prod_id
WHERE o.cust_id = cust_id_param
  AND r.ord_id IS NULL;
$$;
SELECT *
FROM payed_taxes_for_customer(10);
-- =================

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

-- =================

CREATE OR REPLACE FUNCTION wallet_turnover_rate()
RETURNS TABLE (
    sex TEXT,
    salary_range NUMERIC,
    avg_turnover NUMERIC
)
LANGUAGE sql
AS $$
SELECT
    c.sex,
    FLOOR(c.salary / 10000) * 10000 AS salary_range,
    AVG(COALESCE(wt.amount,0)) AS avg_turnover
FROM customer c
LEFT JOIN wallet_transaction wt ON wt.cust_id = c.cust_id
GROUP BY c.sex, FLOOR(c.salary / 10000)
ORDER BY c.sex, salary_range;
$$;
SELECT *
FROM wallet_turnover_rate();
-- =================

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
FROM bnpl_available_debt(15, 500);
-- =================