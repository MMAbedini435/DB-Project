-- Delete rows where shipping date is earlier than order date
DELETE FROM BDB
WHERE Ship_Date < Order_Date;