
-- new column category name
ALTER TABLE category
ADD COLUMN cat_name VARCHAR(100);

INSERT INTO category (cat_id, cat_name)
SELECT 
    -- generated cat_id 
    ROW_NUMBER() OVER (ORDER BY product_category) AS cat_id,
    product_category
FROM (
    SELECT DISTINCT product_category
    FROM BDB
) t;

INSERT INTO subcategory (cat_id, subcat_name)
SELECT DISTINCT
    c.cat_id,
    b.Product_Sub_Category
FROM BDB b
JOIN category c 
    ON c.cat_name = b.product_category;

-- Supplier
ALTER TABLE supplier
ADD COLUMN phone VARCHAR(21) NOT NULL,
ADD COLUMN address VARCHAR(57) NOT NULL;

INSERT INTO supplier (sup_id, name, phone, address)
SELECT
    ROW_NUMBER() OVER (ORDER BY supplier_name) AS sup_id,
    supplier_name,
    supplier_phone,
    supplier_address
FROM (
    SELECT DISTINCT
        supplier_name,
        supplier_phone,
        supplier_address
    FROM BrPrSu
) s;

-- Product
INSERT INTO product (
    prod_id,
    cat_id,
    subcat_name,
    p_name,
    tax_exem,
    other_details
)
SELECT
    ROW_NUMBER() OVER (ORDER BY pp.product_name) AS prod_id,
    c.cat_id,
    pp.sub_category,
    pp.product_name,
    FLOOR(RANDOM() * 11)::int AS tax_exem,  -- 0–10 random number
    to_json(pp.attributes) AS other_details
FROM ProductProperties pp
JOIN category c
    ON c.cat_name = pp.category;

-- Boss and Branch
INSERT INTO boss (boss_id, boss_name)
SELECT
    ROW_NUMBER() OVER (ORDER BY manager_name) AS boss_id,
    manager_name
FROM (
    SELECT DISTINCT manager_name
    FROM BrPrSu
) m;
INSERT INTO branch (
    branch_id,
    b_name,
    b_address,
    b_phone,
    boss_id
)
SELECT
    ROW_NUMBER() OVER (ORDER BY b.branch_name) AS branch_id,
    b.branch_name,
    b.address,
    b.phone,
    bo.boss_id
FROM (
    SELECT DISTINCT
        branch_name,
        address,
        phone,
        manager_name
    FROM BrPrSu
) b
JOIN boss bo
    ON bo.boss_name = b.manager_name;

-- Branch-Product-Supplier
INSERT INTO branch_product_supplier (
    branch_id,
    prod_id,
    sup_id,
    supply_num,
    lead_time_days,
    prod_cost,
    discount,
    ret_price
)
SELECT
    br.branch_id,
    p.prod_id,
    s.sup_id,
    (FLOOR(RANDOM() * 100) + 1)::int AS supply_num,         -- random > 0
    b.lead_time_days,
    (b.supply_price * (0.8 + RANDOM() * 0.15))::numeric(12,2) AS prod_cost, -- slightly smaller
    FLOOR(RANDOM() * 101)::int AS discount,                 -- 0–100%
    b.supply_price AS ret_price
FROM BrPrSu b
JOIN branch br
    ON br.b_name = b.branch_name
JOIN product p
    ON p.p_name = b.product_name
       AND p.subcat_name = b.sub_category
JOIN supplier s
    ON s.name = b.supplier_name;

-- Customer
INSERT INTO customer (
    cust_id,
    cust_name,
    age,
    sex,
    cust_phone,
    email,
    salary,
    relationship,
    tax_exem,
    subtype
)
SELECT
    ROW_NUMBER() OVER (ORDER BY Customer_Name) AS cust_id,
    Customer_Name,
    Customer_Age,
    CASE
        WHEN Gender ILIKE 'male' THEN 'M'
        WHEN Gender ILIKE 'female' THEN 'F'
        ELSE NULL
    END AS sex,
    Phone,
    Email,
    Income,
    (ARRAY['NEW','LOYAL','VIP'])[FLOOR(RANDOM() * 3 + 1)::int] AS relationship,
    FLOOR(RANDOM() * 11)::int AS tax_exem,
    Customer_Segment AS subtype
FROM (
    SELECT DISTINCT
        Customer_Name,
        Customer_Age,
        Gender,
        Phone,
        Email,
        Income,
        Customer_Segment
    FROM BDB
) c;


-- Orders
INSERT INTO orders (
    ord_id,
    pay_met,
    reg_time,
    proc_pri,
    proc_stat,
    branch_id,
    cust_id,
    rec_addr,
    send_type,
    send_met,
    pack_type,
    send_cost,
    send_time,
    dest_city,
    dest_dist,
    rec_postal
)
SELECT DISTINCT
    b.Order_ID AS ord_id,
    b.Payment_Method AS pay_met,
    b.Order_Date AS reg_time,
    b.Order_Priority AS proc_pri,
    b.Order_Status AS proc_stat,
    -- pick random branch_id
    (SELECT branch_id FROM branch ORDER BY RANDOM() LIMIT 1) AS branch_id,
    c.cust_id AS cust_id,
    b.Shipping_Address AS rec_addr,
    b.Shipping_Method AS send_type,
    b.Ship_Mode AS send_met,
    b.Packaging AS pack_type,
    b.Shipping_Cost AS send_cost,
    b.Ship_Date AS send_time,
    b.City AS dest_city,
    b.Region AS dest_dist,
    b.Zip_Code AS rec_postal
FROM BDB b
JOIN customer c
    ON c.email = b.Email; -- email id

-- Order/Product
INSERT INTO order_product (ord_id, prod_id, num)
SELECT DISTINCT 
    b.Order_ID, 
    p.prod_id, 
    b.Order_Quantity
FROM 
    BDB b
JOIN 
    product p ON b.Product_Name = p.Product_Name

-- Review
INSERT INTO review (ord_id, prod_id, is_public, score, description, image_data)
SELECT DISTINCT 
    b.Order_ID, 
    p.prod_id, 
    (RANDOM() > 0.5) AS is_public,     -- Generate a random bool
    b.Ratings AS score, 
    r.Comment AS description, 
    r.Image::BYTEA AS image_data 
FROM 
    BDB b
JOIN 
    product p ON b.Product_Name = p.product_name 
-- left join Reviews so we still get ratings even if there is no written comment
LEFT JOIN 
    Reviews r ON b.Order_ID = r.Order_ID AND b.Product_Name = r.Product_Name
WHERE 
    -- ensure we only create a review row if there's actually a rating or comment to migrate
    b.Ratings IS NOT NULL OR r.Comment IS NOT NULL 


-- refund
-- TODO

-- Wallet
INSERT INTO wallet (cust_id, balance)
SELECT
    c.cust_id,
    w.wallet_balance::NUMERIC(12,2)
FROM Wallet w
JOIN customer c
    ON c.email = w.customer_email;

