---------- orders.reg_time = CURRENT_TIMESTAMP

-- Trigger function
CREATE OR REPLACE FUNCTION trg_orders_set_regtime()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.reg_time <> CURRENT_TIMESTAMP THEN
        RAISE EXCEPTION 'Order reg_time must be CURRENT_TIMESTAMP';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach trigger to orders
CREATE TRIGGER trg_orders_regtime
BEFORE INSERT ON orders
FOR EACH ROW
EXECUTE FUNCTION trg_orders_set_regtime();





---------- Order Status transition validation

CREATE OR REPLACE FUNCTION trg_orders_proc_stat_fsm()
RETURNS TRIGGER AS $$
DECLARE
    valid_transitions CONSTANT jsonb := '{
        "Product Securing": ["Awaiting Payment"],
        "Awaiting Payment": ["Shipped"],
        "Shipped": ["Received"],
        "Received": []
    }'::jsonb;
BEGIN
    -- Allow no change on initial insert
    IF TG_OP = 'UPDATE' THEN
        IF NEW.proc_stat IS DISTINCT FROM OLD.proc_stat THEN
            -- Check if transition is valid
            IF NOT (OLD.proc_stat IS NULL AND NEW.proc_stat IS NOT NULL) AND
               NOT (NEW.proc_stat = ANY (SELECT jsonb_array_elements_text(valid_transitions -> OLD.proc_stat))) THEN
                RAISE EXCEPTION 'Invalid proc_stat transition from % to %', OLD.proc_stat, NEW.proc_stat;
            END IF;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach trigger
CREATE TRIGGER trg_orders_proc_stat
BEFORE UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION trg_orders_proc_stat_fsm();





---------- Low-Income Small Business Customers

CREATE OR REPLACE FUNCTION trg_orders_priority_logic()
RETURNS TRIGGER AS $$
DECLARE
    cust_subtype TEXT;
    cust_salary NUMERIC;
BEGIN
    -- Fetch customer info
    SELECT subtype, salary INTO cust_subtype, cust_salary
    FROM customer
    WHERE cust_id = NEW.cust_id;

    -- Reject CRITICAL for low-income small business customers
    IF cust_subtype = 'Sales representative' AND cust_salary < 5000 AND NEW.proc_pri = 'CRITICAL' THEN
        RAISE EXCEPTION 'Cannot assign CRITICAL priority to low-income Sales representative';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach trigger
CREATE TRIGGER trg_orders_priority
BEFORE INSERT OR UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION trg_orders_priority_logic();




---------- Wallet Transaction Debt Limit
CREATE OR REPLACE FUNCTION trg_wallet_transaction_limit()
RETURNS TRIGGER AS $$
DECLARE
    current_balance NUMERIC;
    new_balance NUMERIC;
BEGIN
    -- Get current balance
    SELECT balance INTO current_balance
    FROM wallet
    WHERE cust_id = NEW.cust_id;

    -- Compute new balance
    IF NEW.sub_type = 'Deposit' THEN
        new_balance := current_balance + NEW.amount;
    ELSIF NEW.sub_type = 'Withdrawal' THEN
        new_balance := current_balance - NEW.amount;
        IF new_balance < - (SELECT debt_limit FROM wallet WHERE cust_id = NEW.cust_id) THEN
            RAISE EXCEPTION 'Withdrawal would exceed customer debt limit';
        END IF;
    ELSE
        RAISE EXCEPTION 'Invalid wallet_transaction sub_type: %', NEW.sub_type;
    END IF;

    -- Update wallet balance
    UPDATE wallet
    SET balance = new_balance
    WHERE cust_id = NEW.cust_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach trigger
CREATE TRIGGER trg_wallet_transaction
BEFORE INSERT ON wallet_transaction
FOR EACH ROW
EXECUTE FUNCTION trg_wallet_transaction_limit();




---------- ensure customers can only review ordered products

CREATE OR REPLACE FUNCTION trg_review_customer_purchased()
RETURNS TRIGGER AS $$
DECLARE
    purchase_exists BOOLEAN;
BEGIN
    -- Check if the customer has purchased the product at least once
    SELECT EXISTS (
        SELECT 1
        FROM orders o
        JOIN order_product op ON o.ord_id = op.ord_id
        WHERE o.cust_id = NEW.cust_id
          AND op.prod_id = NEW.prod_id
    ) INTO purchase_exists;

    -- Raise exception if no purchase exists
    IF NOT purchase_exists THEN
        RAISE EXCEPTION 'Customer % cannot review product % because they have not purchased it',
            NEW.cust_id, NEW.prod_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;




---------- limit customer orders from a branch to 5 per month

CREATE OR REPLACE FUNCTION trg_orders_limit_per_customer_branch()
RETURNS TRIGGER AS $$
DECLARE
    active_orders_count INTEGER;
BEGIN
    -- Count active orders for the same customer in the same branch
    SELECT COUNT(*)
    INTO active_orders_count
    FROM orders
    WHERE cust_id = NEW.cust_id
      AND branch_id = NEW.branch_id
      AND proc_stat <> 'Received';

    -- Raise exception if the limit is reached
    IF active_orders_count >= 5 THEN
        RAISE EXCEPTION 'Customer % already has % active orders in branch %; limit of 5 exceeded',
            NEW.cust_id, active_orders_count, NEW.branch_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;