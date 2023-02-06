-- poли
CREATE ROLE customeruser; 
CREATE ROLE manageruser;  
CREATE USER adminuser WITH SUPERUSER PASSWORD 'StudyDb';

-- схемы
CREATE SCHEMA IF NOT EXISTS logistics;
CREATE SCHEMA IF NOT EXISTS orders; 

-- таблицы
CREATE TABLE logistics.city (
 id SMALLINT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 name VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE logistics.warehouse(
  id INT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  cityid SMALLINT NOT NULL,
  name VARCHAR(500) NOT NULL,
  isstore BOOLEAN NOT NULL DEFAULT false, 
  address VARCHAR(1000) NOT NULL, 
  phone VARCHAR(50) NOT NULL, 
  CONSTRAINT fk_warehouse_city FOREIGN KEY (cityid) REFERENCES logistics.city (id)
);
CREATE INDEX idx_warehouse_city ON logistics.warehouse (cityid);

CREATE TABLE logistics.warehousebin(
  id SMALLINT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  warehouseid INT NOT NULL,
  bin VARCHAR(16) NOT NULL,
  CONSTRAINT fk_warehouseBin_warehouse FOREIGN KEY (warehouseid) REFERENCES logistics.warehouse (id)
);
CREATE INDEX idx_warehousebin_warehouse ON logistics.warehousebin (warehouseid);

CREATE TABLE logistics.category(
  id SMALLINT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  parentid SMALLINT,
  name VARCHAR(50),
  fullname VARCHAR(500)
);
CREATE INDEX idx_category_name ON logistics.category(name);

CREATE TABLE logistics.producttype(
  id SMALLINT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name VARCHAR(20) UNIQUE NOT NULL
);

CREATE TABLE logistics.producttypecategory(
  producttypeid SMALLINT NOT NULL,
  categoryid SMALLINT NOT NULL,
  PRIMARY KEY (producttypeid, categoryid),
  CONSTRAINT fk_producttypecategory_category FOREIGN KEY (categoryid) REFERENCES logistics.category (id),
  CONSTRAINT fk_producttypecategory_productType FOREIGN KEY (producttypeid) REFERENCES logistics.producttype (id)
);

CREATE TABLE logistics.color(
  id SMALLINT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name VARCHAR(20) UNIQUE NOT NULL
);

CREATE TABLE logistics.productsize(
  id SMALLINT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name VARCHAR(50) UNIQUE NOT NULL,
  age VARCHAR(20)
);

CREATE TYPE season_type AS ENUM ('На любой сезон','Зима','Демисезон','Весна','Лето','Осень');
CREATE TABLE logistics.product (
  id INT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  productcode CHAR(9) UNIQUE NOT NULL,
  name VARCHAR(500) NOT NULL,
  description VARCHAR(1000), 
  producttypeid SMALLINT,
  season season_type,
  productsizeid SMALLINT,
  colorid SMALLINT,
  specifications JSON
  CONSTRAINT fk_product_producttype FOREIGN KEY (producttypeid) REFERENCES logistics.producttype (id),
  CONSTRAINT fk_product_color FOREIGN KEY (colorid) REFERENCES logistics.color (id),
  CONSTRAINT fk_product_productsize FOREIGN KEY (productsizeid) REFERENCES logistics.productsize (id)
);
CREATE INDEX idx_product_name ON logistics.product (Name);
CREATE INDEX idx_specification ON logistics.product USING GIN (specifications jsonb_path_ops);
CREATE INDEX idx_product_desc ON logistics.product USING GIN (to_tsvector('russian', description));


CREATE TABLE logistics.productcategory(
  categoryid SMALLINT NOT NULL,
  productid INT NOT NULL,
  PRIMARY KEY (categoryId, productid),
  CONSTRAINT fk_productcategory_category FOREIGN KEY (categoryid) REFERENCES logistics.category (id),
  CONSTRAINT fk_productcategory_product FOREIGN KEY (productid) REFERENCES logistics.product (id)
);

CREATE TABLE logistics.vendor(
  id INT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name VARCHAR(500) UNIQUE NOT NULL,
  description VARCHAR(1000), 
  address VARCHAR(1000) NOT NULL, 
  email VARCHAR(50) NOT NULL, 
  phone VARCHAR(50) NOT NULL 
);

create table logistics.productvendor(
  vendorid  INT NOT NULL,
  productid INT NOT NULL,
  PRIMARY KEY (vendorid, productid),
  CONSTRAINT fk_productvendor_vendor FOREIGN KEY (vendorid) REFERENCES logistics.vendor (id),
  CONSTRAINT fk_productvendor_product FOREIGN KEY (productid) REFERENCES logistics.product (id)
);

create table logistics.productcost(
  vendorid  INT NOT NULL,
  productid INT NOT NULL,
  unitcost  NUMERIC(15,2) NOT NULL,
  fromdate DATE NOT NULL,
  PRIMARY KEY (vendorid, productid),
  CONSTRAINT fk_productcost_productvendor FOREIGN KEY (vendorid, productid) REFERENCES logistics.productvendor (vendorid, productid)
);

CREATE TABLE logistics.productbin(
  productid INT NOT NULL,
  vendorid INT NOT NULL,
  binid INT NOT NULL,
  productcount INT NOT NULL,
  PRIMARY KEY (productid, vendorid, binid),
  CONSTRAINT fk_productbin_warehousebin FOREIGN KEY (binid) REFERENCES logistics.warehouseBin (id),
  CONSTRAINT fk_productbin_productvendor FOREIGN KEY (vendorid, productid) REFERENCES logistics.productvendor (vendorid, productid)
);

CREATE TABLE orders.promocode(
  id SMALLINT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  promocode VARCHAR(8) NOT NULL,
  fromdate DATE, 
  todate DATE, 
  discountpercent SMALLINT CHECK (discountpercent >= 0 AND discountpercent <= 100)  
);

create table orders.customer(
  id INT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  fullname VARCHAR(500) NOT NULL,
  firstname VARCHAR(100) NOT NULL,
  lastname VARCHAR(400) NOT NULL,
  address VARCHAR(1000),
  email VARCHAR(50) UNIQUE NOT NULL,
  phone VARCHAR(50) NOT NULL
);
CREATE INDEX idx_customer_fullname ON orders.customer (fullname);

CREATE TYPE orderstatus_type AS ENUM ('Новый','Подтвержден','Оплачен','Доставлен','Отменен');                                    
CREATE TYPE deliverytimeinterval_type AS ENUM ('10:00-14:00','14:00-18:00','18:00-22:00');                                    
CREATE TABLE orders.salesorder(
  id INT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  ordernumber VARCHAR(16) UNIQUE NOT NULL,
  orderdate DATE NOT NULL,
  orderstatus orderstatus_type DEFAULT 'Новый',
  customerid INT NOT NULL,
  needdelivery BOOLEAN,
  deliverydate DATE,  
  deliverytimeinterval deliverytimeinterval_type DEFAULT '10:00-14:00',
  deliverycost NUMERIC(13,2),
  price NUMERIC(15,2),
  total NUMERIC(15,2),
  promocodeid SMALLINT,
  CONSTRAINT fk_salesorder_customer FOREIGN KEY (customerid) REFERENCES orders.Customer (id),
  CONSTRAINT fk_salesorder_promocode FOREIGN KEY (promocodeid) REFERENCES orders.Promocode (id)
);
CREATE INDEX idx_salesorder_orderdate ON orders.salesorder(orderdate);
CREATE INDEX idx_salesorder_customer ON orders.salesorder(customerid);

CREATE TABLE orders.orderdtl(
  salesorderid INT NOT NULL,
  orderline INT NOT NULL,
  productid INT NOT NULL,
  vendorid  INT NOT NULL,
  unitcost  NUMERIC(13,2),
  productcount smallint NOT NULL CHECK (productcount > 0)
  discountpercent smallint NOT NULL CHECK (discountpercent >= 0 AND discountpercent <= 100), 
  price NUMERIC(13,2),
  CONSTRAINT pk_orderdtl PRIMARY KEY (salesorderid, orderline), 
  CONSTRAINT fk_orderdtl_salesorder FOREIGN KEY (salesorderid) REFERENCES orders.salesorder (id) ON DELETE CASCADE,
  CONSTRAINT fk_orderdtl_productvendor FOREIGN KEY (vendorid, productid) REFERENCES logistics.productvendor (vendorid, productid)
);
CREATE INDEX idx_orderdtl_productvendor ON orders.orderdtl(productid, vendorid);

CREATE TYPE shipstatus_type AS ENUM ('В сборке', 'У курьера', 'Доставлен');
CREATE TABLE logistics.shiphdr(
  Id INT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY, 
  shipnumber VARCHAR(16) UNIQUE NOT NULL,
  shipdate DATE NOT NULL,
  fromwarehouseid INT NOT NULL,
  Status shipstatus_type default 'В сборке',
  CONSTRAINT fk_shiphdr_warehouse FOREIGN KEY (fromwarehouseid) REFERENCES logistics.warehouse (id)
);
CREATE INDEX idx_shiphdr_date ON logistics.shiphdr(shipdate);

CREATE TABLE logistics.shipdtl(
  shiphdrId INT NOT NULL,
  shipline INT NOT NULL,
  frombinid INT NOT NULL,
  productid INT NOT NULL,
  vendorid  INT NOT NULL,
  salesorderid INT,
  orderline INT,
  tobinid INT,
  productcount INT,
  CONSTRAINT pk_shipdtl PRIMARY KEY (shiphdrid, shipline), 
  CONSTRAINT fk_shipdtl_productbin FOREIGN KEY (vendorid, productid, frombinid) REFERENCES logistics.productbin (vendorid, productid, binid)
);
CREATE INDEX idx_shipdtl_productbin ON logistics.shipdtl(vendorid, productid, frombinid);

-- безопасность
grant all privileges on database otus to adminuser;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA logistics TO manageruser;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA logistics TO manageruser;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA orders TO manageruser;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA orders TO manageruser;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA orders TO customeruser;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA orders TO customeruser;
GRANT SELECT ON ALL TABLES IN SCHEMA logistics TO customeruser;
GRANT INSERT, UPDATE, DELETE ON TABLE logistics.shiphdr TO customeruser;
GRANT INSERT, UPDATE, DELETE ON TABLE logistics.shipdtl TO customeruser;



