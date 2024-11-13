CREATE DATABASE AMessyBigCO;
GO

USE AMessyBigCO;
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

-- Create table HR.Companies
CREATE TABLE HR.Companies (
    companyId INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    contactName VARCHAR(100),
    contactTitle VARCHAR(100)
);

-- Create table Info.Addresses
CREATE TABLE Info.Addresses (
    addressId INT PRIMARY KEY,
    address VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    region VARCHAR(100),
    postalCode VARCHAR(20),
    county VARCHAR(100) NOT NULL
);

-- Create table Info.Contacts
CREATE TABLE Info.Contacts (
    contactId INT PRIMARY KEY,
    phone VARCHAR(20) NOT NULL,
    fax VARCHAR(20)
);

-- Create table HR.Employees
CREATE TABLE HR.Employees (
  employeeId INT PRIMARY KEY,
  lastName VARCHAR(20) NOT NULL,
  firstName VARCHAR(10) NOT NULL,
  title VARCHAR(30) NOT NULL,
  courtesyTitle VARCHAR(25) NOT NULL,
  birthdate DATETIME NOT NULL,
  hiredate DATETIME NOT NULL,
  companyId INT,
  addressId INT NOT NULL,
  contactId INT NOT NULL,
  FOREIGN KEY (companyId) REFERENCES HR.Companies(companyId),
  FOREIGN KEY (addressId) REFERENCES Info.Addresses(addressId),
  FOREIGN KEY (contactId) REFERENCES Info.Contacts(contactId),
  CONSTRAINT CHK_birthdate CHECK(birthdate <= CURRENT_TIMESTAMP)
);

CREATE NONCLUSTERED INDEX idx_nc_lastname ON HR.Employees(lastname);

-- Create table Production.Suppliers
CREATE TABLE Production.Suppliers (
    supplierId INT PRIMARY KEY,
    companyId INT NOT NULL,
    addressId INT NOT NULL,
    contactId INT NOT NULL,
    FOREIGN KEY (companyId) REFERENCES HR.Companies(companyId),
    FOREIGN KEY (addressId) REFERENCES Info.Addresses(addressId),
    FOREIGN KEY (contactId) REFERENCES Info.Contacts(contactId)
);

-- Create table Production.Categories
CREATE TABLE Production.Categories (
    categoryId INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT
);

CREATE INDEX name ON Production.Categories(name);

-- Create table Production.Products
CREATE TABLE Production.Products (
    productId INT PRIMARY KEY,
    description VARCHAR(40),
    price DECIMAL(10,2) NOT NULL CONSTRAINT DFT_Products_unitprice DEFAULT(0),
    discontinued BIT NOT NULL CONSTRAINT DFT_Products_discontinued DEFAULT(0),
    supplierId INT NOT NULL,
    categoryId INT NOT NULL,
    FOREIGN KEY (supplierId) REFERENCES Production.Suppliers(supplierId),
    FOREIGN KEY (categoryId) REFERENCES Production.Categories(categoryId),
    CONSTRAINT CHK_Products_unitprice CHECK(price >= 0)
);

CREATE NONCLUSTERED INDEX idx_nc_categoryid  ON Production.Products(categoryid);
CREATE NONCLUSTERED INDEX idx_nc_productname ON Production.Products(description);
CREATE NONCLUSTERED INDEX idx_nc_supplierid  ON Production.Products(supplierid);

-- Create table Sales.B2BCustomers
CREATE TABLE Sales.B2BCustomers (
    customerId INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    frequent BIT DEFAULT 0,
    companyId INT,
    addressId INT NOT NULL,
    contactId INT NOT NULL,
    FOREIGN KEY (companyId) REFERENCES HR.Companies(companyId),
    FOREIGN KEY (addressId) REFERENCES Info.Addresses(addressId),
    FOREIGN KEY (contactId) REFERENCES Info.Contacts(contactId)
);

-- Create table Sales.B2CCustomers
CREATE TABLE Sales.B2CCustomers (
    customerId INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    frequent BIT DEFAULT 0,
    companyId INT,
    addressId INT NOT NULL,
    contactId INT NOT NULL,
    FOREIGN KEY (companyId) REFERENCES HR.Companies(companyId),
    FOREIGN KEY (addressId) REFERENCES Info.Addresses(addressId),
    FOREIGN KEY (contactId) REFERENCES Info.Contacts(contactId)
);

-- Create table Sales.Shippers
CREATE TABLE Sales.Shippers (
    shipperId INT PRIMARY KEY,
    companyId INT NOT NULL,
    contactId INT NOT NULL,
    FOREIGN KEY (companyId) REFERENCES HR.Companies(companyId),
    FOREIGN KEY (contactId) REFERENCES Info.Contacts(contactId)
);

-- Create table Sales.PromoCode
CREATE TABLE Sales.PromoCode (
    promoCodeId INT PRIMARY KEY,
    discountPc DECIMAL(5,2),
    discountAbs DECIMAL(10,2),
    code VARCHAR(50) NOT NULL UNIQUE,
    CONSTRAINT chk_discount 
    CHECK ((discountPc IS NULL AND discountAbs IS NOT NULL) 
    OR (discountPc IS NOT NULL AND discountAbs IS NULL))
);

-- Create table Sales.B2COrders (Business to Consumer)
CREATE TABLE Sales.B2COrders (
    orderId INT PRIMARY KEY,
    date DATE NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    total DECIMAL(10,2) NOT NULL,
    customerId INT NOT NULL,
    promoCodeId INT,
    FOREIGN KEY (customerId) REFERENCES Sales.Customers(customerId),
    FOREIGN KEY (promoCodeId) REFERENCES Sales.PromoCode(promoCodeId)
);

-- Create table Sales.B2BOrders (Business to Business)
CREATE TABLE Sales.B2BOrders (
    orderId INT PRIMARY KEY,
    requiredDate DATE NOT NULL,
    shippedDate DATE,
    freight DECIMAL(10,2),
    shipName VARCHAR(100),
    customerId INT NOT NULL,
    employeeId INT NOT NULL,
    shipAddressId INT NOT NULL,
    shipperId INT NOT NULL,
    FOREIGN KEY (customerId) REFERENCES Sales.Customers(customerId),
    FOREIGN KEY (shipAddressId) REFERENCES Info.Addresses(addressId),
    FOREIGN KEY (shipperId) REFERENCES Sales.Shippers(shipperId),
    CONSTRAINT chk_dates CHECK (CURRENT_TIMESTAMP <= requireddate AND (shippeddate IS NULL OR shippeddate >= CURRENT_TIMESTAMP))
);

-- Create table Sales.B2BOrderDetails
CREATE TABLE Sales.B2BOrderDetails (
    qty INT NOT NULL CHECK (qty > 0),
    orderId INT PRIMARY KEY,
    productId INT NOT NULL,
    FOREIGN KEY (orderId) REFERENCES Sales.B2BOrders(orderId),
    FOREIGN KEY (productId) REFERENCES Production.Products(productId),
    CONSTRAINT CHK_qty  CHECK (qty > 0)
);

CREATE NONCLUSTERED INDEX idx_nc_orderid   ON Sales.B2BOrderDetails(orderId);
CREATE NONCLUSTERED INDEX idx_nc_productid ON Sales.B2BOrderDetails(productid);

-- Create table Sales.B2COrderDetails
CREATE TABLE Sales.B2COrderDetails (
    qty INT NOT NULL CHECK (qty > 0),
    orderId INT PRIMARY KEY,
    productId INT NOT NULL,
    FOREIGN KEY (orderId) REFERENCES Sales.B2COrders(orderId),
    FOREIGN KEY (productId) REFERENCES Production.Products(productId),
    CONSTRAINT CHK_qty  CHECK (qty > 0)
);

CREATE NONCLUSTERED INDEX idx_nc_orderid   ON Sales.B2COrderDetails(orderId);
CREATE NONCLUSTERED INDEX idx_nc_productid ON Sales.B2COrderDetails(productid);

-- Create table Info.Tag
CREATE TABLE Info.Tag (
    tagId INT PRIMARY KEY,
    tagName VARCHAR(50) NOT NULL,
    productId INT NOT NULL,
    FOREIGN KEY (productId) REFERENCES Production.Products(productId)
);
