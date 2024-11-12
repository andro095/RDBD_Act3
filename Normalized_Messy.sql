CREATE SCHEMA Sales AUTHORIZATION dbo;
GO

CREATE SCHEMA Production AUTHORIZATION dbo;
GO

---------------------------------------------------------------------
-- Create Tables
---------------------------------------------------------------------

-- Production Tables Creation
-- Product Table
CREATE TABLE Production.Product (
    id INT NOT NULL PRIMARY KEY,
    description VARCHAR(100) NOT NULL DEFAULT '',
    price NUMERIC(16,2) NOT NULL DEFAULT 0.00,
);

-- Tag Table
CREATE TABLE Production.Tag (
    id INT NOT NULL PRIMARY KEY IDENTITY,
    tag VARCHAR(100) NOT NULL DEFAULT '',
    productId INT NOT NULL,
    FOREIGN KEY (productId) REFERENCES Production.Product(id)
);

-- Sales Tables Creation
-- Customer Table
CREATE TABLE Sales.Customer (
    id INT NOT NULL PRIMARY KEY IDENTITY,
    name VARCHAR(100) NOT NULL DEFAULT '',
    street VARCHAR(100) NOT NULL DEFAULT '',
    city VARCHAR(50) NOT NULL DEFAULT '',
    region VARCHAR(50) NOT NULL DEFAULT '',
    postalCode VARCHAR(15) NOT NULL DEFAULT '',
    phone VARCHAR(30) NOT NULL DEFAULT 0,
    email VARCHAR(50) NOT NULL DEFAULT '',
    frequent BIT NOT NULL DEFAULT 0,
);

-- Promo Code Table
CREATE TABLE Sales.PromoCode (
    id INT NOT NULL PRIMARY KEY IDENTITY,
    code VARCHAR(20) NOT NULL DEFAULT '',
    discountPc NUMERIC(5,2) NOT NULL DEFAULT 0.00,
    discountAbs NUMERIC(16,2) NOT NULL DEFAULT 0.00,
);

-- Order Table
CREATE TABLE Sales.Orders (
    id VARCHAR(40) NOT NULL PRIMARY KEY,
    date DATETIME NOT NULL DEFAULT GETDATE(),
    subTotal NUMERIC(16,2) NOT NULL DEFAULT 0.00,
    total NUMERIC(16,2) NOT NULL DEFAULT 0.00,
    PromoCodeId INT,
    CustomerId INT,
    FOREIGN KEY (PromoCodeId) REFERENCES Sales.PromoCode(id),
    FOREIGN KEY (CustomerId) REFERENCES Sales.Customer(id)
);

-- Order Detail Table
CREATE TABLE Sales.OrderDetail (
    id INT NOT NULL PRIMARY KEY IDENTITY,
    orderId VARCHAR(40) NOT NULL,
    productId INT NOT NULL,
    FOREIGN KEY (orderId) REFERENCES Sales.Orders(id),
    FOREIGN KEY (productId) REFERENCES Production.Product(id)
)


-- Production Data Insertion
-- Product Data
INSERT INTO Production.Product (id, description, price)
SELECT DISTINCT ms.ProductID,
                ISNULL(ms.ProductDescription, ''),
                ISNULL(ms.LineItemPrice, 0.00)
FROM dbo.Messy ms
WHERE ms.ProductID IS NOT NULL;

--- Tag Data
INSERT INTO Production.Tag (tag, productId)
SELECT TRIM(value), ProductID
FROM dbo.Messy
CROSS APPLY STRING_SPLIT(ProductTags, ',')
WHERE ProductTags IS NOT NULL
AND TRIM(value) <> '';

-- Sales Data Insertion
-- Customer Data
INSERT INTO Sales.Customer (name, street, city, region, postalCode, phone, email, frequent)
SELECT DISTINCT ms.CustomerName,
                ISNULL(ms.CustomerAddress1, ''),
                ISNULL(ms.CustomerAddress2, ''),
                CASE
                    WHEN ms.CustomerAddress3 IS NOT NULL AND ms.CustomerAddress3 <> '' THEN ms.CustomerAddress3
                    WHEN ms.CustomerAddress4 IS NOT NULL AND ms.CustomerAddress4 <> '' THEN ms.CustomerAddress4
                    ELSE ''
                END,
                ISNULL(ms.CustomerAddress5, ''),
                REPLACE(ISNULL(ms.CustomerPhoneNo, ''), ' ', ''),
                ISNULL(ms.CustomerEmail, ''),
                IIF(ms.RepeatCustomer = 'Yes', 1, 0)
FROM dbo.Messy ms
WHERE CustomerName IS NOT NULL;

-- Promo Code Data
INSERT INTO Sales.PromoCode (code, discountPc, discountAbs)
SELECT DISTINCT ISNULL(ms.PromoCode, ''),
                ISNULL(TRY_CAST(ms.DiscountAppliedPc AS NUMERIC(5,2)), 0.00),
                ISNULL(ms.DiscountAppliedAbs, 0.00)
FROM dbo.Messy ms
WHERE ms.PromoCode IS NOT NULL;

-- Order Data
INSERT INTO Sales.Orders (id, date, subTotal, total, PromoCodeId, CustomerId)
SELECT DISTINCT ms.OrderNo,
                CONCAT(
                    SUBSTRING(ms.SaleDate,1,4),
                    '-',
                    SUBSTRING(ms.SaleDate, 5, 2),
                    '-',
                    SUBSTRING(ms.SaleDate, 7, 2),
                    ' ',
                    SUBSTRING(ms.SaleDate, 9, 2),
                    ':',
                    SUBSTRING(ms.SaleDate, 11, 2),
                    ':',
                    SUBSTRING(ms.SaleDate, 13, 2)
                ),
                ISNULL(ms.TotalSalePrice, 0.00),
                ISNULL(ms.NewTotalSalePrice, 0.00),
                pc.id,
                cs.id
FROM dbo.Messy ms
LEFT JOIN Sales.PromoCode pc ON ms.PromoCode = pc.code
LEFT JOIN Sales.Customer cs ON ms.CustomerName = cs.name AND ms.RepeatCustomer = IIF(cs.frequent = 1, 'Yes', 'No')
WHERE ms.OrderNo IS NOT NULL;

-- Order Detail Data
INSERT INTO Sales.OrderDetail (orderId, productId)
SELECT DISTINCT ms.OrderNo, ms.ProductID
FROM dbo.Messy ms
WHERE OrderNo IS NOT NULL;



