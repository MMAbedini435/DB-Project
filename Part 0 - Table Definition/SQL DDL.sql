DROP TABLE IF EXISTS bnpl_payment CASCADE;
DROP TABLE IF EXISTS bnpl_contract CASCADE;
DROP TABLE IF EXISTS wallet_transaction CASCADE;
DROP TABLE IF EXISTS wallet CASCADE;
DROP TABLE IF EXISTS review CASCADE;
DROP TABLE IF EXISTS refund CASCADE;
DROP TABLE IF EXISTS order_product CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS customer CASCADE;
DROP TABLE IF EXISTS branch_product_supplier CASCADE;
DROP TABLE IF EXISTS branch CASCADE;
DROP TABLE IF EXISTS boss CASCADE;
DROP TABLE IF EXISTS supplier CASCADE;
DROP TABLE IF EXISTS product CASCADE;
DROP TABLE IF EXISTS subcategory CASCADE;
DROP TABLE IF EXISTS category CASCADE;

CREATE TABLE category (
    cat_id INTEGER PRIMARY KEY
);

CREATE TABLE subcategory (
    cat_id INTEGER NOT NULL,
    subcat_name VARCHAR(100) NOT NULL,
    PRIMARY KEY (cat_id, subcat_name),
    FOREIGN KEY (cat_id) REFERENCES category (cat_id)
);

CREATE TABLE product (
    prod_id INTEGER PRIMARY KEY,
    cat_id INTEGER NOT NULL,
    subcat_name VARCHAR(100) NOT NULL,
    p_name VARCHAR(200) NOT NULL,
    tax_exem INTEGER CHECK (tax_exem BETWEEN 0 AND 10),
    other_details JSONB,
    FOREIGN KEY (cat_id, subcat_name) REFERENCES subcategory (cat_id, subcat_name)
);

CREATE TABLE supplier (
    sup_id INTEGER PRIMARY KEY,
    name VARCHAR(200) NOT NULL
);

CREATE TABLE boss (
    boss_id INTEGER PRIMARY KEY,
    boss_name VARCHAR(200) NOT NULL
);

CREATE TABLE branch (
    branch_id INTEGER PRIMARY KEY,
    b_name VARCHAR(200) NOT NULL,
    b_address VARCHAR(300),
    b_phone VARCHAR(50),
    boss_id INTEGER NOT NULL,
    FOREIGN KEY (boss_id) REFERENCES boss (boss_id)
);

CREATE TABLE branch_product_supplier (
    branch_id INTEGER NOT NULL,
    prod_id INTEGER NOT NULL,
    sup_id INTEGER NOT NULL,
    supply_num INTEGER NOT NULL CHECK (supply_num > 0),
    lead_time_days INTEGER NOT NULL CHECK (lead_time_days > 0),
    prod_cost NUMERIC(12, 2) NOT NULL,
    discount NUMERIC(5, 2) DEFAULT 0,
    ret_price NUMERIC(12, 2),
    PRIMARY KEY (branch_id, prod_id, sup_id),
    FOREIGN KEY (branch_id) REFERENCES branch (branch_id),
    FOREIGN KEY (prod_id) REFERENCES product (prod_id),
    FOREIGN KEY (sup_id) REFERENCES supplier (sup_id)
);

CREATE TABLE customer (
    cust_id INTEGER PRIMARY KEY,
    cust_name VARCHAR(200) NOT NULL,
    age INTEGER CHECK (age >= 0),
    sex VARCHAR(10),
    cust_phone VARCHAR(50),
    email VARCHAR(200) NOT NULL,
    salary NUMERIC(12, 2),
    relationship VARCHAR(5) CHECK (relationship IN ('NEW', 'LOYAL', 'VIP')),
    tax_exem INTEGER CHECK (tax_exem BETWEEN 0 AND 10),
    subtype VARCHAR(20) CHECK (subtype in ('Consumer', 'Corporate', 'Small Business', 'Home Office'))
);

CREATE TABLE orders (
    ord_id INTEGER NOT NULL,
    pay_met VARCHAR(30) NOT NULL,
    reg_time TIMESTAMPTZ NOT NULL,
    proc_pri VARCHAR(20),
    proc_stat VARCHAR(20),
    branch_id INTEGER NOT NULL,
    cust_id INTEGER NOT NULL,
    rec_addr VARCHAR(300),
    send_type VARCHAR(30) DEFAULT 'Ordinary',
    send_met VARCHAR(30),
    pack_type VARCHAR(30),
    send_cost NUMERIC(12, 2) CHECK (send_cost > 0),
    send_time TIMESTAMPTZ NOT NULL,
    dest_city VARCHAR(100) NOT NULL,
    dest_dist VARCHAR(100) NOT NULL,
    rec_postal VARCHAR(20) NOT NULL,
    PRIMARY KEY (ord_id),
    FOREIGN KEY (branch_id) REFERENCES branch (branch_id),
    FOREIGN KEY (cust_id) REFERENCES customer (cust_id)
);

CREATE TABLE order_product (
    ord_id INTEGER NOT NULL,
    prod_id INTEGER NOT NULL,
    num INTEGER NOT NULL CHECK (num > 0),
    unit_price NUMERIC(12, 2) CHECK (unit_price > 0),
    discount NUMERIC(5, 2) DEFAULT 0,
    production_cost NUMERIC(12, 2) CHECK (production_cost > 0),
    PRIMARY KEY (ord_id, prod_id),
    FOREIGN KEY (ord_id) REFERENCES orders (ord_id),
    FOREIGN KEY (prod_id) REFERENCES product (prod_id)
);

CREATE TABLE refund (
    ord_id INTEGER NOT NULL,
    prod_id INTEGER NOT NULL,
    reason TEXT,
    dec_time TIMESTAMPTZ,
    reg_time TIMESTAMPTZ,
    ref_status VARCHAR(30),
    PRIMARY KEY (ord_id, prod_id),
    FOREIGN KEY (ord_id, prod_id) REFERENCES order_product (ord_id, prod_id)
);

CREATE TABLE review (
    ord_id INTEGER NOT NULL,
    prod_id INTEGER NOT NULL,
    is_public BOOLEAN NOT NULL DEFAULT TRUE,
    score INTEGER,
    description TEXT,
    image_data BYTEA,
    PRIMARY KEY (ord_id, prod_id),
    FOREIGN KEY (ord_id) REFERENCES orders (ord_id),
    FOREIGN KEY (prod_id) REFERENCES product (prod_id)
);

CREATE TABLE wallet (
    cust_id INTEGER PRIMARY KEY,
    balance NUMERIC(12, 2) NOT NULL DEFAULT 0,
    FOREIGN KEY (cust_id) REFERENCES customer (cust_id)
);

CREATE TABLE wallet_transaction (
    cust_id INTEGER NOT NULL,
    tran_id INTEGER NOT NULL,
    tran_date TIMESTAMPTZ NOT NULL,
    sub_type VARCHAR(20) NOT NULL,
    amount NUMERIC(12, 2),
    ord_id INTEGER,
    PRIMARY KEY (tran_id),
    FOREIGN KEY (cust_id) REFERENCES customer (cust_id),
    FOREIGN KEY (ord_id) REFERENCES orders (ord_id)
);

CREATE TABLE bnpl_contract (
    ord_id INTEGER PRIMARY KEY,
    reg_date TIMESTAMPTZ NOT NULL,
    FOREIGN KEY (ord_id) REFERENCES orders (ord_id)
);

CREATE TABLE bnpl_payment (
    ord_id INTEGER NOT NULL,
    pay_date TIMESTAMPTZ NOT NULL,
    amount NUMERIC(12, 2) NOT NULL,
    pay_met VARCHAR(30) NOT NULL,
    PRIMARY KEY (ord_id, pay_date),
    FOREIGN KEY (ord_id) REFERENCES bnpl_contract (ord_id)
);