-- 3- Branch bosses
CREATE OR REPLACE VIEW branch_customers AS
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
SELECT * FROM branch_customers;