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
-- 21. Get products without orders in last 30 days
-- 22. Find customers with no orders
-- 23. Calculate average delivery time for B2B orders
-- 24. List products with price higher than category average
-- 25. Find suppliers with no active products
-- 26. Calculate shipping cost percentage of total order value
-- 27. Find products never ordered by B2C customers
-- 28. Calculate orders per employee per month
-- 29. List customers who ordered all products in a category
-- 30. Find address used by multiple customers

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
    @criticalThreshold INT = 10,
    @lowThreshold INT = 50
AS
BEGIN
    SELECT
        p.productId,
        p.name,
        SUM(od.quantity) AS totalSold,
        CASE
            WHEN SUM(od.quantity) < @criticalThreshold THEN 'Critical Low'
            WHEN SUM(od.quantity) < @lowThreshold THEN 'Low'
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
    @orderCountThreshold INT = 10,
    @orderCountLowThreshold INT = 5
AS
BEGIN
    UPDATE Sales.Customers
    SET frequentBuyer =
        CASE
            WHEN orderCount >= @orderCountThreshold THEN 1
            WHEN orderCount < @orderCountLowThreshold THEN 0
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
CREATE FUNCTION HR.GetWorkforceDemographics(@retirementAge INT = 65)
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
                WHEN DATEDIFF(YEAR, birthDate, DATEADD(YEAR, @retirementAge, hireDate)) <= 5 THEN 1
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
CREATE FUNCTION Sales.GetTerritoryPerformance(@analysisCount INT = 0)
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
        CAST(t.FrequentBuyerCount AS FLOAT) / NULLIF(t.CustomerCount, @analysisCount) AS FrequentBuyerRatio
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

-- 9. Get Top Promo Codes by usage
CREATE FUNCTION Sales.GetTopPromoCodes(@topCount INT = 3)
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
    OFFSET 0 ROWS FETCH NEXT @topCount ROWS ONLY
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

-- 21. Get products without orders in last 30 days
CREATE PROCEDURE Production.GetProductsWithoutOrders
AS
BEGIN
    DECLARE @LastMonthDate DATE = DATEADD(DAY, -30, GETDATE());

    -- Create temporary table for recent orders
    CREATE TABLE #RecentOrders (
        productId INT PRIMARY KEY
    );

    -- Insert B2B orders
    INSERT INTO #RecentOrders (productId)
    SELECT DISTINCT od.productId
    FROM Sales.OrderDetailsB2B od
    JOIN Sales.OrdersB2B o ON od.orderId = o.orderId
    WHERE o.date > @LastMonthDate;

    -- Insert B2C orders
    INSERT INTO #RecentOrders (productId)
    SELECT DISTINCT od.productId
    FROM Sales.OrderDetailsB2C od
    JOIN Sales.OrdersB2C o ON od.orderId = o.orderId
    WHERE o.date > @LastMonthDate
    AND NOT EXISTS (
        SELECT 1 FROM #RecentOrders r
        WHERE r.productId = od.productId
    );

    -- Get products without recent orders
    SELECT
        p.productId,
        p.name,
        p.unitPrice,
        c.name AS CategoryName,
        s.companyName AS SupplierName,
        CASE
            WHEN p.discontinued = 1 THEN 'Discontinued'
            ELSE 'Active'
        END AS ProductStatus
    FROM Production.Products p
    LEFT JOIN #RecentOrders r ON p.productId = r.productId
    JOIN Production.Categories c ON p.categoryId = c.categoryId
    JOIN Production.Suppliers s ON p.supplierId = s.supplierId
    WHERE r.productId IS NULL
    ORDER BY
        c.name,
        p.name;

    -- Drop temporary table
    DROP TABLE #RecentOrders;
END;
GO

-- Create index to improve performance
CREATE NONCLUSTERED INDEX IX_OrdersB2B_Date ON Sales.OrdersB2B(date);
CREATE NONCLUSTERED INDEX IX_OrdersB2C_Date ON Sales.OrdersB2C(date);

-- 22. Find customers who have spent more than $10,000 in total purchases
CREATE PROCEDURE Sales.GetHighValueCustomers
    @MinimumSpent DECIMAL(18,2) = 10000.00
AS
BEGIN
    SET NOCOUNT ON;

    -- Get high value customers from both B2B and B2C
    SELECT
        c.customerId,
        c.companyName as CustomerName,
        c.customerType,
        c.city,
        c.country,
        COALESCE(B2B_Sales.TotalSpent, 0) + COALESCE(B2C_Sales.TotalSpent, 0) as TotalSpent,
        COALESCE(B2B_Sales.OrderCount, 0) + COALESCE(B2C_Sales.OrderCount, 0) as TotalOrders
    FROM Sales.Customers c
    -- Get B2B sales
    LEFT JOIN (
        SELECT
            customerId,
            SUM(total) as TotalSpent,
            COUNT(*) as OrderCount
        FROM Sales.OrdersB2B
        GROUP BY customerId
    ) B2B_Sales ON c.customerId = B2B_Sales.customerId
    -- Get B2C sales
    LEFT JOIN (
        SELECT
            customerId,
            SUM(total) as TotalSpent,
            COUNT(*) as OrderCount
        FROM Sales.OrdersB2C
        GROUP BY customerId
    ) B2C_Sales ON c.customerId = B2C_Sales.customerId
    WHERE COALESCE(B2B_Sales.TotalSpent, 0) + COALESCE(B2C_Sales.TotalSpent, 0) > @MinimumSpent
    ORDER BY TotalSpent DESC;
END;
GO

-- 23. Calculate delivery time by shipper
CREATE PROCEDURE Sales.GetAverageDeliveryTime
AS
BEGIN
    -- Overall shipper delivery time
    SELECT
        s.name as ShipperName,
        COUNT(*) as TotalDeliveries,
        AVG(CAST(DATEDIFF(day, requiredDate, shippedDate) AS DECIMAL(10,2))) as AvgDeliveryDays,
        SUM(CASE WHEN shippedDate <= requiredDate THEN 1 ELSE 0 END) as OnTimeDeliveries,
        CAST(SUM(CASE WHEN shippedDate <= requiredDate THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) as OnTimePercentage
    FROM Sales.OrdersB2B o
    JOIN Sales.Shippers s ON o.shipperId = s.shipperId
    GROUP BY s.shipperId, s.name
    ORDER BY OnTimePercentage DESC;

    -- Monthly trend
    SELECT
        FORMAT(shippedDate, 'yyyy-MM') as Month,
        s.name as ShipperName,
        COUNT(*) as Deliveries,
        AVG(CAST(DATEDIFF(day, requiredDate, shippedDate) AS DECIMAL(10,2))) as AvgDeliveryDays
    FROM Sales.OrdersB2B o
    JOIN Sales.Shippers s ON o.shipperId = s.shipperId
    GROUP BY FORMAT(shippedDate, 'yyyy-MM'), s.shipperId, s.name
    ORDER BY Month DESC, Deliveries DESC;
END;
GO

-- 24. List products with unit price higher than category average
CREATE PROCEDURE Production.GetProductsAboveCategoryAverage
AS
BEGIN
    WITH CategoryAverages AS (
        SELECT
            categoryId,
            AVG(unitPrice) as AveragePrice
        FROM Production.Products
        GROUP BY categoryId
    )
    SELECT
        p.productId,
        p.name,
        p.unitPrice,
        c.name as Category
    FROM Production.Products p
    JOIN Production.Categories c ON p.categoryId = c.categoryId
    JOIN CategoryAverages ca ON p.categoryId = ca.categoryId
    WHERE p.unitPrice > ca.AveragePrice
    ORDER BY c.name, p.unitPrice DESC;
END;
GO

-- 25. Find suppliers with no active products
CREATE PROCEDURE Production.GetSuppliersWithNoActiveProducts
AS
BEGIN
    SELECT
        s.supplierId,
        s.companyName,
        s.contactName,
        s.city,
        s.country,
        COUNT(p.productId) as TotalProducts,
        SUM(CASE WHEN p.discontinued = 1 THEN 1 ELSE 0 END) as DiscontinuedProducts,
        SUM(CASE WHEN p.discontinued = 0 THEN 1 ELSE 0 END) as ActiveProducts
    FROM Production.Suppliers s
    LEFT JOIN Production.Products p ON s.supplierId = p.supplierId
    GROUP BY
        s.supplierId,
        s.companyName,
        s.contactName,
        s.city,
        s.country
    HAVING SUM(CASE WHEN p.discontinued = 0 THEN 1 ELSE 0 END) = 0
        OR COUNT(p.productId) = 0
    ORDER BY s.companyName;
END;
GO

-- 26. Calculate shipping cost percentage of total order value
CREATE PROCEDURE Sales.CalculateShippingCostPercentage
AS
BEGIN
    SELECT
        orderId,
        freight,
        subtotal as OrderValue,
        CAST((freight / NULLIF(subtotal, 0)) * 100 as DECIMAL(10,2)) as FreightPercentage
    FROM Sales.OrdersB2B
    WHERE subtotal > 0
    ORDER BY orderId;
END;
GO

-- 27. Find products never ordered by customers
CREATE PROCEDURE Sales.GetProductsNeverOrdered
AS
BEGIN
    SELECT
        p.productId,
        p.name
    FROM Production.Products p
    WHERE NOT EXISTS (
        SELECT 1
        FROM Sales.OrderDetailsB2B b2b
        WHERE b2b.productId = p.productId
    )
    AND NOT EXISTS (
        SELECT 1
        FROM Sales.OrderDetailsB2C b2c
        WHERE b2c.productId = p.productId
    )
    ORDER BY p.name;
END;
GO

-- 28. Calculate orders per employee per month
CREATE PROCEDURE Sales.OrdersPerEmployeePerMonth
AS
BEGIN
    SELECT e.employeeId, e.lastName,
           MONTH(o.requiredDate) as Month,
           COUNT(*) as OrderCount
    FROM HR.Employees e
    JOIN Sales.OrdersB2B o ON e.employeeId = o.employeeId
    GROUP BY e.employeeId, e.lastName, MONTH(o.requiredDate);
END;
GO;

-- 29. List customers who ordered all products in a category
CREATE PROCEDURE Sales.CustomersOrderedAllProductsInCategory
AS
BEGIN
    SELECT c.companyName, ca.name as CategoryName
    FROM Sales.Customers c
    JOIN Sales.OrdersB2B o ON c.customerId = o.customerId
    JOIN Sales.OrderDetailsB2B od ON o.orderId = od.orderId
    JOIN Production.Products p ON od.productId = p.productId
    JOIN Production.Categories ca ON p.categoryId = ca.categoryId
    GROUP BY ca.name, ca.categoryId, c.companyName
    HAVING COUNT(DISTINCT p.productId) = (
        SELECT COUNT(*)
        FROM Production.Products
        WHERE categoryId = ca.categoryId
    );
END;
GO

-- 30. Find address used by multiple customers
CREATE PROCEDURE Sales.GetSharedAddresses
AS
BEGIN
    SELECT
        address,
        city,
        region,
        country,
        COUNT(DISTINCT customerId) as CustomerCount,
        STRING_AGG(companyName, ', ') as Companies
    FROM Sales.Customers
    GROUP BY
        address,
        city,
        region,
        country
    HAVING COUNT(DISTINCT customerId) > 1
    ORDER BY
        CustomerCount DESC,
        city,
        address;

    -- Additional breakdown by customer type
    SELECT
        address,
        city,
        region,
        country,
        customerType,
        COUNT(DISTINCT customerId) as CustomerCount
    FROM Sales.Customers
    GROUP BY
        address,
        city,
        region,
        country,
        customerType
    HAVING COUNT(DISTINCT customerId) > 1
    ORDER BY
        CustomerCount DESC,
        customerType,
        city,
        address;
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
EXEC Production.FlagLowInventoryProducts
    @criticalThreshold = 10,
    @lowThreshold = 35;

-- 4. Frequent Buyer Status Upgrade/Downgrade
EXEC Sales.UpdateCustomerFrequentBuyerStatus
    @orderCountThreshold = 10,
    @orderCountLowThreshold = 5;

-- 5. Employee Sales Performance
EXEC HR.CalculateEmployeePerformance @StartDate = '2018-01-01', @EndDate = '2018-12-31';

-- 6. Age-based HR Analytics
SELECT * FROM HR.GetWorkforceDemographics(65);

-- 7. Sales Territory Analysis
SELECT * FROM Sales.GetTerritoryPerformance(0);

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
SELECT * FROM Sales.GetTopPromoCodes(4);

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

--- 21. Get products without orders in last 30 days
EXEC Production.GetProductsWithoutOrders;

--- 22. Find customers who have spent more than $10,000 in total purchases
EXEC Sales.GetHighValueCustomers @MinimumSpent = 10000;

--- 23. Calculate delivery time by shipper
EXEC Sales.GetAverageDeliveryTime;

--- 24. List products with unit price higher than category average
EXEC Production.GetProductsAboveCategoryAverage;

--- 25. Find suppliers with no active products
EXEC Production.GetSuppliersWithNoActiveProducts;

--- 26. Calculate shipping cost percentage of total order value
EXEC Sales.CalculateShippingCostPercentage;

--- 27. Find products never ordered by customers
EXEC Sales.GetProductsNeverOrdered;

--- 28. Calculate orders per employee per month
EXEC Sales.OrdersPerEmployeePerMonth;

--- 29. List customers who ordered all products in a category
EXEC Sales.CustomersOrderedAllProductsInCategory;

--- 30. Find address used by multiple customers
EXEC Sales.GetSharedAddresses;