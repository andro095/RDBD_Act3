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

-- HR.Companies
CREATE TABLE HR.Companies (
    companyId INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(100) NOT NULL,
    contactName VARCHAR(100),
    contactTitle VARCHAR(100)
);

-- Info.Addresses
CREATE TABLE Info.Addresses (
    addressId INT PRIMARY KEY IDENTITY(1,1),
    address VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    region VARCHAR(100),
    postalCode VARCHAR(20),
    county VARCHAR(100) NOT NULL
);

-- Info.Contacts
CREATE TABLE Info.Contacts (
    contactId INT PRIMARY KEY IDENTITY(1,1),
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100) NOT NULL,
    fax VARCHAR(20)
);

-- Production.Categories
CREATE TABLE Production.Categories (
    categoryId INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(100) NOT NULL,
    description TEXT
);

-- HR.Employees
CREATE TABLE HR.Employees (
    employeeId INT PRIMARY KEY IDENTITY(1,1),
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

-- Production.Suppliers
CREATE TABLE Production.Suppliers (
    supplierId INT PRIMARY KEY IDENTITY(1,1),
    companyId INT NOT NULL,
    addressId INT NOT NULL,
    contactId INT NOT NULL,
    FOREIGN KEY (companyId) REFERENCES HR.Companies(companyId),
    FOREIGN KEY (addressId) REFERENCES Info.Addresses(addressId),
    FOREIGN KEY (contactId) REFERENCES Info.Contacts(contactId)
);


-- Production.Products
CREATE TABLE Production.Products (
    productId INT PRIMARY KEY IDENTITY(1,1),
    description VARCHAR(40),
    price DECIMAL(10,2) NOT NULL CONSTRAINT DFT_Products_unitprice DEFAULT(0),
    discontinued BIT NOT NULL CONSTRAINT DFT_Products_discontinued DEFAULT(0),
    supplierId INT NOT NULL,
    categoryId INT NOT NULL,
    FOREIGN KEY (supplierId) REFERENCES Production.Suppliers(supplierId),
    FOREIGN KEY (categoryId) REFERENCES Production.Categories(categoryId),
    CONSTRAINT CHK_Products_unitprice CHECK(price >= 0)
);

-- Sales.B2BCustomers
CREATE TABLE Sales.B2BCustomers (
    customerId INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(100) NOT NULL,
    frequent BIT DEFAULT 0,
    companyId INT,
    addressId INT NOT NULL,
    contactId INT NOT NULL,
    FOREIGN KEY (companyId) REFERENCES HR.Companies(companyId),
    FOREIGN KEY (addressId) REFERENCES Info.Addresses(addressId),
    FOREIGN KEY (contactId) REFERENCES Info.Contacts(contactId)
);

-- Sales.B2CCustomers
CREATE TABLE Sales.B2CCustomers (
    customerId INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(100) NOT NULL,
    frequent BIT DEFAULT 0,
    companyId INT,
    addressId INT NOT NULL,
    contactId INT NOT NULL,
    FOREIGN KEY (companyId) REFERENCES HR.Companies(companyId),
    FOREIGN KEY (addressId) REFERENCES Info.Addresses(addressId),
    FOREIGN KEY (contactId) REFERENCES Info.Contacts(contactId)
);

-- Sales.Shippers
CREATE TABLE Sales.Shippers (
    shipperId INT PRIMARY KEY IDENTITY(1,1),
    companyId INT NOT NULL,
    contactId INT NOT NULL,
    FOREIGN KEY (companyId) REFERENCES HR.Companies(companyId),
    FOREIGN KEY (contactId) REFERENCES Info.Contacts(contactId)
);

-- Sales.PromoCode
CREATE TABLE Sales.PromoCode (
    promoCodeId INT PRIMARY KEY IDENTITY(1,1),
    discountPc DECIMAL(5,2),
    discountAbs DECIMAL(10,2),
    code VARCHAR(50) NOT NULL UNIQUE,
    CONSTRAINT chk_discount 
    CHECK ((discountPc IS NULL AND discountAbs IS NOT NULL) 
    OR (discountPc IS NOT NULL AND discountAbs IS NULL))
);

-- Sales.B2COrders
CREATE TABLE Sales.B2COrders (
    orderId INT PRIMARY KEY IDENTITY(1,1),
    date DATE NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    total DECIMAL(10,2) NOT NULL,
    customerId INT NOT NULL,
    promoCodeId INT,
    FOREIGN KEY (customerId) REFERENCES Sales.B2CCustomers(customerId),
    FOREIGN KEY (promoCodeId) REFERENCES Sales.PromoCode(promoCodeId)
);

-- Sales.B2BOrders
CREATE TABLE Sales.B2BOrders (
    orderId INT PRIMARY KEY IDENTITY(1,1),
    requiredDate DATE NOT NULL,
    shippedDate DATE,
    freight DECIMAL(10,2),
    shipName VARCHAR(100),
    customerId INT NOT NULL,
    employeeId INT NOT NULL,
    shipAddressId INT NOT NULL,
    shipperId INT NOT NULL,
    FOREIGN KEY (customerId) REFERENCES Sales.B2BCustomers(customerId),
    FOREIGN KEY (employeeId) REFERENCES HR.Employees(employeeId),
    FOREIGN KEY (shipAddressId) REFERENCES Info.Addresses(addressId),
    FOREIGN KEY (shipperId) REFERENCES Sales.Shippers(shipperId),
    CONSTRAINT chk_dates CHECK (CURRENT_TIMESTAMP <= requireddate 
        AND (shippeddate IS NULL OR shippeddate >= CURRENT_TIMESTAMP))
);

-- Sales.B2BOrderDetails
CREATE TABLE Sales.B2BOrderDetails (
    orderDetailId INT PRIMARY KEY IDENTITY(1,1),
    qty INT NOT NULL CHECK (qty > 0),
    orderId INT NOT NULL,
    productId INT NOT NULL,
    FOREIGN KEY (orderId) REFERENCES Sales.B2BOrders(orderId),
    FOREIGN KEY (productId) REFERENCES Production.Products(productId)
);

-- Sales.B2COrderDetails
CREATE TABLE Sales.B2COrderDetails (
    orderDetailId INT PRIMARY KEY IDENTITY(1,1),
    qty INT NOT NULL CHECK (qty > 0),
    orderId INT NOT NULL,
    productId INT NOT NULL,
    FOREIGN KEY (orderId) REFERENCES Sales.B2COrders(orderId),
    FOREIGN KEY (productId) REFERENCES Production.Products(productId)
);

-- Info.Tag
CREATE TABLE Info.Tag (
    tagId INT PRIMARY KEY IDENTITY(1,1),
    tagName VARCHAR(50) NOT NULL,
    productId INT NOT NULL,
    FOREIGN KEY (productId) REFERENCES Production.Products(productId)
);

-- Start with HR.Companies (combining BIGCO and Messy companies)
INSERT INTO HR.Companies (companyId, name, contactName, contactTitle)
SELECT name,
       contactName,
       contactTitle
FROM (
    -- Companies from BIGCO
    SELECT DISTINCT name, contactName, contactTitle
    FROM NBIGCO.Production.Companies
    UNION
    -- Companies from Messy (deriving from customer data)
    SELECT DISTINCT 
           c.name,
           NULL as contactName,
           NULL as contactTitle
    FROM NF.Sales.Customer c
) AS CombinedCompanies;

-- Info.Addresses
INSERT INTO Info.Addresses (addressId, address, city, region, postalCode, county)
SELECT address, city, region, postalCode, country
FROM (
    -- Addresses from BIGCO
    SELECT DISTINCT 
           address, city, region, postalCode, country
    FROM NBIGCO.Info.Addresses
    UNION
    -- Addresses from Messy
    SELECT DISTINCT 
           street as address,
           city,
           region,
           postalCode,
           'Unknown' as country
    FROM NF.Sales.Customer
) AS CombinedAddresses;

-- Info.Contacts
INSERT INTO Info.Contacts (contactId, phone, email, fax)
SELECT phone, email, fax
FROM (
    -- Contacts from BIGCO
    SELECT DISTINCT 
        phone, 
        '' as email, 
        fax
    FROM NBIGCO.Info.Phones
    UNION
    -- Contacts from Messy
    SELECT DISTINCT 
           phone,
           email,
           NULL as fax
    FROM NF.Sales.Customer
) AS CombinedContacts;

-- Production.Categories
INSERT INTO Production.Categories (categoryId, name, description)
SELECT name,
       description
FROM (
    -- Categories from BIGCO
    SELECT DISTINCT 
           name,
           description
    FROM NBIGCO.Production.Categories
) AS BIGCOCategories;

-- HR.Employees
INSERT INTO HR.Employees (employeeId,
        lastName,
        firstName,
        title,
        courtesyTitle,
        birthdate,
        hiredate,
        companyId,
        addressId,
        contactId)
SELECT lastName,
       firstName,
       title,
       courtesyTitle,
       birthdate,
       hiredate,
       addressId,
       phoneId
FROM (
    -- HR.Employees from BIGCO
    SELECT DISTINCT 
            lastname,
            firstname,
            title,
            courtesyTitle,
            birthDate,
            hireDate,
            em.addressId,
            phoneId
    FROM NBIGCO.HR.Employees em
    JOIN Info.Addresses a ON a.address = em.addressId
    JOIN Info.Contacts co ON co.contactId = em.phoneId
) AS BIGCOEmployees;

-- Production.Supliers
INSERT INTO Production.Suppliers (supplierId, companyID, addressId, contactId)
SELECT companyId,
       addressId,
       phoneId as contactId
FROM (
    -- Suppliers from BIGCO
    SELECT DISTINCT 
           s.companyID,
           s.addressId,
           s.phoneId
    FROM NBIGCO.Production.Suppliers s
    JOIN HR.Companies co ON co.companyId = s.companyID
    JOIN Info.Addresses a ON a.addressId = s.addressId
    JOIN Info.Contacts c ON c.contactId = s.phoneId
) AS BIGCOSuppliers;

-- Production.Products
INSERT INTO Production.Products (productId, description, price, discontinued, supplierId, categoryId)
SELECT description,
       price,
       discontinued,
       supplierId,
       categoryId
FROM (
    -- Products from BIGCO
    SELECT 
           p.name as description,
           p.price,
           p.discontinued,
           s.supplierId,
           c.categoryId
    FROM NBIGCO.Production.Products p
    JOIN Production.Suppliers s ON p.supplierId = s.supplierId
    JOIN Production.Categories c ON p.categoryId = c.categoryId
    UNION
    -- Products from Messy
    SELECT 
           p.description,
           p.price,
           0 as discontinued,
           0 as supplierId,
           0 as categoryId
    FROM NF.Production.Product p
) AS CombinedProducts;

-- Sales.PromoCode
INSERT INTO Sales.PromoCode (promoCodeId, discountPc, discountAbs, code)
SELECT discountPc,
       discountAbs,
       code
FROM (
    -- Promo codes from Messy
    SELECT 
           code,
           discountPc,
           discountAbs
    FROM Sales.PromoCode
) AS CombinedPromoCodes;

-- Sales.B2BCustomers
INSERT INTO Sales.B2BCustomers (customerId, [name], frequent, companyId, addressId, contactId)
SELECT 
    name,
    frequent,
    companyId,
    addressId,
    contactId
FROM (
    -- Customers from BIGCO
    SELECT
        comp.name as name,
        0 as frequent,
        comp.companyId,
        a.addressId,
        cont.contactId
    FROM NBIGCO.Sales.Customers c
    JOIN HR.Companies comp ON c.companyId = comp.companyId
    JOIN Info.Addresses a ON c.addressId = a.addressId
    JOIN Info.Contacts cont ON c.phoneId = cont.contactId
    UNION
    -- Customers from Messy
    SELECT
        comp.name as name,
        c.frequent,
        comp.companyId,
        a.addressId,
        cont.contactId
    FROM NF.Sales.Customer c
    LEFT JOIN HR.Companies comp ON c.name = comp.name
    JOIN Info.Addresses a ON c.street = a.address AND c.city = a.city
    JOIN Info.Contacts cont ON c.phone = cont.phone
) AS CombinedB2BCustomers;

-- Sales.B2CCustomers
INSERT INTO Sales.B2CCustomers (customerId, [name], frequent, companyId, addressId, contactId)
SELECT 
    name,
    frequent,
    companyId,
    addressId,
    contactId
FROM (
    -- Customers from BIGCO
    SELECT
        comp.name as name,
        0 as frequent,
        comp.companyId,
        a.addressId,
        cont.contactId
    FROM NBIGCO.Sales.Customers c
    JOIN HR.Companies comp ON c.companyId = comp.companyId
    JOIN Info.Addresses a ON c.addressId = a.addressId
    JOIN Info.Contacts cont ON c.phoneId = cont.contactId
    UNION
    -- Customers from Messy
    SELECT
        comp.name as name,
        c.frequent,
        comp.companyId,
        a.addressId,
        cont.contactId
    FROM NF.Sales.Customer c
    LEFT JOIN HR.Companies comp ON c.name = comp.name
    JOIN Info.Addresses a ON c.street = a.address AND c.city = a.city
    JOIN Info.Contacts cont ON c.phone = cont.phone
) AS CombinedB2CCustomers;

-- Production.Supliers
INSERT INTO Sales.Shippers (shipperId, companyId, contactId)
SELECT shipperId,
       companyId,
       phoneId as contactId
FROM (
    -- Shippers from BIGCO
    SELECT DISTINCT 
           s.shipperId,
           s.companyId,
           s.phoneId
    FROM NBIGCO.Production.Shippers s
    JOIN HR.Companies co ON co.companyId = s.companyID
    JOIN Info.Contacts c ON c.contactId = s.phoneId
) AS BIGCOShippers;

-- Production.Supliers
INSERT INTO Sales.Shippers (shipperId, companyId, contactId)
SELECT shipperId,
       companyId,
       phoneId as contactId
FROM (
    -- Shippers from BIGCO
    SELECT DISTINCT 
           s.shipperId,
           s.companyId,
           s.phoneId
    FROM NBIGCO.Production.Shippers s
    JOIN HR.Companies co ON co.companyId = s.companyID
    JOIN Info.Contacts c ON c.contactId = s.phoneId
) AS BIGCOShippers;

-- Production.PromoCode
INSERT INTO Sales.PromoCode (promoCodeId, discountPc, discountAbs,code)
SELECT discountPc, discountAbs,code
FROM (
    -- PromoCode from Messy
    SELECT DISTINCT 
           pc.code,
           pc.discountPc,
           pc.discountAbs
    FROM NF.Sales.PromoCode pc
) AS MessyPromoCode;
