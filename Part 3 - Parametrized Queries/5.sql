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