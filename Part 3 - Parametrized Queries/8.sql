CREATE OR REPLACE FUNCTION wallet_turnover_rate()
RETURNS TABLE (
    sex TEXT,
    salary_range NUMERIC,
    avg_turnover NUMERIC
)
LANGUAGE sql
AS $$
SELECT
    c.sex,
    FLOOR(c.salary / 10000) * 10000 AS salary_range,
    AVG(COALESCE(wt.amount,0)) AS avg_turnover
FROM customer c
LEFT JOIN wallet_transaction wt ON wt.cust_id = c.cust_id
GROUP BY c.sex, FLOOR(c.salary / 10000)
ORDER BY c.sex, salary_range;
$$;
SELECT *
FROM wallet_turnover_rate();