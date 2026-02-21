-- Fix Box types shipped via 'Ground'
UPDATE BDB
SET Ship_Mode = 'Air (Post)'
WHERE Packaging IN ('Box Small', 'Box Medium', 'Box Large') 
  AND Ship_Mode = 'Ground';

-- Fix Envelope Large shipped via Air methods
UPDATE BDB
SET Ship_Mode = 'Ground'
WHERE Packaging = 'Envelope Large' 
  AND Ship_Mode IN ('Air (Post)', 'Air (Freight)');