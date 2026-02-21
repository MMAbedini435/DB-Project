-- 5- Support
CREATE OR REPLACE VIEW support_pending_refunds AS
SELECT
    r.ord_id,
    r.prod_id,
    o.cust_id,
    o.branch_id,
    r.reason,
    r.reg_time,
    r.dec_time,
    r.ref_status
FROM refund r
JOIN orders o ON r.ord_id = o.ord_id
WHERE r.ref_status = 'Awaiting refund review';
SELECT * FROM support_pending_refunds;