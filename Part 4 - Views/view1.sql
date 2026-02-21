-- 1- Warehouse
CREATE OR REPLACE VIEW warehouse_unshipped_items AS
SELECT
    op.prod_id,
    p.p_name,
    SUM(op.num) AS total_quantity,
    COUNT(DISTINCT o.ord_id) AS pending_orders_count
FROM order_product op
JOIN orders o ON op.ord_id = o.ord_id
JOIN product p ON op.prod_id = p.prod_id
WHERE o.proc_stat IN ('Pending Payment', 'Stocking')
GROUP BY op.prod_id, p.p_name;
SELECT * FROM warehouse_unshipped_items;