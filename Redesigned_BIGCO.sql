CREATE DATABASE NBIGCO;
GO

USE NBIGCO;
GO

CREATE SCHEMA HR AUTHORIZATION dbo;
GO
CREATE SCHEMA Production AUTHORIZATION dbo;
GO
CREATE SCHEMA Sales AUTHORIZATION dbo;
GO
CREATE SCHEMA Info AUTHORIZATION dbo;
GO

---------------------------------------------------------------------
-- Create Tables
---------------------------------------------------------------------

-- Info Tables Creation
-- Addresses Table
CREATE TABLE Info.Addresses (
    addressId INT NOT NULL PRIMARY KEY IDENTITY,
    address VARCHAR(100) NOT NULL DEFAULT '',
    city VARCHAR(50) NOT NULL DEFAULT '',
    region VARCHAR(50) NOT NULL DEFAULT '',
    postalCode VARCHAR(15) NOT NULL DEFAULT '',
    country VARCHAR(50) NOT NULL DEFAULT ''
);

-- Phones Table
CREATE TABLE Info.Phones (
    phoneId INT NOT NULL PRIMARY KEY IDENTITY,
    phone VARCHAR(30) NOT NULL DEFAULT '0000000000',
    fax VARCHAR(30) NOT NULL DEFAULT '0000000000'
);

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
    addressId INT NOT NULL,
    phoneId INT NOT NULL,
    FOREIGN KEY (addressId) REFERENCES Info.Addresses(addressId),
    FOREIGN KEY (phoneId) REFERENCES Info.Phones(phoneId),
    CONSTRAINT CHK_birthdate CHECK(birthdate <= CURRENT_TIMESTAMP),
);

-- Production Tables Creation
-- Companies Table
CREATE TABLE Production.Companies (
    companyId INT NOT NULL PRIMARY KEY IDENTITY,
    name VARCHAR(40) NOT NULL DEFAULT '',
    contactName VARCHAR(30) NOT NULL DEFAULT '',
    contactTitle VARCHAR(30) NOT NULL DEFAULT '',
)

-- Categories Table
CREATE TABLE Production.Categories (
    categoryId INT NOT NULL PRIMARY KEY IDENTITY,
    name VARCHAR(40) NOT NULL DEFAULT '',
    description VARCHAR(100) NOT NULL DEFAULT '',
);

-- Shippers Table
CREATE TABLE Production.Shippers (
    shipperId INT NOT NULL PRIMARY KEY IDENTITY,
    companyID INT NOT NULL,
    phoneId INT NOT NULL,
    FOREIGN KEY (companyID) REFERENCES Production.Companies(companyId),
    FOREIGN KEY (phoneId) REFERENCES Info.Phones(phoneId),
);

-- Suppliers Table
CREATE TABLE Production.Suppliers (
    supplierId INT NOT NULL PRIMARY KEY IDENTITY,
    companyID INT NOT NULL,
    addressId INT NOT NULL,
    phoneId INT NOT NULL,
    FOREIGN KEY (companyID) REFERENCES Production.Companies(companyId),
    FOREIGN KEY (addressId) REFERENCES Info.Addresses(addressId),
    FOREIGN KEY (phoneId) REFERENCES Info.Phones(phoneId),
);

-- Products Table
CREATE TABLE Production.Products (
    productId INT NOT NULL PRIMARY KEY IDENTITY,
    name VARCHAR(100) NOT NULL DEFAULT '',
    price MONEY NOT NULL DEFAULT 0.00,
    discontinued BIT NOT NULL DEFAULT 0,
    supplierId INT NOT NULL,
    categoryId INT NOT NULL,
    FOREIGN KEY (supplierId) REFERENCES Production.Suppliers(supplierId),
    FOREIGN KEY (categoryId) REFERENCES Production.Categories(categoryId),
);

-- Sales Tables Creation
-- Customers Table
CREATE TABLE Sales.Customers (
    customerId INT NOT NULL PRIMARY KEY IDENTITY,
    companyId INT NOT NULL,
    addressId INT NOT NULL,
    phoneId INT NOT NULL,
    FOREIGN KEY (companyId) REFERENCES Production.Companies(companyId),
    FOREIGN KEY (addressId) REFERENCES Info.Addresses(addressId),
    FOREIGN KEY (phoneId) REFERENCES Info.Phones(phoneId),
);



-- Orders Table
CREATE TABLE Sales.Orders (
    orderId INT NOT NULL PRIMARY KEY IDENTITY,
    date DATETIME NOT NULL DEFAULT GETDATE(),
    requiredDate DATETIME NOT NULL DEFAULT GETDATE(),
    shippedDate DATETIME NOT NULL DEFAULT GETDATE(),
    freight MONEY NOT NULL DEFAULT 0.00,
    shipname VARCHAR(50) NOT NULL DEFAULT '',
    customerId INT NOT NULL,
    employeeId INT NOT NULL,
    shipAddressId INT NOT NULL,
    shipperId INT NOT NULL,
    FOREIGN KEY (customerId) REFERENCES Sales.Customers(customerId),
    FOREIGN KEY (employeeId) REFERENCES HR.Employees(employeeId),
    FOREIGN KEY (shipAddressId) REFERENCES Info.Addresses(addressId),
    FOREIGN KEY (shipperId) REFERENCES Production.Shippers(shipperId),
);

-- OrderDetails Table
CREATE TABLE Sales.OrderDetails (
    orderDetailId INT NOT NULL PRIMARY KEY IDENTITY,
    qty INT NOT NULL DEFAULT 0,
    discount MONEY NOT NULL DEFAULT 0.00,
    orderId INT NOT NULL,
    productId INT NOT NULL,
    FOREIGN KEY (orderId) REFERENCES Sales.Orders(orderId),
    FOREIGN KEY (productId) REFERENCES Production.Products(productId),
);

--- Data insertion
-- Info Data Insertion
-- Addresses Data Insertion
INSERT INTO Info.Addresses (address, city, region, postalCode, country)
SELECT DISTINCT address, city, region, postalCode, country
FROM BIGCO.HR.Employees emp
UNION
SELECT DISTINCT sp.address, sp.city, sp.region, sp.postalCode, sp.country
FROM BIGCO.Production.Suppliers sp
UNION
SELECT DISTINCT ord.shipaddress, ord.shipcity, ord.shipregion, ord.shippostalcode, ord.shipcountry
FROM BIGCO.Sales.Orders ord
UNION
SELECT cs.address, cs.city, cs.region, cs.postalCode, cs.country
FROM BIGCO.Sales.Customers cs;

-- Phones Data Insertion
INSERT INTO Info.Phones (phone, fax)
SELECT DISTINCT emp.phone, '0000000000' as fax
FROM BIGCO.HR.Employees emp
UNION
SELECT DISTINCT sp.phone, sp.fax
FROM BIGCO.Production.Suppliers sp
UNION
SELECT DISTINCT cs.phone, cs.fax
FROM BIGCO.Sales.Customers cs
UNION
SELECT sh.phone, '0000000000' as fax
FROM BIGCO.Sales.Shippers sh;

-- HR Data Insertion
-- Employees Data Insertion
INSERT INTO HR.Employees (lastname, firstname, title, courtesyTitle, birthDate, hireDate, addressId, phoneId)
SELECT DISTINCT emp.lastname, emp.firstname, emp.title, emp.titleofcourtesy, emp.birthDate, emp.hireDate, adr.addressId, ph.phoneId
FROM BIGCO.HR.Employees emp
JOIN Info.Addresses adr ON emp.address = adr.address AND emp.city = adr.city AND emp.region = adr.region AND emp.postalCode = adr.postalCode AND emp.country = adr.country
JOIN Info.Phones ph ON emp.phone = ph.phone AND ph.fax = '0000000000';

-- Production Data Insertion
-- Companies Data Insertion
INSERT INTO Production.Companies (name, contactName, contactTitle)
SELECT DISTINCT sup.companyname, sup.contactname, sup.contacttitle
FROM BIGCO.Production.Suppliers sup
UNION
SELECT DISTINCT cs.companyname, cs.contactname, cs.contacttitle
FROM BIGCO.Sales.Customers cs
UNION
SELECT DISTINCT sh.companyname, '', ''
FROM BIGCO.Sales.Shippers sh;

-- Categories Data Insertion
INSERT INTO Production.Categories (name, description)
SELECT DISTINCT cat.categoryname, cat.description
FROM BIGCO.Production.Categories cat;

-- Shippers Data Insertion
INSERT INTO Production.Shippers (companyID, phoneId)
SELECT DISTINCT comp.companyId, ph.phoneId
FROM BIGCO.Sales.Shippers sh
JOIN Production.Companies comp ON sh.companyname = comp.name AND comp.contactName = '' AND comp.contactTitle = ''
JOIN Info.Phones ph ON sh.phone = ph.phone AND ph.fax = '0000000000';

-- Suppliers Data Insertion
INSERT INTO Production.Suppliers (companyID, addressId, phoneId)
SELECT DISTINCT comp.companyId, adr.addressId, ph.phoneId
FROM BIGCO.Production.Suppliers sup
JOIN Production.Companies comp ON sup.companyname = comp.name AND comp.contactName = sup.contactname AND comp.contactTitle = sup.contacttitle
JOIN Info.Addresses adr ON sup.address = adr.address AND sup.city = adr.city AND sup.region = adr.region AND sup.postalCode = adr.postalCode AND sup.country = adr.country
JOIN Info.Phones ph ON sup.phone = ph.phone AND ph.fax = sup.fax;

-- Products Data Insertion
INSERT INTO Production.Products (name, price, discontinued, supplierId, categoryId)
SELECT DISTINCT prod.productname, prod.unitprice, prod.discontinued, sup.supplierId, cat.categoryId
FROM BIGCO.Production.Products prod
JOIN Production.Suppliers sup ON prod.supplierID = sup.supplierID
JOIN Production.Categories cat ON prod.categoryID = cat.categoryID;

-- Customers Data Insertion
INSERT INTO Sales.Customers (companyId, addressId, phoneId)
SELECT DISTINCT comp.companyId, adr.addressId, ph.phoneId
FROM BIGCO.Sales.Customers cs
JOIN Production.Companies comp ON cs.companyname = comp.name AND comp.contactName = cs.contactname AND comp.contactTitle = cs.contacttitle
JOIN Info.Addresses adr ON cs.address = adr.address AND cs.city = adr.city AND cs.region = adr.region AND cs.postalCode = adr.postalCode AND cs.country = adr.country
JOIN Info.Phones ph ON cs.phone = ph.phone AND ph.fax = cs.fax;

-- Orders Data Insertion
INSERT INTO Sales.Orders (date, requiredDate, shippedDate, freight, shipname, customerId, employeeId, shipAddressId, shipperId)
SELECT DISTINCT ord.orderdate, ord.requireddate, ord.shippeddate, ord.freight, ord.shipname, cs.customerId, emp.employeeId, adr.addressId, sh.shipperId
FROM BIGCO.Sales.Orders ord
JOIN Sales.Customers cs ON ord.custid = cs.customerID
JOIN BIGCO.HR.Employees bemp ON ord.empid = bemp.empid
JOIN HR.Employees emp ON bemp.lastname = emp.lastname AND bemp.firstname = emp.firstname AND bemp.title = emp.title
JOIN Info.Addresses adr ON ord.shipaddress = adr.address AND ord.shipcity = adr.city AND ord.shipregion = adr.region AND ord.shippostalcode = adr.postalCode AND ord.shipcountry = adr.country
JOIN BIGCO.Sales.Shippers bsh ON ord.shipperid = bsh.shipperid
JOIN Production.Shippers sh ON bsh.shipperid = sh.shipperId;

-- OrderDetails Data Insertion
INSERT INTO Sales.OrderDetails (qty, discount, orderId, productId)
SELECT DISTINCT ord.qty, ord.discount, ord.orderid, prod.productid
FROM BIGCO.Sales.OrderDetails ord
JOIN Production.Products prod ON ord.productid = prod.productid;