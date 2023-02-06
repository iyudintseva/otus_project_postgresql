DROP PROCEDURE IF EXISTS  generate_salesorders;
DROP PROCEDURE IF EXISTS  create_salesorder;

CREATE OR REPLACE PROCEDURE create_salesorder(v_i INT, v_order_date DATE)
AS $BODY$
	DECLARE 
      v_order_id INT := 0; 
      v_month INT := 0; 
      v_customerid int := 0;
      v_order_status orderstatus_type;
      v_order_number varchar(16);
      v_deliverydate date;
      v_price numeric(15,2) := 0;
      v_pricedtl numeric(15,2) := 0;
      v_order_line int := 0;
  BEGIN

    v_order_number = CONCAT('ASDFG', v_i);
    v_order_status := 'Подтвержден';
    v_month := EXTRACT(MONTH FROM v_order_date);  
    
    IF v_month = 11 THEN
	  v_order_status := 'Доставлен';
    ELSEIF v_month = 12 THEN 	
	  v_order_status := 'Оплачен';
    END IF;  

    SELECT id FROM orders.customer 
    ORDER BY id LIMIT 1
    INTO v_customerid;

    SELECT id FROM orders.customer 
    WHERE id >= RANDOM()*200 + v_customerid 
    ORDER BY id LIMIT 1
    INTO v_customerid;
    
    v_deliverydate := v_order_date + INTERVAL '1 day';

    INSERT INTO  orders.salesorder 
      (ordernumber, orderdate, orderstatus, customerid, needdelivery,
       deliverydate, deliverytimeinterval, deliverycost, price, total) 
    VALUES (v_order_number, v_order_date, v_order_status, v_customerid, true,
              v_deliverydate, '14:00-18:00', 199, 0, 199)
    ON CONFLICT DO NOTHING
    RETURNING id INTO v_order_id;  
  
   -- add 5 order lines
   v_price := 0; -- для расчета общей стоимости
   LOOP
      v_order_line := v_order_line + 1;
      
      WITH 
        cte_pv AS 
        (
           -- выберем случайным образом продукт в наличии
           SELECT productid, vendorid 
           FROM logistics.productbin 
           WHERE productid >= (RANDOM()*100000 + 1 )::int
           LIMIT 1 
        ),
        cte_pc AS
        (
           -- узнаем его цену
           SELECT pc.productid, pc.vendorid, pc.unitcost 
           FROM logistics.productcost AS pc
           INNER JOIN cte_pv  
           ON pc.vendorid = cte_pv.vendorid AND pc.productid = cte_pv.productid
           LIMIT 1 
        )
      INSERT INTO orders.orderdtl 
	    	( salesorderid, orderline, vendorid, productid, unitcost, 
             discountpercent, productcount, price) 
      SELECT v_order_id, v_order_line, cte_pc.vendorid, cte_pc.productid,
             cte_pc.unitcost, 0, 1, cte_pc.unitcost 
      FROM cte_pc  
      ON CONFLICT DO NOTHING
      RETURNING unitcost INTO v_pricedtl;

      v_price := v_price + v_pricedtl;
      
      IF v_order_line >= 5 THEN
          EXIT;
	  END IF;
    END LOOP;
  
    UPDATE orders.salesorder
    SET price = v_price, total = total + price
    WHERE id = v_order_id;

  COMMIT; 
END 
$BODY$
LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE  generate_salesorders()
AS $BODY$
  DECLARE 
      v_p1 int := -98;
      v_p2 int := 0;
      v_order_date date;
  BEGIN
    <<loop1>>
    LOOP
      v_p1 := v_p1 + 100;
      v_p2 := 0;
      
      <<loop2>>
      LOOP
        v_p2 := v_p2 + 1;
      
        v_order_date = '2022-12-05';
        IF v_p2 < 25 THEN
           v_order_date = '2022-11-05';
        ELSEIF v_p2 < 50 THEN   
          v_order_date = '2022-12-18';
        ELSEIF v_p2 < 70 THEN   
          v_order_date = '2023-01-12';
        END IF;

        CALL create_salesorder(v_p1 + v_p2, v_order_date);

        IF v_p2 >= 100 THEN
          COMMIT;
          EXIT;
	  	END IF;
      END LOOP loop2;
      IF v_p1 >= 10000 THEN
        EXIT;
	  END IF;
    END LOOP loop1;
  COMMIT; 
END 
$BODY$
LANGUAGE plpgsql;

CALL generate_salesorders();

DROP PROCEDURE IF EXISTS  generate_salesorders;
DROP PROCEDURE IF EXISTS  create_salesorder;