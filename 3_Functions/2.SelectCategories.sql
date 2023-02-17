DROP FUNCTION IF EXISTS select_categories;

CREATE OR REPLACE FUNCTION select_categories(v_category VARCHAR(50))
RETURNS TABLE (id INT, parentid INT, fullname VARCHAR(500)) AS 
$BODY$

WITH RECURSIVE cte_cat AS
(
    SELECT c.id, c.parentid, c.fullname
    FROM logistics.category AS c 
    WHERE c.name = v_category
    UNION ALL 
    SELECT c1.id, c1.parentid, c1.fullname
    FROM logistics.category AS c1
    INNER JOIN cte_cat AS c2
    ON c1.parentid = c2.id
)
SELECT * FROM cte_cat; 

$BODY$
LANGUAGE sql;

SELECT * FROM select_categories('Одежда для девочек') AS t1;


