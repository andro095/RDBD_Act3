-- Assignment-4

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
-- 11. Determine High-Value Customers
-- 12. Top-3 Selling Products in a Category
-- 13. Dynamic Customer Loyalty Tier Update
-- 14. Evaluate Supplier Performance
-- 15. Calculate Total Discounted Sales applied to orders (B2B and B2C)
-- 16. Product Restocking Recommendation System
-- 17. Generate Product Profit Margin Report
-- 18. Analyze Promo Code Effectiveness
-- 19. Predict Employee Turnover Risk
-- 20. Customer Type(B2B VS B2C) Revenue Breakdown

-- ###################################################################################################################

-- Task-2 Applied Business Rules on Database with Database Procedures/Functions

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

-- 11. Determine High-Value Customers
CREATE PROCEDURE Sales.DetermineHighValueCustomers
    @startDate DATETIME,
    @endDate DATETIME,
    @threshold DECIMAL
AS
BEGIN
    SELECT 
        C.CustomerID,
        C.CompanyName,
        SUM(O.Total) AS TotalSpent
    FROM Sales.Customers AS C
    INNER JOIN Sales.OrdersB2B AS O ON C.CustomerID = O.CustomerID
    WHERE O.Date BETWEEN @startDate AND @endDate
    GROUP BY C.CustomerID, C.CompanyName
    HAVING SUM(O.Total) > @threshold
    ORDER BY TotalSpent DESC;
END;
GO

-- 12. Top-3 Selling Products in a Category
CREATE FUNCTION Sales.GetTopSellingProductsByCategory
    (@categoryId INT, @startDate DATETIME, @endDate DATETIME)
RETURNS TABLE
AS
RETURN
    SELECT TOP 3 
        P.ProductID,
        P.Name AS ProductName,
        SUM(OD.Quantity) AS TotalQuantitySold
    FROM Production.Products AS P
    INNER JOIN Sales.OrderDetailsB2B AS OD ON P.ProductID = OD.ProductID
    INNER JOIN Sales.OrdersB2B AS O ON OD.OrderID = O.OrderID
    WHERE P.CategoryID = @categoryId AND O.Date BETWEEN @startDate AND @endDate
    GROUP BY P.ProductID, P.Name
    ORDER BY TotalQuantitySold DESC;
GO

-- 13. Dynamic Customer Loyalty Tier Update
CREATE PROCEDURE Sales.UpdateLoyaltyTiers
AS
BEGIN
    DECLARE @BronzeThreshold DECIMAL = 5000;
    DECLARE @SilverThreshold DECIMAL = 10000;
    DECLARE @GoldThreshold DECIMAL = 12000;

    WITH CustomerSpending AS (
        SELECT 
            C.CustomerID,
            SUM(O.Total) AS TotalSpent
        FROM Sales.Customers AS C
        INNER JOIN Sales.OrdersB2B AS O ON C.CustomerID = O.CustomerID
        WHERE O.Date BETWEEN '2018-01-01' AND '2018-12-31'
        GROUP BY C.CustomerID
    )
    UPDATE Sales.Customers
    SET CustomerType = 
        CASE
            WHEN CS.TotalSpent >= @GoldThreshold THEN 'Platinum'
            WHEN CS.TotalSpent >= @SilverThreshold THEN 'Gold'
            WHEN CS.TotalSpent >= @BronzeThreshold THEN 'Silver'
            ELSE 'Bronze'
        END
    FROM Sales.Customers AS C
    INNER JOIN CustomerSpending AS CS ON C.CustomerID = CS.CustomerID;

    PRINT 'Customer Loyalty Tiers Updated Successfully';
END;
GO

-- 14. Evaluate Supplier Performance
CREATE FUNCTION Sales.GetAverageDeliveryTime(@supplierId INT)
RETURNS FLOAT
AS
BEGIN
    RETURN (
        SELECT AVG(DATEDIFF(DAY, O.RequiredDate, O.ShippedDate))
        FROM Sales.OrdersB2B AS O
        INNER JOIN Production.Products AS P ON O.OrderID = P.ProductID
        WHERE P.SupplierID = @supplierId AND O.ShippedDate IS NOT NULL
    );
END;
GO

-- 15. Calculate Total Discounted Sales applied to orders (B2B and B2C)
CREATE PROCEDURE Sales.CalculateTotalDiscounts
    @startDate DATETIME,
    @endDate DATETIME
AS
BEGIN
    SELECT 
        SUM((Subtotal - Total)) AS TotalDiscount
    FROM (
        SELECT Subtotal, Total FROM Sales.OrdersB2B WHERE Date BETWEEN @startDate AND @endDate
        UNION ALL
        SELECT Subtotal, Total FROM Sales.OrdersB2C WHERE Date BETWEEN @startDate AND @endDate
    ) AS Discounts;
END;
GO

-- 16. Product Restocking Recommendation System
CREATE PROCEDURE Production.GetRestockingRecommendations
AS
BEGIN
    WITH ProductSales AS (
        SELECT 
            P.ProductID,
            P.Name AS ProductName,
            SUM(OD.Quantity) AS TotalSold,
            DATEDIFF(DAY, MIN(O.Date), MAX(O.Date)) AS TotalDays
        FROM Production.Products AS P
        INNER JOIN Sales.OrderDetailsB2B AS OD ON P.ProductID = OD.ProductID
        INNER JOIN Sales.OrdersB2B AS O ON OD.OrderID = O.OrderID
        WHERE O.Date >= DATEADD(MONTH, -3, GETDATE())
        GROUP BY P.ProductID, P.Name
    ),
    StockLevels AS (
        SELECT 
            PS.ProductID,
            PS.ProductName,
            (PS.TotalSold / NULLIF(PS.TotalDays, 0)) * 30 AS RecommendedRestock
        FROM ProductSales AS PS
    )
    SELECT 
        ProductID,
        ProductName,
        RecommendedRestock
    FROM StockLevels
    WHERE RecommendedRestock > 0
    ORDER BY RecommendedRestock DESC;
END;
GO

-- 17. Generate Product Profit Margin Report
CREATE PROCEDURE Production.GetProductProfitMargins
    @startDate DATETIME,
    @endDate DATETIME
AS
BEGIN
    SELECT 
        P.ProductID,
        P.Name AS ProductName,
        P.UnitPrice,
        SUM(OD.Quantity * P.UnitPrice) AS TotalRevenue,
        SUM(OD.Quantity * (P.UnitPrice - OD.UnitPrice)) AS ProfitMargin
    FROM Production.Products AS P
    INNER JOIN Sales.OrderDetailsB2B AS OD ON P.ProductID = OD.ProductID
    INNER JOIN Sales.OrdersB2B AS O ON OD.OrderID = O.OrderID
    WHERE O.Date BETWEEN @startDate AND @endDate
    GROUP BY P.ProductID, P.Name, P.UnitPrice
    ORDER BY ProfitMargin DESC;
END;
GO

-- 18. Analyze Promo Code Effectiveness
CREATE FUNCTION Sales.GetPromoCodeEffectiveness(@promoCodeId INT)
RETURNS TABLE
AS
RETURN
    SELECT 
        PromoCodeID,
        COUNT(*) AS TotalOrders,
        SUM(Total) AS TotalRevenueGenerated
    FROM (
        SELECT PromoCodeID, Total FROM Sales.OrdersB2B WHERE PromoCodeID = @promoCodeId
        UNION ALL
        SELECT PromoCodeID, Total FROM Sales.OrdersB2C WHERE PromoCodeID = @promoCodeId
    ) AS PromoSales
    GROUP BY PromoCodeID;
GO

-- 19. Predict Employee Turnover Risk
CREATE PROCEDURE HR.PredictEmployeeTurnoverRisk
AS
BEGIN
    DECLARE @LowTenure INT = 2;
    DECLARE @HighAbsences INT = 10;

    WITH EmployeeData AS (
        SELECT 
            E.EmployeeID,
            E.FirstName,
            E.LastName,
            DATEDIFF(YEAR, E.HireDate, GETDATE()) AS Tenure,
            CASE
                WHEN DATEDIFF(YEAR, E.HireDate, GETDATE()) < @LowTenure THEN 'High Risk'
                ELSE 'Low Risk'
            END AS TurnoverRisk
        FROM HR.Employees AS E
    )
    SELECT 
        EmployeeID,
        FirstName,
        LastName,
        Tenure,
        TurnoverRisk
    FROM EmployeeData
    ORDER BY TurnoverRisk DESC, Tenure ASC;
END;
GO

-- 20. Customer Type(B2B VS B2C) Revenue Breakdown
CREATE PROCEDURE Sales.GetCustomerTypeRevenueBreakdown
    @startDate DATETIME,
    @endDate DATETIME
AS
BEGIN
    SELECT 
        'B2B' AS CustomerType,
        SUM(Total) AS TotalRevenue
    FROM Sales.OrdersB2B
    WHERE Date BETWEEN @startDate AND @endDate
    UNION ALL
    SELECT 
        'B2C' AS CustomerType,
        SUM(Total) AS TotalRevenue
    FROM Sales.OrdersB2C
    WHERE Date BETWEEN @startDate AND @endDate;
END;
GO


-- ###################################################################################################################

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

-- 11. Determine High-Value Customers
EXEC Sales.DetermineHighValueCustomers 
    @startDate = '2018-01-01', 
    @endDate = '2018-12-31', 
    @threshold = 10000;

-- 12. Top-3 Selling Products in a Category
SELECT * FROM Sales.GetTopSellingProductsByCategory( 1, '2018-01-01', '2018-12-31');

-- 13. Dynamic Customer Loyalty Tier Update
EXEC Sales.UpdateLoyaltyTiers;

-- Check if customertype is updated or not
SELECT CustomerID, CustomerType FROM Sales.Customers;

-- 14. Evaluate Supplier Performance
SELECT Sales.GetAverageDeliveryTime(1) AS AverageDeliveryTime;

-- 15. Calculate Total Discounted Sales applied to orders (B2B and B2C)
EXEC Sales.CalculateTotalDiscounts 
    @startDate = '2018-01-01', 
    @endDate = '2018-12-31';

-- 16. Product Restocking Recommendation System
EXEC Production.GetRestockingRecommendations;

-- 17. Generate Product Profit Margin Report
EXEC Production.GetProductProfitMargins 
    @startDate = '2018-01-01', 
    @endDate = '2018-12-31';

-- 18. Analyze Promo Code Effectiveness
SELECT * FROM Sales.GetPromoCodeEffectiveness(1);

-- 19. Predict Employee Turnover Risk
EXEC HR.PredictEmployeeTurnoverRisk;

-- 20. Customer Type(B2B VS B2C) Revenue Breakdown
EXEC Sales.GetCustomerTypeRevenueBreakdown 
    @startDate = '2018-01-01', 
    @endDate = '2018-12-31';