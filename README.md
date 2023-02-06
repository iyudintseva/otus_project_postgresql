# Схема Базы данных

# ТАБЛИЦЫ
### **City** - список городов , где расположены магазины и склады
Field | Type | Properties | Description 
--- | --- | --- | ---
Id | SMALLINT | PRIMARY KEY AUTO_INCREMENT | Идентификатор
Name | VARCHAR(50) | UNIQUE NOT NULL | Наименование города

### **Warehouse** - список магазинов и складских помещений с адресами
Field | Type | Properties | Description 
--- | --- | --- | ---
Id | INT | PRIMARY KEY AUTO_INCREMENT | Идентификатор
CityId | SMALLINT | NOT NULL | Указатель на город
Name | VARCHAR(500) | NOT NULL | Наименование
IsStore | BOOLEAN | NOT NULL DEFAULT false | Флаг, является ли помещение магазином 
Address | VARCHAR(1000) | NOT NULL | Адрес помещения 
Phone | VARCHAR(50) | NOT NULL | Телефон 

### **WarehouseBin** - ячейки на складе 
Field | Type | Properties | Description 
--- | --- | --- | ---
Id | INT | PRIMARY KEY AUTO_INCREMENT | Идентификатор
WarehouseId | INT | NOT NULL | Указатель на склад
Bin | VARCHAR(16) | NOT NULL | Номер ячейки

### **Category** - категории для поиска товара
Field | Type | Properties | Description 
--- | --- | --- | ---
Id | SMALLINT | PRIMARY KEY AUTO_INCREMENT | Идентификатор
ParentId | SMALLINT | | Указатель на родительскую категорию 
Name | VARCHAR(50) | | Наименование
FullName | VARCHAR(500) | | Полный путь с родительскими категориями  для отображения в отчетах

### **ProductType** - список типов товаров
Field | Type | Properties | Description 
--- | --- | --- | ---
Id | SMALLINT | PRIMARY KEY AUTO_INCREMENT | Идентификатор
Name | VARCHAR(50) | | Наименование

### **ProductTypeCategory** - Связь типа товара с категориями
Field | Type | Properties | Description 
--- | --- | --- | ---
ProductTypeId | SMALLINT | NOT NULL | Указатель на тип товара
CategoryId | SMALLINT | NOT NULL | Указатель на категорию

### **Color** - список основных цветов товара
Field | Type | Properties | Description 
--- | --- | --- | ---
Id | SMALLINT | PRIMARY KEY AUTO_INCREMENT | Идентификатор
Name | VARCHAR(50) | | Наименование

### **ProductSize** - список размеров товаров
Field | Type | Properties | Description 
--- | --- | --- | ---
Id | SMALLINT | PRIMARY KEY AUTO_INCREMENT | Идентификатор
Name | VARCHAR(50) | | Наименование
Age | VARCHAR(20) | | Возраст

### **Product** - таблица с информацией о товарах
Field | Type | Properties | Description 
--- | --- | --- | ---
Id | INT | PRIMARY KEY AUTO_INCREMENT | Идентификатор
ProductCode | CHAR(9) | UNIQUE NOT NULL | Код продукта для поиска
Name | VARCHAR(500) | NOT NULL | Наименование
Description | VARCHAR(1000) | | Описание
ProductTypeId | SMALLINT | |Указатель на тип продукта. Продукт не может быть связан с категорией неподходящей для выбранного типа
Season | ENUM('На любой сезон', 'Зима', 'Демисезон', 'Весна', 'Лето','Осень') | | Сезонность
ProductSizeId | SMALLINT | | указатель на размер 
ColorId | SMALLINT | |Указатель на цвет
Specifications | JSON | | JSON c характеристиками товара
txtSpecifications | VARCHAR(3000) | | комбинация всех описаний о товаре для полнетекстового поиска

### **ProductCategory** - Связь товара с категориями
Field | Type | Properties | Description 
--- | --- | --- | ---
ProductId | INT | NOT NULL | Указатель на продукт
CategoryId | SMALLINT | NOT NULL | Указатель на категорию

### **Vendor** - Список поставщиков
Field | Type | Properties | Description 
--- | --- | --- | ---
Id | INT | PRIMARY KEY AUTO_INCREMENT | Идентификатор
Name | VARCHAR(500) | UNIQUE NOT NULL | Наименование
Description | VARCHAR(1000) | |  Описание
Address | VARCHAR(1000) | NOT NULL | Адрес
EMail | VARCHAR(50) | NOT NULL | e-mail
Phone | VARCHAR(50) | NOT NULL | Телефон

### **ProductVendor** - Связь товаров с постовщиками
Field | Type | Properties | Description 
--- | --- | --- | ---
VendorId  | INT | NOT NULL | Указатель на постовщика
ProductId | INT | NOT NULL | Указатель на товар

### **ProductCost** - Стоимость товаров
Field | Type | Properties | Description 
--- | --- | --- | ---
ProductId | INT | NOT NULL | Указатель на товар
VendorId  | INT | NOT NULL | Указатель на постовщика
FromDate  | DATETIME | NOT NULL | Момент времени, с которого действует цена
UnitCost  | NUMERIC(13,2) || Цена

### **ProductBin** - Размещение товара на складе
Field | Type | Properties | Description 
--- | --- | --- | ---
ProductId | INT | NOT NULL | Указатель на товар
VendorId | INT | NOT NULL | Указатель на поставщика
BinId | INT | NOT NULL | Указатель на ячейку товара
ProductCount | INT | | Количество данного товара в ячейке

### **Customer** - Данные покупателей
Field | Type | Properties | Description 
--- | --- | --- | ---
Id | INT | PRIMARY KEY AUTO_INCREMENT | Идентификатор
FullName | VARCHAR(500) | NOT NULL | Полное имя
FirstName | VARCHAR(100) | NOT NULL | Фамилия
LastName | VARCHAR(400) | NOT NULL | Имя
Address | VARCHAR(1000) || Адрес
EMail | VARCHAR(50) | UNIQUE NOT NULL | E-mail
Phone | VARCHAR(50) | NOT NULL | Телефон
DiscountPercent | SMALLINT | UNSIGNED CHECK (Discount >= 0 AND Discount <= 25) | Личная скидка покупателя 

### **SalesOrder** - Заказы
Field | Type | Properties | Description 
--- | --- | --- | ---
Id | INT | PRIMARY KEY AUTO_INCREMENT | Идентификатор 
OrderNumber | VARCHAR(16)| UNIQUE NOT NULL | Номер заказа
OrderDate | DATETIME | | Дата и время заказа
OrderStatus | ENUM('Новый', 'Подтвержден', 'Оплачен', 'Доставлен', 'Отменен') | default 'Новый' | Статус заказа
CustomerId | INT | NOT NULL | | Указатель на покупателя
WarehouseId | INT | | Указатель на магазин, если доставка осуществляется в пункт самовывоза
NeedDelivery | BOOLEAN | |  Флаг, требуется ли доставка к клиету
DeliveryDate | DATE | | Запланированая дата доставки   
DeliveryTimeInterval | ENUM ('10:00-14:00','14:00-18:00','18:00-22:00') || Временной интервал доставки
DeliveryCost | NUMERIC(13,2) | | Стоимость доставки
Price | NUMERIC(15,2) | | Общая стоимость товаров в заказе
Total | NUMERIC(15,2) | | Общая сумма заказа для оплаты клиентом 
PromocodeId | SMALLINT | | Указатель на Прококод
 
### **OrderDtl** - детали заказа
Field | Type | Properties | Description 
--- | --- | --- | ---
SalesOrderId | INT | NOT NULL | Указатель на заказ
OrderLine | INT | NOT NULL | Единица закада
ProductId | INT | NOT NULL | Указатель на продукт
VendorId | INT | NOT NULL | Указатель на поставщика
UnitCost | NUMERIC(13,2) | | Цена , выбранного товара. Фиксируется после смены статуса заказа на 'Подтвержден'. До фиксации значение остается равным 0, и берется из таблицы ProductCost, излишних пересчетов.
ProductCount | SMALLINT | NOT NULL | CHECK( ProductCount > 0) | Количество товара в заказе.
DiscountPercent | SMALLINT | CHECK (DiscountPercent >= 0 AND DiscountPercent <= 100) | Скидка расчитывается согласно выбранному промокоду и личной скидки клиента 
Price | NUMERIC(13,2) | | Суммарная цена товара, учитывая скидку.

### **Promocode** - промокоды
Field | Type | Properties | Description 
--- | --- | --- | ---
Id | INT | PRIMARY KEY AUTO_INCREMENT | Идентификатор 
Promocode | VARCHAR(8) | NOT NULL | Прококод
FromDate | DATETIME | NOT NULL | Момент времени с которого промокод действителен
ToDate | DATETIME | NOT NULL | Момент времени до которого промокод действителен
DiscountPercent | TINYINT | UNSIGNED CHECK (Discount >= 0 AND Discount <= 100) | Скидка 

### **ShipHdr** - Накладная доставки
Field | Type | Properties | Description 
--- | --- | --- | ---
Id | INT | PRIMARY KEY AUTO_INCREMENT | Идентификатор 
ShipNumber | VARCHAR(16)| UNIQUE NOT NULL | Номер накладной
ShipDate | DATETIME | NOT NULL | Дата доставки
FromWarehouseId | INT | NOT NULL | Указатель на склад с какого осуществляется доставка
Status | ENUM {'В сборке', 'В пути', 'Доставлен' } | default 'В сборке' | Статус доставки

### **ShipDtl** - детали доставки
Field | Type | Properties | Description 
--- | --- | --- | ---
ShipHdrId | INT | NOT NULL | Указатель на накладную доставки
ShipDtlLine | INT | NOT NULL | Номер позиции в накладной
FromBinId | INT | NOT NULL | Указатель ячейки , откуда товар нужно забрать
ProductId | INT | NOT NULL | Указатель на товар
VendorId  | INT | NOT NULL | Указатель на поставщика
SalesOrderId | INT | | Указатель на заказ. Вносится, если доставка осуществляется клиенту
OrderLine | INT | | Указатель на позицию заказа. Вносится, если доставка осуществляется клиенту
ToBinId | INT | | Указатель на ячейку  на складе. Вносится, если доставка осуществляется на другой склад 
ProductCount | INT | | Количество товара в позиции
Status | ENUM {'В сборке', 'В пути', 'Доставлен' } | default 'В сборке' | Статус позиции

---

# ИНДЕКСЫ
### **City**
PRIMARY KEY (id)

### **Warehouse**
PRIMARY KEY (id)

INDEX idx_warehouse_city (cityid)

FOREIGN KEY fk_warehouse_city (cityid) REFERENCES city (id)

### **WarehouseBin**
PRIMARY KEY (id)

INDEX idx_warehousebin_warehouse (warehouseid)

FOREIGN KEY fk_warehousebin_warehouse (warehouseid) REFERENCES warehouse (id)

### **Category**
PRIMARY KEY (id)

INDEX idx_Category_Name (name)

FOREIGN KEY fk_parent_category (parentid) REFERENCES category (id)

### **ProductType**
PRIMARY KEY (id)

### **ProductTypeCategory**
PRIMARY KEY (categoryid, producttypeid )

FOREIGN KEY fk_ProductTypeCategory_Category (categoryid) REFERENCES Category (id),

FOREIGN KEY fk_ProductTypeCategory_ProductType (producttypeid) REFERENCES ProductType (id)

### **Color**
PRIMARY KEY (id)

### **ProductSize**
PRIMARY KEY (id)

### **Product**
PRIMARY KEY (id)

INDEX idx_Product_Name (Name)

INDEX idx_specification USING GIN (specifications jsonb_path_ops)

INDEX idx_product_desc USING GIN (to_tsvector('russian', description));

FOREIGN KEY fk_Product_ProductType (producttypeid) REFERENCES ProductType (id),

FOREIGN KEY fk_Product_Color (colorid) REFERENCES Color (id),

FOREIGN KEY fk_Product_ProductSize (productsizeid) REFERENCES ProductSize (id)

### **ProductCategory**
PRIMARY KEY (categoryId, productId )

FOREIGN KEY fk_ProductCategory_Category (categoryid) REFERENCES Category (id),

FOREIGN KEY fk_ProductCategory_Product (productid) REFERENCES Product (id)
### **Vendor**
PRIMARY KEY (id)

### **ProductVendor**
PRIMARY KEY (vendorid, productid )

FOREIGN KEY fk_ProductVendor_Vendor (vendorid) REFERENCES Vendor (id)

FOREIGN KEY fk_ProductVendor_Product FOREIGN KEY (productid) REFERENCES Product (id)
### **ProductCost**
PRIMARY KEY (vendorid, productid, fromdate)

FOREIGN KEY fk_ProductVendor_ProductVendor (vendorid, productid) REFERENCES ProductVendor (vendorid, productid)

### **ProductBin**
PRIMARY KEY (productid, vendorid, binid)

FOREIGN KEY fk_ProductBin_WarehouseBin FOREIGN KEY (binid) REFERENCES WarehouseBin (id)

FOREIGN KEY fk_ProductBin_ProductVendor (vendorid, productid) REFERENCES ProductVendor (vendorid, productid)

### **Customer**
PRIMARY KEY (id)

INDEX idx_Customer_FullName (fullname)

### **SalesOrder**
PRIMARY KEY (id)

INDEX idx_SalesOrder_OrderNumber (ordernamber)

INDEX idx_SalesOrder_OrderDate (orderdate)

FOREIGN KEY fk_SalesOrder_Customer (customerid) REFERENCES Customer (id)

### **OrderDtl**
PRIMARY KEY (salesorderid, orderline) 

INDEX idx_orderdtl_productvendor (productid, vendorid)

FOREIGN KEY fk_OrderDtl_SalesOrder (salesorderid) REFERENCES SalesOrder (id) ON DELETE CASCADE,

FOREIGN KEY fk_OrderDtl_ProductVendor (vendorid, productid) REFERENCES ProductVendor (vendorid,productid) 

### **Promocode**
PRIMARY KEY (id)

### **ShipHdr**
PRIMARY KEY (id)

INDEX idx_shiphdr_date (shipdate)

### **ShipDtl**
PRIMARY KEY (shiphdrid, shipdtlline) 

INDEX idx_shipdtl_productbin (vendorid, productid, frombinid);

FOREIGN KEY fk_ShipDtl_ProductBin (vendorid, productid, frombinid) REFERENCES ProductBin (vendorid, productid, binid)
 
---



