-- category
-- import data from category.csv 
COPY logistics.category(fullname, id, parentid, name) FROM '/var/lib/postgresql/data/Category.csv' DELIMITER ',' CSV HEADER;

-- city
-- import data from city.csv 
COPY logistics.city FROM '/var/lib/postgresql/data/City.csv' DELIMITER ',' CSV HEADER;

-- color
-- import data from color.csv 
COPY logistics.color(name) FROM '/var/lib/postgresql/data/Color.csv' DELIMITER ',' CSV HEADER;

-- Customer
-- import data from names.csv 
-- Create temp table for import customers
CREATE TABLE temp_customer
( Id INT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  fullname VARCHAR(500) UNIQUE NOT NULL
);

-- import data from names.csv 
COPY temp_customer(fullname) FROM '/var/lib/postgresql/data/Names.csv' DELIMITER ',' CSV HEADER;
 
-- move data to Customer table
INSERT INTO orders.customer
	(id, fullname, firstname, lastname, address, email, phone)
OVERRIDING SYSTEM VALUE    
SELECT temp_customer.id, temp_customer.fullname,
       substring(temp_customer.fullname, 0, position(' ' in temp_customer.fullname)),
       substring(temp_customer.fullname, position(' ' in temp_customer.fullname) + 1, length(temp_customer.fullname)),
       concat('address of ', temp_customer.fullname), 
       concat(replace(temp_customer.fullname, ' ', '_'), '@mail.ru'),
	   substring(concat('+7495', temp_customer.id, '123456'), 1, 12)
	FROM temp_customer;

DROP TABLE IF EXISTS temp_customer;
COMMIT;
 
-- productsize
-- import data from productsize.csv 
COPY logistics.productsize(id, name, age) FROM '/var/lib/postgresql/data/ProductSize.csv' DELIMITER ',' CSV HEADER;
    
-- producttype
-- import data from producttype.csv 
COPY logistics.producttype(id, name) FROM '/var/lib/postgresql/data/ProductType.csv' DELIMITER ',' CSV HEADER;

-- producttypecategory
-- import data from producttypecategory.csv 
COPY logistics.producttypecategory FROM '/var/lib/postgresql/data/ProductTypeCategory.csv' DELIMITER ',' CSV HEADER;

-- vendor
-- Create temp table for import vendors
CREATE TABLE temp_vendor
( name VARCHAR(500) UNIQUE NOT NULL
);
-- import data from vendor.csv 
COPY temp_vendor FROM '/var/lib/postgresql/data/Vendor.csv' DELIMITER ',' CSV HEADER;
-- move data to vendor table
INSERT INTO logistics.vendor
	(name, description, address, email, phone)
SELECT temp_vendor.name, '',
	   concat('address of ', temp_vendor.name), 
       concat(replace(temp_vendor.name, ' ', '_'),'@mail.ru'), 
       '+79998887766'
	FROM temp_vendor;

DROP TABLE IF EXISTS temp_vendor;

   
