------ Invalid Discount
-- branch_product_supplier
DELETE FROM branch_product_supplier
WHERE discount < 0 OR discount > 100;

-- order_product
DELETE FROM order_product
WHERE discount < 0 OR discount > 100;



------ invalid email
DELETE FROM customer
WHERE NOT (
    email ~* '(?:[a-z0-9!#$%&''*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&''*+/=?^_`{|}~-]+)*|"[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f\\]*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9]))\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])'
);



------ ship before order data
DELETE FROM orders
WHERE send_time < reg_time;


------ Logistic problems
SELECT *
FROM orders
WHERE pack_type = 'Large standard envelop'
  AND send_met IN ('Air (Post)', 'Air (Freight)');


------ Logistic problems
SELECT *
FROM orders
WHERE pack_type IN ('Small box', 'Medium box', 'Large box')
  AND send_met = 'Ground';


------ Manager of more than one branch
SELECT boss_id, COUNT(*) AS branch_count
FROM branch
GROUP BY boss_id
HAVING COUNT(*) > 1;




------ Branch without a manager
SELECT *
FROM branch
WHERE boss_id IS NULL;



------ Customers with no order in any branch
SELECT c.*
FROM customer c
LEFT JOIN orders o ON o.cust_id = c.cust_id
WHERE o.ord_id IS NULL;



------ Incorrect return flow
SELECT r1.*
FROM refund r1
JOIN refund r0
  ON r0.ord_id = r1.ord_id
 AND r0.prod_id = r1.prod_id
WHERE r0.reg_time < r1.reg_time
  AND NOT (
       (r0.ref_status = 'Awaiting refund review'
        AND r1.ref_status IN ('Approved refund', 'Rejected refund'))
  );



------ Incorrect Feedback
  SELECT *
FROM review
WHERE score < 1
   OR score > 5;



------ Too long descriptions
SELECT *
FROM review
WHERE description IS NOT NULL
  AND char_length(description) >= 800;