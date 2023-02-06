DROP PROCEDURE IF EXISTS  generate_products;
DROP PROCEDURE IF EXISTS  create_product;

CREATE OR REPLACE PROCEDURE create_product(v_product_id INT)
AS $BODY$
	DECLARE 
      v_productid int := 0;
      v_season season_type := 'На любой сезон';
      v_colorid SMALLINT := RANDOM() * 17 + 1; 
      v_productsizeid smallint := RANDOM() * 46 + 1; 
      v_producttypeid smallint := RANDOM() * 40 + 1; 
      v_vendorid smallint := RANDOM() * 117 + 1; 
      v_producttype VARCHAR(20);
      v_color VARCHAR(20); 
      v_specifications JSON;
  BEGIN
    
    SELECT name FROM logistics.producttype 
    WHERE Id = v_producttypeid
    INTO v_producttype;
    
    SELECT name FROM logistics.color 
    WHERE Id = v_colorid
    INTO v_color;

    INSERT INTO logistics.product
	    (productcode,name,Description,producttypeid,colorid,season,productsizeid)
	  VALUES 
      ( SUBSTRING(CONCAT('A', v_product_id, 'BCDEFG'), 0, 8), 
        CONCAT(v_producttype, ' ', v_color), '', 
        v_producttypeid, v_colorid, v_season, v_productsizeid)
    ON CONFLICT DO NOTHING
    RETURNING id INTO v_productid; 

    INSERT INTO logistics.productvendor (productid,vendorid)
	  VALUES ( v_productid, v_vendorid)
    ON CONFLICT DO NOTHING;

    INSERT INTO logistics.productCost (productid,vendorid, unitcost, fromdate)
	  VALUES ( v_productid, v_vendorid, RANDOM() * 5000 + 1, now()::date)
    ON CONFLICT DO NOTHING;

    WITH ptc_cte AS
    (
      SELECT categoryid 
      FROM logistics.producttypecategory
      WHERE producttypeid = v_producttypeid
    )
    INSERT INTO logistics.productcategory (productid, categoryid)
    SELECT v_productid AS productid, Categoryid 
    FROM ptc_cte
    ON CONFLICT DO NOTHING;

  COMMIT; 
END 
$BODY$
LANGUAGE plpgsql;

CALL create_product(1);
select id from logistics.product order by id desc limit 1;

CREATE OR REPLACE PROCEDURE  generate_products()
AS $BODY$
	DECLARE 
      v_p1 int := 0;
      v_p2 int := 0;
      v_id int := 0;
  BEGIN
    <<outloop>>
    LOOP
      v_p1 := v_p1 + 1;
      v_p2 := 0;
      
      <<inloop>>
      LOOP
        v_p2 := v_p2 + 1;
        v_id = v_id + 1;

        CALL create_product(v_id);

        IF v_p2 >= 1000 THEN
          EXIT;
	  	  END IF;
      END LOOP inloop;
      COMMIT;
      IF v_p1 >= 100000 THEN
        EXIT;
	  END IF;
    END LOOP outloop;
END 
$BODY$
LANGUAGE plpgsql;

CALL generate_products();

SELECT count(1) FROM product;

DROP PROCEDURE IF EXISTS  generate_products;
DROP PROCEDURE IF EXISTS  create_product;


CREATE OR REPLACE PROCEDURE update_product(v_product_id INT)
AS $BODY$
	DECLARE 
      v_style VARCHAR(20) := 'классический'; 
      v_productweight VARCHAR(20);  
      v_packageheight INT := 2;
      v_packagelength INT := 26;
      v_packagewifth INT := 20;
      v_material VARCHAR(100) := '69% хлопок, 29% полиэстер, 2% эластан'; 
      v_specifications JSONB;
      v_txt_spec VARCHAR(3000);
      v_producttype VARCHAR(20);
      v_name VARCHAR(20);
      v_desc VARCHAR(3000) := '';
    BEGIN
    
    SELECT p.name FROM logistics.Product as p
    WHERE p.id = v_product_id
    INTO v_name;
  
    SELECT pt.name FROM logistics.producttype as pt
    INNER JOIN logistics.Product as p
    ON p.producttypeid = pt.id and p.id = v_product_id
    LIMIT 1
    INTO v_producttype;  
  
    IF (v_producttype = 'Босоножки' OR
        v_producttype = 'Ботинки' OR
        v_producttype = 'Туфли' OR
        v_producttype = 'Сапоги' OR
        v_producttype = 'Сандалии') THEN
        v_material := 'кожа';
        v_packageheight = 15;
    ELSEIF v_producttype = 'Балетки' THEN
        v_material := 'кожа';
        v_packageheight = 15;
    ELSEIF v_producttype = 'Валенки' OR
           v_producttype = 'Шапка' THEN
        v_material := 'шерсть';
        v_packageheight = 15;
    ELSEIF v_producttype = 'Кеды' THEN
        v_material := 'Верх: 60% полиэстер, 40% вискоза';
        v_packageheight = 15;
    ELSEIF v_producttype = 'Резиновые сапоги' THEN
        v_material := '100% ПВХ';
        v_packageheight = 15;
    ELSEIF v_producttype = 'Брюки' OR
           v_producttype = 'Трусы' THEN
        v_material := '95% хлопок, 5% эластан';
    ELSEIF  v_producttype = 'Боди' OR
            v_producttype = 'Песочник' OR
            v_producttype = 'Пижама' OR
            v_producttype = 'Пинетки' OR
            v_producttype = 'Ползунки' OR
            v_producttype = 'Футболка' OR
            v_producttype = 'Чепчик' THEN
        v_material := '100% хлопок';
    ELSEIF v_producttype = 'Джемпер' THEN
        v_material :=   '82% хлопок, 18% нейлон'; 
    ELSEIF v_producttype = 'Комбинизон' OR
            v_producttype = 'Куртка' OR
            v_producttype = 'Полукомбинизон' THEN
        v_material := 'Верх: 100% полиэстер. Покрытие: 100% полиуретан. Подкладка: 100% полиэстер. Наполнитель: 100% полиэстер, 200 г/м2.';
    ELSEIF v_producttype = 'Свитер' THEN
        v_material :=   '50% вискоза, 50% нейлон.';
    END IF;
  
    v_txt_spec := concat('{
       "style": "классический",
       "material": "', v_material, '",                 
       "productweight": 300,
       "packageheight": ', v_packageheight, ',
       "packagelength": 26,
       "packagewifth": 20
    }');    

    v_specifications := v_txt_spec::JSONB;

    v_desc := concat(v_name, ' цвета, изготовлены из ', v_material);

    UPDATE logistics.Product
    SET specifications = v_specifications,
        description = v_desc
    WHERE id = v_product_id;    

  COMMIT; 
END 
$BODY$
LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE  update_products()
AS $BODY$
	DECLARE 
      v_id int := 0;
  BEGIN
    <<outloop>>
    LOOP
      v_id := v_id + 1;

      CALL update_product(v_id);

      IF v_id >= 124536 THEN
        EXIT;
	  END IF;
    END LOOP outloop;
END 
$BODY$
LANGUAGE plpgsql;

CALL update_products();

