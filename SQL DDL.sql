-- 1. Product catalog
CREATE TABLE
    category (cat_id INTEGER PRIMARY KEY);

CREATE TABLE
    subcategory (
        cat_id INTEGER NOT NULL,
        subcat_name VARCHAR(100) NOT NULL,
        PRIMARY KEY (cat_id, subcat_name),
        FOREIGN KEY (cat_id) REFERENCES category (cat_id)
    );

CREATE TABLE
    product (
        prod_id INTEGER PRIMARY KEY,
        cat_id INTEGER NOT NULL,
        subcat_name VARCHAR(100) NOT NULL,
        p_name VARCHAR(200) NOT NULL,
        tax_exem INTEGER CHECK (tax_exem BETWEEN 0 AND 10),
        other_details JSON,
        FOREIGN KEY (cat_id, subcat_name) REFERENCES subcategory (cat_id, subcat_name)
    );

CREATE TABLE
    supplier (
        sup_id INTEGER PRIMARY KEY,
        name VARCHAR(200) NOT NULL
    );

-- 2. Organization (bosses, branches, supply relations)
CREATE TABLE
    boss (
        boss_id INTEGER PRIMARY KEY,
        boss_name VARCHAR(200) NOT NULL
    );

CREATE TABLE
    branch (
        branch_id INTEGER PRIMARY KEY,
        b_name VARCHAR(200) NOT NULL,
        b_address VARCHAR(300),
        b_phone VARCHAR(50),
        boss_id INTEGER NOT NULL,
        FOREIGN KEY (boss_id) REFERENCES boss (boss_id)
    );

CREATE TABLE
    branch_product_supplier (
        branch_id INTEGER NOT NULL,
        prod_id INTEGER NOT NULL,
        sup_id INTEGER NOT NULL,
        supply_num INTEGER NOT NULL CHECK (supply_num > 0),
        lead_time_days INTEGER NOT NULL CHECK (lead_time_days > 0),
        fin_price NUMERIC(12, 2) NOT NULL,
        discount INTEGER NOT NULL CHECK (discount BETWEEN 0 AND 100) DEFAULT 0,
        ret_price NUMERIC(12, 2),
        PRIMARY KEY (branch_id, prod_id, sup_id),
        FOREIGN KEY (branch_id) REFERENCES branch (branch_id),
        FOREIGN KEY (prod_id) REFERENCES product (prod_id),
        FOREIGN KEY (sup_id) REFERENCES supplier (sup_id)
    );

-- 3. Customers and reviews
CREATE TABLE
    customer (
        cust_id INTEGER PRIMARY KEY,
        cust_name VARCHAR(200) NOT NULL,
        age INTEGER CHECK (age >= 0),
        sex CHAR(1),
        cust_phone VARCHAR(50),
        email VARCHAR(200),
        salary NUMERIC(12, 2),
        relationship VARCHAR(5) CHECK (relationship IN ('NEW', 'LOYAL', 'VIP')),
        tax_exem INTEGER CHECK (tax_exem BETWEEN 0 AND 10),
        subtype VARCHAR(20) CHECK (subtype IN ('Sales representative', 'Consumer'))
    );

CREATE TABLE
    review (
        ord_id INTEGER NOT NULL,
        prod_id INTEGER NOT NULL,
        is_public BOOLEAN NOT NULL DEFAULT TRUE,
        score INTEGER NOT NULL CHECK (score BETWEEN 1 AND 5),
        description TEXT,
        image_data BYTEA,
        PRIMARY KEY (ord_id, prod_id),
        FOREIGN KEY (ord_id) REFERENCES order (ord_id),
        FOREIGN KEY (prod_id) REFERENCES product (prod_id)
    );

-- 4. Orders and related tables
CREATE TABLE
    orders (
        ord_id INTEGER NOT NULL,
        pay_met VARCHAR(11) NOT NULL CHECK (
            pay_met IN (
                'Credit Card',
                'Debit Card',
                'Cash',
                'Wallet',
                'BNPL'
            )
        ),
        reg_time TIMESTAMPTZ NOT NULL,
        proc_pri VARCHAR(8) CHECK (
            proc_pri IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT', 'CRITICAL')
        ),
        proc_stat VARCHAR(16) CHECK (
            proc_stat IN (
                'Awaiting Payment',
                'Product Securing',
                'Shipped',
                'Received',
                'Unknown'
            )
        ),
        branch_id INTEGER NOT NULL,
        cust_id INTEGER NOT NULL,
        rec_addr VARCHAR(300),
        send_type VARCHAR(17) DEFAULT 'Normal' CHECK (
            send_type IN ('Normal', 'Special', 'Same day delivery')
        ),
        send_met VARCHAR(15) CHECK (
            send_met IN ('Ground shipping', 'Airmail', 'Air freight')
        ),
        pack_type VARCHAR(22) CHECK (
            pack_type IN (
                'Small box',
                'Medium box',
                'Large box',
                'Small standard envelop',
                'Large standard envelop',
                'Small bubble mailer',
                'Large bubble mailer'
            )
        ),
        send_cost NUMERIC(12,2) CHECK (send_cost > 0),
        send_time TIMESTAMPTZ NOT NULL CHECK (send_time >= reg_time),
        dest_city VARCHAR(100) NOT NULL,
        dest_dist VARCHAR(100) NOT NULL,
        rec_postal VARCHAR(20) NOT NULL,
        PRIMARY KEY (ord_id),
        FOREIGN KEY (branch_id) REFERENCES branch (branch_id),
        FOREIGN KEY (cust_id) REFERENCES customer (cust_id)
    );

CREATE TABLE
    order_product (
        ord_id INTEGER NOT NULL,
        prod_id INTEGER NOT NULL,
        num INTEGER NOT NULL CHECK (num > 0),
        PRIMARY KEY (ord_id, prod_id),
        FOREIGN KEY (ord_id) REFERENCES orders (ord_id),
        FOREIGN KEY (prod_id) REFERENCES product (prod_id)
    );

CREATE TABLE
    refund (
        ord_id INTEGER NOT NULL,
        prod_id INTEGER NOT NULL,
        reason TEXT,
        dec_time TIMESTAMPTZ,
        reg_time TIMESTAMPTZ,
        ref_status VARCHAR(22) CHECK (
            ref_status IN (
                'Awaiting refund review',
                'Approved refund',
                'Rejected refund'
            )
        ),
        PRIMARY KEY (ord_id, prod_id),
        FOREIGN KEY (ord_id) REFERENCES orders (ord_id),
        FOREIGN KEY (prod_id) REFERENCES product (prod_id),
        FOREIGN KEY (ord_id, prod_id) REFERENCES order_product (ord_id, prod_id)
    );

-- 5. Wallet and transactions
CREATE TABLE
    wallet (
        cust_id INTEGER PRIMARY KEY,
        balance NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (balance >= 0),
        FOREIGN KEY (cust_id) REFERENCES customer (cust_id)
    );

CREATE TABLE
    wallet_transaction (
        cust_id INTEGER NOT NULL,
        tran_id INTEGER PRIMARY KEY,
        tran_date TIMESTAMPTZ NOT NULL,
        sub_type VARCHAR(10) NOT NULL CHECK (sub_type IN ('Deposit', 'Withdrawal')),
        amount NUMERIC(12,2),
        ord_id INTEGER,
        PRIMARY KEY (tran_id),
        FOREIGN KEY (cust_id) REFERENCES customer (cust_id),
        FOREIGN KEY (ord_id) REFERENCES Orders (ord_id)
    );

-- 6. BNPL (Buy Now Pay Later)
CREATE TABLE
    bnpl_contract (
        ord_id INTEGER PRIMARY KEY,
        reg_date TIMESTAMPTZ NOT NULL,
        FOREIGN KEY (ord_id) REFERENCES orders (ord_id)
    );

CREATE TABLE
    bnpl_payment (
        ord_id INTEGER NOT NULL,
        pay_date TIMESTAMPTZ NOT NULL,
        amount NUMERIC(12,2) NOT NULL,
        pay_met VARCHAR(11) NOT NULL CHECK (
            pay_met IN ('Credit Card', 'Debit Card', 'Cash', 'Wallet')
        ),
        PRIMARY KEY (ord_id, pay_date),
        FOREIGN KEY (ord_id) REFERENCES bnpl_contract (ord_id)
    );