CREATE OR REPLACE FUNCTION possible_attribute_values(attribute_name TEXT, cat_id_param INT, subcat_name_param TEXT)
RETURNS TABLE (
    attr_value TEXT
)
LANGUAGE sql
AS $$
SELECT DISTINCT other_details ->> attribute_name AS attr_value
FROM product
WHERE cat_id = cat_id_param
  AND subcat_name = subcat_name_param
  AND other_details ->> attribute_name IS NOT NULL;
$$;
SELECT *
FROM possible_attribute_values('camera', 2, 'Mobile Phones');