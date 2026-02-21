-- Delete rows with invalid discount values
DELETE FROM BDB
WHERE Discount < 0 OR Discount > 1;