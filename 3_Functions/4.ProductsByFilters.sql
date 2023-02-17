DROP FUNCTION IF EXISTS calc_product_fields_filter;
DROP FUNCTION IF EXISTS calc_cte_prod_cost_qty;
DROP FUNCTION IF EXISTS create_query_products_by_filters;
DROP FUNCTION IF EXISTS get_products_by_filters;

CREATE OR REPLACE 
FUNCTION calc_product_fields_filter( 
    v_producttype VARCHAR(20), v_season VARCHAR(20), 
    v_size VARCHAR(8), v_color VARCHAR(20))
RETURNS VARCHAR(3000) AS
$BODY$
DECLARE
  v_qry VARCHAR(3000) := ' WHERE ';
  v_add_and bool := false;
BEGIN
  IF (v_season IS NOT NULL AND v_season <> '') THEN
    IF v_add_and 
    THEN v_qry := v_qry || ' AND '; 
    END IF;

    v_qry := v_qry ||
    ' p.seazon = $7 ';
                             
    v_add_and := true;                         
  END IF;

  IF (v_producttype IS NOT NULL AND v_producttype <> '') THEN
    IF v_add_and 
    THEN v_qry := v_qry || ' AND '; 
    END IF;

    v_qry := v_qry ||
    ' p.producttypeid = (SELECT pt.id FROM logistics.producttype AS pt
                             WHERE pt.name = $6) ';
                             
    v_add_and := true;                         
  END IF;
  
  IF (v_size IS NOT NULL AND v_size <> '') THEN
    IF v_add_and 
    THEN v_qry := v_qry || ' AND '; 
    END IF;
    
    v_qry := v_qry ||
    ' p.productsizeid = (SELECT ps.id FROM logistics.productsize AS ps
                             WHERE ps.name = $8) ';
    v_add_and := true;                         
  END IF;
  
  IF (v_color IS NOT NULL AND v_color <> '') THEN
    IF v_add_and 
    THEN v_qry := v_qry || ' AND '; 
    END IF;

    v_qry := v_qry ||
    ' p.colorid = (SELECT col.id FROM logistics.color AS col
                             WHERE col.name = $9) ';
  
    v_add_and := true;                         
  END IF;
  
  RETURN v_qry;
END;
$BODY$
LANGUAGE plpgsql;

CREATE OR REPLACE 
FUNCTION calc_cte_prod_cost_qty(v_city VARCHAR(50),
    v_category VARCHAR(50), v_min_price NUMERIC(15,2), v_max_price NUMERIC(15,2),
    v_vendor_name VARCHAR(500), v_product_type VARCHAR(20), v_season VARCHAR(20), 
    v_size VARCHAR(8), v_color VARCHAR(20))
RETURNS VARCHAR(3000) AS
$BODY$
DECLARE v_qry VARCHAR(3000) := '';
BEGIN
  v_qry := 'WITH ';
  IF v_category Is NOT NULL AND v_category <> '' THEN
     v_qry := v_qry || ' 
     cte_cat AS
       (
          SELECT c.id, c.parentid, c.fullname
          FROM select_categories($2) AS c
       ),
       ';
  END IF;  
  
  v_qry := v_qry || '
        cte_qty AS 
        (
            SELECT pb.productid, pb.vendorid,  SUM(pb.productcount) AS qty
            FROM logistics.city AS c 
            INNER JOIN logistics.warehouse AS w
                ON w.cityid = c.id '  || 
            (CASE WHEN (v_city IS NOT NULL AND v_city <> '') 
             THEN ' AND c.name = $1 ' ELSE '' END) || '   
            INNER JOIN logistics.warehousebin AS wb 
                ON wb.warehouseid = w.id
            INNER JOIN logistics.productbin AS pb 
                ON pb.binid = wb.id  
            INNER JOIN logistics.vendor AS v
               ON pb.vendorid = v.id ' || 
            (CASE WHEN (v_vendor_name IS NOT NULL AND v_vendor_name <> '') 
             THEN ' AND v.name = $5 ' ELSE '' END ) ||
            (CASE WHEN (v_category IS NOT NULL AND v_category <> '') 
             THEN '
             INNER JOIN logistics.productcategory as p_cat 
             ON pb.productid = p_cat.productid
             INNER JOIN cte_cat 
             ON p_cat.categoryid = cte_cat.id ' ELSE '' END) || '
             INNER JOIN logistics.product AS p
                ON pb.productid = p.id
             ' || calc_product_fields_filter(v_product_type, v_season, v_size , v_color) || '
             GROUP BY pb.productid, pb.vendorid
             ORDER BY pb.productid, pb.vendorid             
        ),
        cte_cost AS
        (
            SELECT pc.productid, pc.vendorid, pc.unitcost, pc.fromdate, 
                   rank() OVER (ORDER BY pc.fromdate DESC) AS rnk
            FROM logistics.productcost as pc 
            INNER JOIN cte_qty 
            ON cte_qty.vendorid = pc.vendorid 
            AND cte_qty.productid = pc.productid 
            AND pc.fromdate <= NOW()::date  
        ),
        cte_prod_cost_qty AS
        (
            SELECT p1.id AS productid, p1.name AS productname, 
                   v1.id AS vendorid, v1.name AS vendorname,
                   cte_cost.unitcost AS price, cte_qty.qty::int AS quantity
            FROM cte_cost 
            INNER JOIN cte_qty
            ON cte_cost.productid = cte_qty.productid AND
               cte_cost.vendorid = cte_qty.vendorid
            INNER JOIN logistics.product AS p1
            ON p1.id = cte_cost.productid
            INNER JOIN logistics.vendor AS v1
            ON v1.id = cte_cost.vendorid
            ' || (CASE WHEN v_max_price > 0 
                  THEN ' WHERE cte_cost.unitcost >= $3 AND cte_cost.unitcost <= $4 ' 
                  ELSE '' END ) ||'
        ) ';

RETURN v_qry;
END;
$BODY$
LANGUAGE plpgsql;

CREATE OR REPLACE 
FUNCTION create_query_products_by_filters(v_city VARCHAR(50),
	v_category VARCHAR(50), v_min_price NUMERIC(15,2), v_max_price NUMERIC(15,2),
    v_vendor_name VARCHAR(500), v_product_type VARCHAR(20), v_season VARCHAR(20), 
    v_size VARCHAR(8), v_color VARCHAR(20),
    sort_by_name BOOL, sort_by_price BOOL, sort_by_vendor BOOL, 
    page_number INT, records_per_page INT)
RETURNS TEXT AS 
$BODY$
DECLARE v_cte VARCHAR(3000) := ''; 
        v_select_statement VARCHAR(3000) := '';
        v_order_by_statement VARCHAR(3000) := '';
        v_limit_statement VARCHAR(3000) := '';
        v_product_query VARCHAR(3000) := '';
BEGIN

  v_cte := calc_cte_prod_cost_qty(v_city, v_category , 
                             v_min_price, v_max_price,
                             v_vendor_name , v_product_type, 
                             v_season , v_size , v_color );
  
  v_select_statement := '
   SELECT p.productid, p.productname AS product, 
   p.vendorid, p.vendorname AS vendor,
   p.price, p.quantity FROM cte_prod_cost_qty AS p '; 
  
 v_order_by_statement := CONCAT(' 
    ORDER BY ',
	( CASE WHEN sort_by_name THEN ' p.productname,' ELSE '' END ),
	( CASE WHEN sort_by_vendor THEN ' p.vendorname,' ELSE '' END ),
	( CASE WHEN sort_by_price THEN ' p.price,' ELSE '' END ),
	( CASE WHEN NOT sort_by_name THEN ' p.productname,' ELSE '' END ),
	( CASE WHEN NOT sort_by_vendor THEN ' p.vendorname,' ELSE '' END)); 
  v_order_by_statement := trim ( TRAILING ',' FROM v_order_by_statement );  
 
  IF (page_number > 0 AND records_per_page > 0) 
  THEN
    v_limit_statement :=
      CONCAT( ' LIMIT ', records_per_page,
      (CASE WHEN page_number > 1 
       THEN ' OFFSET ' || ((page_number - 1) * records_per_page) 
       ELSE ' ' END));
  END IF;

  v_product_query := CONCAT(v_cte, 
                            v_select_statement,
                            v_order_by_statement,
                            v_limit_statement);

 RETURN v_product_query;

END; 
$BODY$
LANGUAGE plpgsql;

CREATE OR REPLACE 
FUNCTION get_products_by_filters(v_city VARCHAR(50),
	v_category VARCHAR(50), v_min_price NUMERIC(15,2), v_max_price NUMERIC(15,2),
    v_vendor_name VARCHAR(500), v_product_type VARCHAR(20), v_season VARCHAR(20), 
    v_size VARCHAR(8), v_color VARCHAR(20),
    sort_by_name BOOL, sort_by_price BOOL, sort_by_vendor BOOL, 
    page_number INT, records_per_page INT)
RETURNS TABLE (productid INT, productname VARCHAR(500),
               vendorid INT, vendorname VARCHAR(500),
               price NUMERIC(13,2), quantity INT) AS
$BODY$
DECLARE v_sql TEXT;
BEGIN
 v_sql := create_query_products_by_filters (v_city, v_category, v_min_price, v_max_price,
      v_vendor_name, v_product_type, v_season, 
      v_size, v_color, sort_by_name, sort_by_price, sort_by_vendor,
      page_number, records_per_page);
      
 RETURN QUERY EXECUTE v_sql
 USING v_city, v_category, v_min_price, v_max_price,
       v_vendor_name, v_product_type, v_season, 
       v_size, v_color;
End;
$BODY$
LANGUAGE plpgsql;


-- test --

SELECT pz.name, * FROM products_by_category('Москва', 'Одежда для девочек') AS t1
INNER JOIN logistics.product as p 
ON t1.price < 1000 AND t1.productid = p.id
INNER JOIN logistics.productsize as pz
ON p.productsizeid = pz.id
order by t1.price;

select * FROM get_products_by_filters('Москва', 'Одежда для девочек',0, 1000,
                                      '', '','','128', 'синий', 
                                     true, false, false,
                                     0, 0);

select * FROM get_products_by_filters('Москва', 'Одежда для девочек',0, 1000,
                                      '', '','','', 'синий', 
                                     false, false, true,
                                     0, 0);

select * FROM get_products_by_filters('Москва', 'Одежда для девочек',0, 1000,
                                      '', '','','', 'синий', 
                                     false, true, false,
                                     0, 0);

select * FROM get_products_by_filters('Москва', 'Одежда для девочек',0, 1000,
                                      'Dolphin', '','','', 'синий', 
                                     true, false, false,
                                     0, 0);

select * FROM get_products_by_filters('Москва', 'Одежда для девочек',0, 1000,
                                      '', 'Комбинизон','','', 'синий', 
                                     true, false, false,
                                     0, 0);
