-- 1. branch: add UNIQUE constraint on boss_id
ALTER TABLE branch
    ADD CONSTRAINT uq_branch_boss_id UNIQUE (boss_id);

-- 2. branch_product_supplier: modify discount check from 0-100 to 0-1
ALTER TABLE branch_product_supplier
    DROP CONSTRAINT branch_product_supplier_discount_check;

ALTER TABLE branch_product_supplier
    ADD CONSTRAINT branch_product_supplier_discount_check
        CHECK (discount BETWEEN 0 AND 1);

-- 3. customer: add email regex check
ALTER TABLE customer
    DROP CONSTRAINT customer_email_check;  -- if it exists

ALTER TABLE customer
    ADD CONSTRAINT customer_email_check
    CHECK (email ~* 
    '(?:[a-z0-9!#$%&''*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&''*+/=?^_`{|}~-]+)*|"[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f\\]*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9]))\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\]))');

-- 4. review: add description length check
ALTER TABLE review
    ADD CONSTRAINT review_description_length_check
        CHECK (char_length(description) < 800);

-- 5. orders: modify proc_stat and pack_type constraints
ALTER TABLE orders
    ALTER COLUMN proc_stat SET NOT NULL;

ALTER TABLE orders
    DROP CONSTRAINT orders_pack_type_check;

ALTER TABLE orders
    ADD CONSTRAINT orders_pack_type_check
        CHECK (
            pack_type IN (
                'Small box',
                'Medium box',
                'Large box',
                'Small standard envelop',
                'Large standard envelop',
                'Small bubble mailer',
                'Large bubble mailer'
            )
            AND NOT (pack_type = 'Large standard envelop' AND send_met in ('Airmail', 'Air freight'))
            AND NOT (pack_type in ('Small box', 'Medium box', 'Large box') AND send_met = 'Ground shipping')
        );

-- 6. orders: modify foreign key on branch_id to ON DELETE SET NULL
ALTER TABLE orders
    DROP CONSTRAINT orders_branch_id_fkey;

ALTER TABLE orders
    ADD CONSTRAINT orders_branch_id_fkey
        FOREIGN KEY (branch_id) REFERENCES branch(branch_id) ON DELETE SET NULL;

-- 7. refund: set ref_status NOT NULL
ALTER TABLE refund
    ALTER COLUMN ref_status SET NOT NULL;

-- 8. wallet: add debt_limit column
ALTER TABLE wallet
    ADD COLUMN debt_limit NUMERIC(12,2) NOT NULL DEFAULT 0;
