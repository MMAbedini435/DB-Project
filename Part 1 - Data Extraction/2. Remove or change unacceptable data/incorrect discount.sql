-- Count rows with invalid discount values
SELECT COUNT(*) AS invalid_discount_count
FROM BDB
WHERE Discount < 0 OR Discount > 1;