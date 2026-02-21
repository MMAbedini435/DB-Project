-- 1. branch: add UNIQUE constraint on boss_id
ALTER TABLE branch
    ADD CONSTRAINT uq_branch_boss_id UNIQUE (boss_id);

-- 2. customer: add email regex check
ALTER TABLE customer
ADD CONSTRAINT customer_email_check
CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

-- 3. review: add description length check
ALTER TABLE review
    ADD CONSTRAINT review_description_length_check
        CHECK (char_length(description) < 800);

-- 4. orders: modify proc_stat and pack_type constraints
ALTER TABLE orders
    ALTER COLUMN proc_stat SET NOT NULL;

ALTER TABLE orders
    DROP CONSTRAINT orders_pack_type_check;

ALTER TABLE orders
    ADD CONSTRAINT orders_pack_type_check
        CHECK (
            pack_type IN (
                'Box Small',
                'Box Medium',
                'Box Large',
                'Envelope Small',
                'Envelope Large',
                'Bubble Envelope Small',
                'Bubble Envelope Large'
            )
            AND NOT (pack_type = 'Envelope Large' AND send_met in ('Air (Post)', 'Air (Freight)'))
            AND NOT (pack_type in ('Box Small', 'Box Medium', 'Box Large') AND send_met = 'Ground')
        );

-- 5. orders: modify foreign key on branch_id to ON DELETE SET NULL
ALTER TABLE orders
    DROP CONSTRAINT orders_branch_id_fkey;

ALTER TABLE orders
    ADD CONSTRAINT orders_branch_id_fkey
        FOREIGN KEY (branch_id) REFERENCES branch(branch_id) ON DELETE SET NULL;

-- 6. refund: set ref_status NOT NULL
ALTER TABLE refund
    ALTER COLUMN ref_status SET NOT NULL;

-- 7. wallet: add debt_limit column
ALTER TABLE wallet
    ADD COLUMN debt_limit NUMERIC(12,2) NOT NULL DEFAULT 0;
