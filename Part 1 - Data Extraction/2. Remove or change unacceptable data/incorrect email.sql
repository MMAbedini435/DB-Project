-- Remove rows with invalid emails
DELETE FROM BDB
WHERE Email !~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$';