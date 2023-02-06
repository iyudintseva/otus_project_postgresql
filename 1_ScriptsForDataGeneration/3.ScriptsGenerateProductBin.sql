-- сгенерировать записи в таблицe warehouse
DROP PROCEDURE IF EXISTS create_warehouse;
CREATE OR REPLACE PROCEDURE create_warehouse()
AS $BODY$
	DECLARE v_p1 int := 0;
            v_city varchar(20); 
  BEGIN
    LOOP
      v_p1 := v_p1 + 1;

      SELECT name FROM logistics.city WHERE id = v_p1 INTO v_city;
      
      INSERT INTO logistics.warehouse (cityid, name, address, phone, isstore)
       VALUES(v_p1, 'MyShop-1',  concat(v_city, ', ул. Мира, д.1'), '+79998887766', true); 

      INSERT INTO logistics.warehouse (cityid, name, address, phone, isstore)
       VALUES(v_p1, 'MyShop-2',  concat(v_city, ', ул. Ленина, д.1'), '+79998887766', true); 

      INSERT INTO logistics.warehouse (cityid, name, address, phone, isstore)
       VALUES(v_p1, 'MyShop-3',  concat(v_city, ', ул. Пушкина, д.1'), '+79998887766', false);

      IF v_p1 >= 50 THEN
          EXIT;  
      END IF;
    END LOOP;
  COMMIT; 
END 
$BODY$
LANGUAGE plpgsql;

CALL create_warehouse();

DROP PROCEDURE IF EXISTS create_warehouse;

-- сгенерировать записи в таблицe warehousebin
DROP PROCEDURE IF EXISTS create_warehousebin;
CREATE OR REPLACE PROCEDURE create_warehousebin()
AS $BODY$
	DECLARE 
      v_id int := 0;
      v_last_id int := 0;
      v_p1 int := 0;
      v_p2 int := 0;
  BEGIN
    SELECT id FROM logistics.warehouse
    ORDER BY id LIMIT 1 INTO v_id;
  
    SELECT id FROM logistics.warehouse
    ORDER BY id DESC LIMIT 1 INTO v_last_id;
    
    v_p1 := v_id - 1;
    
    -- for each warehouses create 1000 bins
    <<warehouse_loop>>
    LOOP
      v_p1 := v_p1 + 1;
      v_p2 := 0;
      <<bin_loop>>
      LOOP
          v_p2 := v_p2 + 1;

		  INSERT INTO logistics.warehousebin (warehouseid, bin)
          VALUES (v_p1, SUBSTRING(concat('A', v_p1, 'B', v_p2),0,8)); 
		  IF v_p2 >= 100 THEN
            EXIT;
		  END IF;
      END LOOP bin_loop;
      IF v_p1 >= v_last_id THEN
          EXIT;
	  END IF;
    END LOOP warehouse_loop;
  COMMIT; 
END 
$BODY$
LANGUAGE plpgsql;

CALL create_warehousebin();

drop procedure if exists create_warehousebin;

-- сгенерировать записи в таблицe productbin
DROP PROCEDURE IF EXISTS create_productbin;
DROP PROCEDURE IF EXISTS create_productbin_for_warehouse;


CREATE OR REPLACE PROCEDURE create_productbin_for_warehouse(v_warehouseid int)
AS $BODY$
	DECLARE 
      v_p1 int := 0;
      v_first_id int := 0;
      v_last_id int := 0;
  BEGIN
    SELECT id FROM logistics.warehousebin 
    WHERE warehouseid = v_warehouseid
    ORDER BY id LIMIT 1
    INTO v_first_id;
    
    SELECT id FROM logistics.warehousebin 
    WHERE warehouseid = v_warehouseid
    ORDER BY id DESC LIMIT 1
    INTO v_last_id;
    
    -- в одну ячейку кладем 1 вид товара
    v_p1 := v_first_id - 1;
    LOOP  
      v_p1 := v_p1 + 1;

      INSERT INTO logistics.productbin (productid, vendorid, binid, productcount) 
      SELECT pv.productid, pv.vendorid, wb.id, (RANDOM()*(100) + 1)::int
	  FROM logistics.warehousebin as wb
      INNER JOIN logistics.productvendor as pv
      ON wb.warehouseid = v_warehouseid AND 
         wb.id = v_p1 AND
         pv.productid = (RANDOM()*100000 + 1)::int 
      ON CONFLICT DO NOTHING;

      IF v_p1 >= v_last_id THEN
          EXIT;
	  END IF;
    END LOOP;
  COMMIT; 
END 
$BODY$
LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE create_productbin()
AS $BODY$
	DECLARE 
    v_l1 int := 0;
    v_fwid int := 0;
    v_lwid int := 0;
  BEGIN
    
    SELECT id FROM logistics.warehouse 
    ORDER BY id
    LIMIT 1
    INTO v_fwid;

    SELECT id FROM logistics.warehouse 
    ORDER BY id DESC
    LIMIT 1
    INTO v_lwid;

    v_l1 := v_fwid - 1;

    LOOP  
      v_l1 := v_l1 + 1;

      CALL create_productbin_for_warehouse(v_l1);
      
      IF v_l1 >= v_lwid THEN
          EXIT;
	  END IF;
    END LOOP;
  END 
$BODY$
LANGUAGE plpgsql;
 
CALL create_productbin();

DROP PROCEDURE IF EXISTS create_productbin;
DROP PROCEDURE IF EXISTS create_productbin_for_warehouse;