DROP FUNCTION IF EXISTS products_by_category;

CREATE OR REPLACE FUNCTION products_by_category(v_city VARCHAR(50), v_category VARCHAR(500))
RETURNS TABLE (productid INT, productname VARCHAR(500),
               vendorid INT, vendorname VARCHAR(500),
               price NUMERIC(13,2), quantity INT) AS
$BODY$

WITH RECURSIVE cte_cat AS
(
    SELECT id FROM select_categories(v_category)
),
cte_prodid AS 
(
    SELECT pc.productid 
    FROM logistics.productcategory as pc
    INNER JOIN cte_cat 
    ON pc.categoryid = cte_cat.id
)
,
cte_qty AS 
(
    SELECT pb.vendorid, pb.productid, SUM(pb.productcount) AS qty
    FROM logistics.city as c 
    INNER JOIN logistics.warehouse as w
        ON w.cityid = c.id AND c.name = v_city   
    INNER JOIN logistics.warehousebin as wb 
        ON wb.warehouseid = w.id
    INNER JOIN logistics.productbin as pb 
        ON pb.binid = wb.id 
    INNER JOIN cte_prodid ON pb.productid = cte_prodid.productid 
    GROUP BY pb.productid, pb.vendorid
    ORDER BY pb.productid, pb.vendorid             
)
, 
cte_cost AS
(
    SELECT pc.productid, pc.vendorid, pc.unitcost, pc.fromdate, 
           rank() OVER (ORDER BY pc.fromdate DESC) AS rnk
    FROM logistics.productcost as pc 
    INNER JOIN cte_qty 
    ON cte_qty.vendorid = pc.vendorid 
    AND cte_qty.productid = pc.productid 
    AND pc.fromdate <= NOW()::date
)
SELECT p.id AS productid, p.name AS productname, v.id AS vendorid, v.name AS vendorname, 
       cte_cost.unitcost AS price, cte_qty.qty AS quantity
FROM cte_qty 
INNER JOIN cte_cost 
    ON cte_qty.vendorid = cte_cost.vendorid 
    AND cte_qty.productid = cte_cost.productid
    AND cte_cost.rnk = 1
INNER JOIN logistics.product AS p
    ON p.id = cte_qty.productid
INNER JOIN logistics.vendor as v 
    ON v.id = cte_qty.vendorid 
ORDER BY p.name, v.name;    

$BODY$
LANGUAGE sql;

SELECT * FROM products_by_category('Москва', 'Одежда для девочек') AS t1;


