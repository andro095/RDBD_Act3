CREATE DATABASE AmalgamatedBIGCO;
GO

USE AmalgamatedBIGCO;
GO

CREATE SCHEMA HR AUTHORIZATION dbo;
GO
CREATE SCHEMA Production AUTHORIZATION dbo;
GO
CREATE SCHEMA Sales AUTHORIZATION dbo;
GO

-- ---------------------------------------------------------------------
-- -- Create Tables
-- ---------------------------------------------------------------------

-- HR Tables Creation
-- Employee Table
CREATE TABLE HR.Employees (
    employeeId INT NOT NULL PRIMARY KEY IDENTITY,
    lastname VARCHAR(50) NOT NULL DEFAULT '',
    firstname VARCHAR(50) NOT NULL DEFAULT '',
    title VARCHAR(50) NOT NULL DEFAULT '',
    courtesyTitle VARCHAR(50) NOT NULL DEFAULT '',
    birthDate DATETIME NOT NULL DEFAULT '1900-01-01 00:00:00',
    hireDate DATETIME NOT NULL DEFAULT '1900-01-01 00:00:00',
    address VARCHAR(50) NOT NULL DEFAULT '',
    city VARCHAR(50) NOT NULL DEFAULT '',
    region VARCHAR(50) NOT NULL DEFAULT '',
    postalCode VARCHAR(50) NOT NULL DEFAULT '',
    country VARCHAR(50) NOT NULL DEFAULT '',
    phone VARCHAR(50) NOT NULL DEFAULT '',
    managerId INT NULL,
    CONSTRAINT CHK_birthdate CHECK(birthdate <= CURRENT_TIMESTAMP),
    CONSTRAINT CHK_hiredate CHECK(hiredate <= CURRENT_TIMESTAMP),
    CONSTRAINT FK_Employees_Manager FOREIGN KEY (managerId) REFERENCES HR.Employees(employeeId)
);

CREATE NONCLUSTERED INDEX IDX_lastname   ON HR.Employees(lastname);
CREATE NONCLUSTERED INDEX IDX_postalcode ON HR.Employees(postalcode);

-- Production Tables Creation
-- Suppliers Table
CREATE TABLE Production.Suppliers (
    supplierId INT NOT NULL PRIMARY KEY IDENTITY,
    companyName VARCHAR(50) NOT NULL DEFAULT '',
    contactName VARCHAR(50) NOT NULL DEFAULT '',
    contactTitle VARCHAR(50) NOT NULL DEFAULT '',
    address VARCHAR(50) NOT NULL DEFAULT '',
    city VARCHAR(50) NOT NULL DEFAULT '',
    region VARCHAR(50) NOT NULL DEFAULT '',
    postalCode VARCHAR(50) NOT NULL DEFAULT '',
    country VARCHAR(50) NOT NULL DEFAULT '',
    phone VARCHAR(50) NOT NULL DEFAULT '',
    fax VARCHAR(50) NOT NULL DEFAULT '',
);

CREATE NONCLUSTERED INDEX IDX_companyname ON Production.Suppliers(companyname);
CREATE NONCLUSTERED INDEX IDX_postalcode ON Production.Suppliers(postalcode);

-- Categories Table
CREATE TABLE Production.Categories (
    categoryId INT NOT NULL PRIMARY KEY IDENTITY,
    name VARCHAR(100) NOT NULL DEFAULT '',
    description VARCHAR(100) NOT NULL DEFAULT '',
);

CREATE INDEX IDX_categoryName ON Production.Categories(name);

-- Products Table
CREATE TABLE Production.Products (
    productId INT NOT NULL PRIMARY KEY IDENTITY,
    name VARCHAR(50) NOT NULL DEFAULT '',
    unitPrice DECIMAL(18, 2) NOT NULL DEFAULT 0.00,
    discontinued BIT NOT NULL DEFAULT 0,
    supplierId INT NOT NULL,
    categoryId INT NOT NULL,
    CONSTRAINT FK_Products_Supplier FOREIGN KEY (supplierId) REFERENCES Production.Suppliers(supplierId),
    CONSTRAINT FK_Products_Category FOREIGN KEY (categoryId) REFERENCES Production.Categories(categoryId),
    CONSTRAINT CHK_unitPrice CHECK(unitPrice >= 0)
);

CREATE NONCLUSTERED INDEX IDX_categoryid ON Production.Products(categoryid);
CREATE NONCLUSTERED INDEX IDX_productname ON Production.Products(name);
CREATE NONCLUSTERED INDEX IDX_supplierid ON Production.Products(supplierid);

-- Tags Table
CREATE TABLE Production.Tags (
    tagId INT NOT NULL PRIMARY KEY IDENTITY,
    name VARCHAR(50) NOT NULL DEFAULT '',
    productId INT NOT NULL,
    CONSTRAINT FK_Tags_Product FOREIGN KEY (productId) REFERENCES Production.Products(productId)
);

CREATE NONCLUSTERED INDEX IDX_tagname ON Production.Tags(name);

-- Sales Tables Creation
-- Customers Table
CREATE TABLE Sales.Customers (
    customerId INT NOT NULL PRIMARY KEY IDENTITY,
    customerType VARCHAR(20) NOT NULL DEFAULT '',
    companyName VARCHAR(50) NOT NULL DEFAULT '',
    contactName VARCHAR(50) NOT NULL DEFAULT '',
    contactTitle VARCHAR(50) NOT NULL DEFAULT '',
    address VARCHAR(50) NOT NULL DEFAULT '',
    city VARCHAR(50) NOT NULL DEFAULT '',
    region VARCHAR(50) NOT NULL DEFAULT '',
    postalCode VARCHAR(50) NOT NULL DEFAULT '',
    country VARCHAR(50) NOT NULL DEFAULT '',
    phone VARCHAR(50) NOT NULL DEFAULT '',
    fax VARCHAR(50) NOT NULL DEFAULT '',
    email VARCHAR(50) NOT NULL DEFAULT '',
    frequentBuyer BIT NOT NULL DEFAULT 0,
    CONSTRAINT CHK_customerType CHECK(customerType IN ('Individual', 'Company')),
);

CREATE NONCLUSTERED INDEX IDX_city ON Sales.Customers(city);
CREATE NONCLUSTERED INDEX IDX_companyname ON Sales.Customers(companyname);
CREATE NONCLUSTERED INDEX IDX_postalcode ON Sales.Customers(postalcode);
CREATE NONCLUSTERED INDEX IDX_region ON Sales.Customers(region);
CREATE NONCLUSTERED INDEX IDX_customerType ON Sales.Customers(customerType);
CREATE NONCLUSTERED INDEX IDX_frequentBuyer ON Sales.Customers(frequentBuyer);

-- Shippers Table
CREATE TABLE Sales.Shippers (
    shipperId INT NOT NULL PRIMARY KEY IDENTITY,
    name VARCHAR(50) NOT NULL DEFAULT '',
    phone VARCHAR(50) NOT NULL DEFAULT '',
);

CREATE NONCLUSTERED INDEX IDX_shippername ON Sales.Shippers(name);

-- Promo Codes Table
CREATE TABLE Sales.PromoCodes (
    promoCodeId INT NOT NULL PRIMARY KEY IDENTITY,
    code VARCHAR(50) NOT NULL DEFAULT '',
    discountPc DECIMAL(18, 2) NOT NULL DEFAULT 0.00,
    discountAbs DECIMAL(18, 2) NOT NULL DEFAULT 0.00,
);

CREATE NONCLUSTERED INDEX IDX_promocode ON Sales.PromoCodes(code);

-- Orders B2B Table
CREATE TABLE Sales.OrdersB2B (
    orderId INT NOT NULL PRIMARY KEY IDENTITY,
    date DATETIME NOT NULL DEFAULT '1900-01-01 00:00:00',
    requiredDate DATETIME NOT NULL DEFAULT '1900-01-01 00:00:00',
    shippedDate DATETIME NOT NULL DEFAULT '1900-01-01 00:00:00',
    freight DECIMAL(18, 2) NOT NULL DEFAULT 0.00,
    shipName VARCHAR(50) NOT NULL DEFAULT '',
    shipAddress VARCHAR(50) NOT NULL DEFAULT '',
    shipCity VARCHAR(50) NOT NULL DEFAULT '',
    shipRegion VARCHAR(50) NOT NULL DEFAULT '',
    shipPostalCode VARCHAR(50) NOT NULL DEFAULT '',
    shipCountry VARCHAR(50) NOT NULL DEFAULT '',
    subtotal DECIMAL(18, 2) NOT NULL DEFAULT 0.00,
    total DECIMAL(18, 2) NOT NULL DEFAULT 0.00,
    customerId INT NOT NULL,
    employeeId INT NOT NULL,
    shipperId INT NOT NULL,
    promoCodeId INT NULL,
    CONSTRAINT FK_OrdersB2B_Customer FOREIGN KEY (customerId) REFERENCES Sales.Customers(customerId),
    CONSTRAINT FK_OrdersB2B_Employee FOREIGN KEY (employeeId) REFERENCES HR.Employees(employeeId),
    CONSTRAINT FK_OrdersB2B_Shipper FOREIGN KEY (shipperId) REFERENCES Sales.Shippers(shipperId),
    CONSTRAINT FK_OrdersB2B_PromoCode FOREIGN KEY (promoCodeId) REFERENCES Sales.PromoCodes(promoCodeId),
);

CREATE NONCLUSTERED INDEX IDX_custid ON Sales.OrdersB2B(customerId);
CREATE NONCLUSTERED INDEX IDX_empid ON Sales.OrdersB2B(employeeId);
CREATE NONCLUSTERED INDEX IDX_shipperid ON Sales.OrdersB2B(shipperid);
CREATE NONCLUSTERED INDEX IDX_orderdate ON Sales.OrdersB2B(date);
CREATE NONCLUSTERED INDEX IDX_shippeddate ON Sales.OrdersB2B(shippeddate);

-- Order B2C Table
CREATE TABLE Sales.OrdersB2C (
    orderId INT NOT NULL PRIMARY KEY IDENTITY,
    date DATETIME NOT NULL DEFAULT '1900-01-01 00:00:00',
    subtotal DECIMAL(18, 2) NOT NULL DEFAULT 0.00,
    total DECIMAL(18, 2) NOT NULL DEFAULT 0.00,
    customerId INT NULL,
    promoCodeId INT NULL,
    CONSTRAINT FK_OrdersB2C_Customer FOREIGN KEY (customerId) REFERENCES Sales.Customers(customerId),
    CONSTRAINT FK_OrdersB2C_PromoCode FOREIGN KEY (promoCodeId) REFERENCES Sales.PromoCodes(promoCodeId),
);

CREATE NONCLUSTERED INDEX IDX_custid ON Sales.OrdersB2C(customerId);
CREATE NONCLUSTERED INDEX IDX_orderdate ON Sales.OrdersB2C(date);

-- Order Details B2B Table

CREATE TABLE Sales.OrderDetailsB2B (
    orderId INT NOT NULL,
    productId INT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    unitPrice DECIMAL(18, 2) NOT NULL DEFAULT 0.00,
    CONSTRAINT PK_OrderDetailsB2B PRIMARY KEY (orderId, productId),
    CONSTRAINT FK_OrderDetailsB2B_Order FOREIGN KEY (orderId) REFERENCES Sales.OrdersB2B(orderId),
    CONSTRAINT FK_OrderDetailsB2B_Product FOREIGN KEY (productId) REFERENCES Production.Products(productId),
    CONSTRAINT CHK_quantity CHECK(quantity > 0),
    CONSTRAINT CHK_unitPrice CHECK(unitPrice >= 0)
);

CREATE NONCLUSTERED INDEX IDX_orderid ON Sales.OrderDetailsB2B(orderId);
CREATE NONCLUSTERED INDEX IDX_productid ON Sales.OrderDetailsB2B(productId);

-- Order Details B2C Table
CREATE TABLE Sales.OrderDetailsB2C (
    orderId INT NOT NULL,
    productId INT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    unitPrice DECIMAL(18, 2) NOT NULL DEFAULT 0.00,
    CONSTRAINT PK_OrderDetailsB2C PRIMARY KEY (orderId, productId),
    CONSTRAINT FK_OrderDetailsB2C_Order FOREIGN KEY (orderId) REFERENCES Sales.OrdersB2C(orderId),
    CONSTRAINT FK_OrderDetailsB2C_Product FOREIGN KEY (productId) REFERENCES Production.Products(productId),
    CONSTRAINT CHK_quantity_B2C CHECK(quantity > 0),
    CONSTRAINT CHK_unitPrice_B2C CHECK(unitPrice >= 0)
);

CREATE NONCLUSTERED INDEX IDX_orderid ON Sales.OrderDetailsB2C(orderId);
CREATE NONCLUSTERED INDEX IDX_productid ON Sales.OrderDetailsB2C(productId);

-- ---------------------------------------------------------------------
-- -- Data Insertion
-- ---------------------------------------------------------------------
--- HR Data Insertion
-- Insert Employees
INSERT INTO HR.Employees (lastname, firstname, title, courtesyTitle, birthDate, hireDate, address, city, region, postalCode, country, phone, managerId)
SELECT lastname, firstname, title, titleofcourtesy, birthDate, hireDate, address, city, region, postalCode, country, phone, mgrid
FROM BIGCO.HR.Employees;

--- Production Data Insertion
-- Insert Suppliers
INSERT INTO Production.Suppliers (companyName, contactName, contactTitle, address, city, region, postalCode, country, phone, fax)
SELECT companyName, contactName, contactTitle, address, city, region, postalCode, country, phone, fax
FROM BIGCO.Production.Suppliers;

-- Insert Categories
INSERT INTO Production.Categories (name, description)
SELECT categoryname, description
FROM BIGCO.Production.Categories;

-- Insert Products
INSERT INTO Production.Products (name, unitPrice, discontinued, supplierId, categoryId)
SELECT productname, unitprice, discontinued, supplierid, categoryid
FROM BIGCO.Production.Products
UNION
SELECT description, price, 0, 1, 1
FROM NF.Production.Product;

-- Insert Tags
INSERT INTO Production.Tags (name, productId)
SELECT tg.tag, prd.productId
FROM NF.Production.Tag tg
INNER JOIN NF.Production.Product pdt ON tg.productId = pdt.id
INNER JOIN Production.Products prd ON prd.name = pdt.description AND prd.unitPrice = pdt.price;

--- Sales Data Insertion
-- Insert Customers
INSERT INTO Sales.Customers (customerType, companyName, contactName, contactTitle, address, city, region, postalCode, country, phone, fax, email, frequentBuyer)
SELECT 'Company', companyName, contactName, contactTitle, address, city, region, postalCode, country, phone, fax, 'example@gmail.com', 0
FROM BIGCO.Sales.Customers
UNION
SELECT 'Individual', 'Messy', name, 'Mr.', street, city, region, postalCode, 'UK', phone, '1234567890', email, frequent
FROM NF.Sales.Customer;

-- Insert Shippers
INSERT INTO Sales.Shippers (name, phone)
SELECT companyname, phone
FROM BIGCO.Sales.Shippers;

-- Insert Promo Codes
INSERT INTO Sales.PromoCodes (code, discountPc, discountAbs)
SELECT code, discountPc, discountAbs
FROM NF.Sales.PromoCode;


-- Insert Orders B2B
GO;

CREATE VIEW vm_OrderTotals AS
SELECT orderid, (unitprice * qty) AS subtotal, (unitprice * qty * (1 - discount)) AS total
FROM BIGCO.Sales.OrderDetails;

INSERT INTO Sales.OrdersB2B (date, requiredDate, shippedDate, freight, shipName, shipAddress, shipCity, shipRegion, shipPostalCode, shipCountry, subtotal, total, customerId, employeeId, shipperId, promoCodeId)
SELECT ord.orderdate, ord.requireddate, ord.shippeddate, ord.freight, ord.shipname, ord.shipaddress, ord.shipcity, ord.shipregion, ord.shippostalcode, ord.shipcountry, ot.subtotal, ot.total, cust.customerId, ord.empid, ord.shipperid, 1
FROM BIGCO.Sales.Orders ord
INNER JOIN BIGCO.Sales.Customers cst ON ord.custid = cst.custid
INNER JOIN Sales.Customers cust ON cst.companyname = cust.companyname
INNER JOIN vm_OrderTotals ot ON ord.orderid = ot.orderid;

-- Insert Orders B2C
INSERT INTO Sales.OrdersB2C (date, subtotal, total, customerId, promoCodeId)
SELECT ord.date, ord.subTotal, ord.total, cust.customerId, ord.PromoCodeId
FROM NF.Sales.Orders ord
LEFT JOIN NF.Sales.Customer cst ON ord.CustomerId = cst.Id
LEFT JOIN Sales.Customers cust ON cst.name = cust.contactName AND cst.frequent = cust.frequentBuyer;

-- Insert Order Details B2B
INSERT INTO Sales.OrderDetailsB2B (orderId, productId, quantity, unitPrice)
SELECT ordb.orderId, prdt.productId, ordt.qty, ordt.unitprice
FROM BIGCO.Sales.OrderDetails ordt
INNER JOIN BIGCO.Sales.Orders ord ON ordt.orderid = ord.orderid
INNER JOIN Sales.OrdersB2B ordb ON ord.empid = ordb.employeeId AND ord.shipperid = ordb.shipperId
INNER JOIN BIGCO.Production.Products prd ON ordt.productid = prd.productid
INNER JOIN Production.Products prdt ON prd.productname = prdt.name AND prd.unitPrice = prdt.unitPrice;

-- Insert Order Details B2C
INSERT INTO Sales.OrderDetailsB2C (orderId, productId, quantity, unitPrice)
SELECT ordb.orderId, prdt.productId, 1, 0
FROM NF.Sales.OrderDetail ordt
INNER JOIN NF.Sales.Orders ord ON ordt.OrderId = ord.Id
INNER JOIN Sales.OrdersB2C ordb ON ord.Date = ordb.date AND ord.subTotal = ordb.subtotal AND ord.total = ordb.total
INNER JOIN NF.Production.Product prd ON prd.id = ordt.productId
INNER JOIN Production.Products prdt ON prd.description = prdt.name AND prd.price = prdt.unitPrice;
