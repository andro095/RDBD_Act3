-- Assignment-3

-- Team Member Names: Dev Bharatbhai Patel
--					  Zeel Samir Shah
--					  Diego Bolaños Osejo
--					  Andre Sebastian Rodriguez Ovalle

-- Task-1

-- Business Rules
-- 1. Calculate Vacation Days Based on Tenure
-- 2. Update Manager of Employee
-- 3. Low Inventory Flagging
-- 4. Frequent Buyer Status Upgrade/Downgrade
-- 5. Employee Sales Performance
-- 6. Age-based HR Analytics
-- 7. Sales Territory Analysis
-- 8. Update B2B Order Address
-- 9. Get Top 3 Promo Codes by usage
-- 10. Get total sales of a category


-- Task-2 Applied Business Rules on Database with Database Procedures
-- 1. Calculate Vacation Days Based on Tenure
CREATE FUNCTION HR.CalculateVacationDays(@lastname VARCHAR(50), @firstname VARCHAR(50))
RETURNS INT
AS
BEGIN
    DECLARE @hireDate DATETIME;

    SELECT @hireDate = HireDate
    FROM HR.Employees
    WHERE LastName = @lastname AND FirstName = @firstname;

    DECLARE @yearsOfService INT = DATEDIFF(YEAR, @hireDate, GETDATE());
    RETURN
        CASE
            WHEN @yearsOfService < 1 THEN 10
            WHEN @yearsOfService BETWEEN 1 AND 5 THEN 15
            WHEN @yearsOfService BETWEEN 6 AND 10 THEN 20
            ELSE 25
        END
END;

-- 2. Update Manager of Employee
CREATE PROCEDURE HR.UpdateManagerOfEmployee
    @employeeLastName VARCHAR(50),
    @employeeName VARCHAR(50),
    @newManagerLastname VARCHAR(50),
    @newManagerFirstname VARCHAR(50)
AS
BEGIN
    DECLARE @managerID INT;
    DECLARE @employeeID INT;

    SELECT @managerID = EmployeeID
    FROM HR.Employees
    WHERE LastName = @newManagerLastname AND FirstName = @newManagerFirstname;

    SELECT @employeeID = EmployeeID
    FROM HR.Employees
    WHERE LastName = @employeeLastName AND FirstName = @employeeName;

    UPDATE HR.Employees
    SET ManagerID = @managerID
    WHERE EmployeeID = @employeeID;

    PRINT 'Manager Updated Successfully';
END;
GO;

-- 3. Low Inventory Flagging
CREATE PROCEDURE Production.FlagLowInventoryProducts
AS
BEGIN
    SELECT
        p.productId,
        p.name,
        SUM(od.quantity) AS totalSold,
        CASE
            WHEN SUM(od.quantity) < 10 THEN 'Critical Low'
            WHEN SUM(od.quantity) < 50 THEN 'Low'
            ELSE 'Normal'
        END AS inventoryStatus
    FROM Production.Products p
    LEFT JOIN Sales.OrderDetailsB2B od ON p.productId = od.productId
    LEFT JOIN Sales.OrderDetailsB2C odc ON p.productId = odc.productId
    GROUP BY p.productId, p.name
    HAVING SUM(od.quantity) < 50
END;
GO

-- 4. Frequent Buyer Status Upgrade/Downgrade
CREATE PROCEDURE Sales.UpdateCustomerFrequentBuyerStatus
AS
BEGIN
    UPDATE Sales.Customers
    SET frequentBuyer =
        CASE
            WHEN orderCount >= 10 THEN 1
            WHEN orderCount < 5 THEN 0
            ELSE frequentBuyer
        END
    FROM Sales.Customers c
    JOIN (
        SELECT
            customerId,
            COUNT(*) as orderCount
        FROM (
            SELECT customerId FROM Sales.OrdersB2B
            UNION ALL
            SELECT customerId FROM Sales.OrdersB2C
            WHERE customerId IS NOT NULL
        ) AS AllOrders
        GROUP BY customerId
    ) AS OrderStats ON c.customerId = OrderStats.customerId;
END;
GO

-- 5. Employee Sales Performance
CREATE PROCEDURE HR.CalculateEmployeePerformance
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SELECT
        e.employeeId,
        e.firstname + ' ' + e.lastname AS EmployeeName,
        COUNT(DISTINCT o.orderId) AS TotalOrders,
        SUM(o.total) AS TotalSales,
        AVG(o.total) AS AverageOrderValue
    FROM HR.Employees e
    LEFT JOIN Sales.OrdersB2B o ON e.employeeId = o.employeeId
    WHERE o.date BETWEEN @StartDate AND @EndDate
    GROUP BY e.employeeId, e.firstname, e.lastname
    ORDER BY TotalSales DESC;
END;
GO

-- 6. Age-based HR Analytics
CREATE FUNCTION HR.GetWorkforceDemographics()
RETURNS TABLE
AS
RETURN
(
    WITH AgeBands AS (
        SELECT
            employeeId,
            DATEDIFF(YEAR, birthDate, GETDATE()) AS Age,
            CASE
                WHEN DATEDIFF(YEAR, birthDate, GETDATE()) < 30 THEN 'Under 30'
                WHEN DATEDIFF(YEAR, birthDate, GETDATE()) BETWEEN 30 AND 40 THEN '30-40'
                WHEN DATEDIFF(YEAR, birthDate, GETDATE()) BETWEEN 41 AND 50 THEN '41-50'
                WHEN DATEDIFF(YEAR, birthDate, GETDATE()) BETWEEN 51 AND 60 THEN '51-60'
                ELSE 'Over 60'
            END AS AgeGroup,
            CASE
                WHEN DATEDIFF(YEAR, birthDate, DATEADD(YEAR, 65, hireDate)) <= 5 THEN 1
                ELSE 0
            END AS NearingRetirement
        FROM HR.Employees
    )
    SELECT
        AgeGroup,
        COUNT(*) AS EmployeeCount,
        AVG(CAST(Age AS FLOAT)) AS AverageAge,
        SUM(NearingRetirement) AS RetirementEligibleNext5Years,
        CAST(COUNT(*) AS FLOAT) / (SELECT COUNT(*) FROM HR.Employees) * 100 AS PercentageOfWorkforce
    FROM AgeBands
    GROUP BY AgeGroup
);
GO

-- 7. Sales Territory Analysis
CREATE FUNCTION Sales.GetTerritoryPerformance()
RETURNS TABLE
AS
RETURN
(
    WITH TerritoryStats AS (
        SELECT
            region,
            COUNT(DISTINCT customerId) AS CustomerCount,
            SUM(CASE WHEN frequentBuyer = 1 THEN 1 ELSE 0 END) AS FrequentBuyerCount
        FROM Sales.Customers
        GROUP BY region
    )
    SELECT
        t.region,
        t.CustomerCount,
        t.FrequentBuyerCount,
        CAST(t.FrequentBuyerCount AS FLOAT) / NULLIF(t.CustomerCount, 0) AS FrequentBuyerRatio
    FROM TerritoryStats t
);
GO

-- 8. Update B2B Order Address
CREATE PROCEDURE Sales.UpdateB2BOrderAddress
    @orderId INT,
    @newAddress VARCHAR(100),
    @newCity VARCHAR(50),
    @newRegion VARCHAR(50),
    @newPostalCode VARCHAR(10),
    @newCountry VARCHAR(50)
AS
BEGIN
    UPDATE Sales.OrdersB2B
    SET shipAddress = @newAddress,
        shipCity = @newCity,
        shipRegion = @newRegion,
        shipPostalCode = @newPostalCode,
        shipCountry = @newCountry
    WHERE orderId = @orderId;

    PRINT 'Order Address Updated Successfully';
END;
GO

-- 9. Get Top 3 Promo Codes by usage
CREATE FUNCTION Sales.GetTop3PromoCodes()
RETURNS TABLE
AS
RETURN
(
    SELECT
        pc.code AS PromoCode,
        COUNT(*) AS UsageCount
    FROM Sales.OrdersB2C ord
    INNER JOIN Sales.PromoCodes pc ON ord.promoCodeId = pc.promoCodeId
    WHERE ord.promoCodeId IS NOT NULL
    GROUP BY pc.code
    ORDER BY UsageCount DESC
    OFFSET 0 ROWS FETCH NEXT 3 ROWS ONLY
);
GO

-- 10. Get total sales of a category
CREATE FUNCTION Sales.GetTotalSalesByCategory(@categoryName VARCHAR(50))
RETURNS TABLE
AS
RETURN
(
    SELECT c.name AS Category, SUM(ob2b.total) AS TotalSales
    FROM Sales.OrdersB2B ob2b
    INNER JOIN Sales.OrderDetailsB2B odb2b ON ob2b.orderId = odb2b.orderId
    INNER JOIN Production.Products p ON odb2b.productId = p.productId
    INNER JOIN Production.Categories c ON p.categoryId = c.categoryId
    WHERE c.name = @categoryName
    GROUP BY c.name
);
GO


-- Task-3 Test the Business Rules
-- 1. Calculate Vacation Days Based on Tenure
SELECT HR.CalculateVacationDays('Davis', 'sara') AS 'Vacation Days';

-- 2. Update Manager of Employee
SELECT lastname, firstname, managerId
FROM HR.Employees
WHERE LastName = 'Nikia' AND FirstName = 'Smiley';

EXEC [HR].[UpdateManagerOfEmployee]
         @employeeLastName = 'Nikia',
         @employeeName = 'Curtin',
         @newManagerLastname = 'Elenora',
         @newManagerFirstname =  'Smiley';

SELECT lastname, firstname, managerId
FROM HR.Employees
WHERE LastName = 'Nikia' AND FirstName = 'Smiley';

-- 3. Low Inventory Flagging
EXEC Production.FlagLowInventoryProducts;

-- 4. Frequent Buyer Status Upgrade/Downgrade
EXEC Sales.UpdateCustomerFrequentBuyerStatus;

-- 5. Employee Sales Performance
EXEC HR.CalculateEmployeePerformance @StartDate = '2018-01-01', @EndDate = '2018-12-31';

-- 6. Age-based HR Analytics
SELECT * FROM HR.GetWorkforceDemographics();

-- 7. Sales Territory Analysis
SELECT * FROM Sales.GetTerritoryPerformance();

-- 8. Update B2B Order Address
SELECT * FROM Sales.OrdersB2B WHERE orderId = 4;

EXEC Sales.UpdateB2BOrderAddress
         @orderId = 4,
         @newAddress = '1234 New Address',
         @newCity = 'New City',
         @newRegion = 'New Region',
         @newPostalCode = '12345',
         @newCountry = 'New Country';

SELECT * FROM Sales.OrdersB2B WHERE orderId = 4;

-- 9. Get Top 3 Promo Codes by usage
SELECT * FROM Sales.GetTop3PromoCodes();

-- 10. Get total sales of a category
SELECT * FROM Sales.GetTotalSalesByCategory('Electronics');