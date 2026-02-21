-- Step 1: Identify which manager is assigned to multiple branches
WITH manager_branches AS (
    SELECT manager_name, branch_name,
           ROW_NUMBER() OVER (PARTITION BY manager_name ORDER BY branch_name) AS rn
    FROM BrPrSu
    GROUP BY manager_name, branch_name
)
-- Step 2: Keep only the first branch per manager, delete the rest
DELETE FROM BrPrSu
USING manager_branches mb
WHERE BrPrSu.manager_name = mb.manager_name
  AND BrPrSu.branch_name = mb.branch_name
  AND mb.rn > 1;