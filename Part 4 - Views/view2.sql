-- 2- Accounting
DROP MATERIALIZED VIEW IF EXISTS accounting_daily_sales;
CREATE MATERIALIZED VIEW accounting_daily_sales AS
SELECT
    DATE(o.reg_time) AS order_date,
    SUM(op.num * op.unit_price) AS total_sales,
    SUM(op.num * (op.unit_price - op.production_cost)) AS total_profit
FROM orders o
JOIN order_product op ON o.ord_id = op.ord_id
GROUP BY DATE(o.reg_time)
ORDER BY DATE(o.reg_time);
SELECT * FROM accounting_daily_sales;
