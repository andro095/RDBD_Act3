-- Assignment-3

-- Team Member Names: Dev Bharatbhai Patel
--					  Zeel Samir Shah
--					  Diego Bolaños Osejo 
--					  Andre Sebastian Rodriguez Ovalle

-- Task-1

-- Business Rules

-- 1.  Display total sales per product category for each month to identify monthly sales trends by category.
-- 2.  Show quarterly sales totals for each product in each region to assess product popularity across regions.
-- 3.  Display the number of purchases each customer made per year to evaluate customer engagement.
-- 4.  Display average order value by month for each customer to identify high-value customers and seasonal trends.
-- 5.  Identify top-selling products by sales revenue each month to track demand and optimize stock.
-- 6.  Track the use of discounts across product categories each month to monitor discounting patterns.
-- 7.  Display the number of units sold for each product by sales channel to assess channel performance.
-- 8.  Show the distribution of customers by location for each product category to guide marketing efforts.
-- 9.  Calculate inventory turnover rate for each product model per month to manage stock more effectively.
-- 10. Display year-over-year sales growth by product category to track growth and adjust strategies.
-- 11. Display the total enrollment count for each program in each year.
-- 12. Show the count of students in each country and academic status, providing insights into geographic diversity and academic performance.
-- 13. Display the number of penalties issued to students within each program by year, helping track disciplinary trends.
-- 14.	Calculate the total amount of fees collected by each payment method, grouped by year, to identify payment trends and preferences.
-- 15. Display the number of courses offered on each campus per semester, allowing management to see course distribution across campuses.
-- 16. Display the number of offenses recorded for students, by each academic year and penalty type.
-- 17. Calculate the average final marks of students for each course within a program, helping to assess student performance in each course.
-- 18. Show the total amount invoiced to students per semester for each program, giving insight into program-specific revenue.
-- 19. Count the number of logs generated per day, by each user and audit category, to monitor user activity levels and focus areas.
-- 20. Display the enrollment count of international and domestic students for each program, by year, showing trends in student demographics.
-- 21. Employee count by title and company.
-- 22. Average employee age by title and courtesy title.
-- 23. Employee hire patterns by year and region.
-- 24. Employee distribution across cities and titles.
-- 25. Employee counts by company size and region.
-- 26. Product count by category and supplier.
-- 27. Average product price by category and supplier.
-- 28. Discontinued product percentage by category and supplier.
-- 29. Product tag distribution across categories.
-- 30. Product counts by price ranges and categories.
-- 31. B2B vs B2C customer distribution by city.
-- 32. Frequent customer percentage by region.
-- 33. Customer concentration by county and type.
-- 34. Company-affiliated vs individual customer distribution by region.
-- 35. Customer contact methods distribution by type.
-- 36. Order volume by employee and quarter.
-- 37. Average freight cost by shipper and region.
-- 38. Shipping delays analysis by shipper and region.
-- 39. Order values by customer category and region.
-- 40. Order distribution by employee and shipper.


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Task-2 Applied Business Rules on Database with Database Views


-- 1. Display total sales per product category for each month to identify monthly sales trends by category.

CREATE VIEW vw_MonthlySalesByProductCategory AS
SELECT 
    p.ProductCategoryID,
	pc.Name as ProductCategoryName,
    FORMAT(soh.OrderDate, 'yyyy-MM') AS SalesMonth,
    SUM(sod.LineTotal) AS TotalSales
FROM 
    SalesLT.SalesOrderHeader soh
JOIN 
    SalesLT.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN 
    SalesLT.Product p ON sod.ProductID = p.ProductID
JOIN 
	SalesLT.ProductCategory pc ON p.ProductCategoryID = pc.ProductCategoryID
GROUP BY 
    p.ProductCategoryID,
	pc.Name,
    FORMAT(soh.OrderDate, 'yyyy-MM');


-- 2. Show quarterly sales totals for each product in each region to assess product popularity across regions.

CREATE VIEW vw_QuarterySalesByProductAndRegion AS
SELECT
    p.Name AS Product,
    DATEPART(QUARTER, soh.OrderDate) AS SalesQuarter,
    a.City AS Region,
    SUM(sod.LineTotal) AS TotalSales
FROM 
    SalesLT.SalesOrderHeader soh
JOIN 
    SalesLT.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN 
    SalesLT.Product p ON sod.ProductID = p.ProductID
JOIN 
    SalesLT.Address a ON soh.ShipToAddressID = a.AddressID
GROUP BY 
    p.Name, DATEPART(QUARTER, soh.OrderDate), a.City;


-- 3. Display the number of purchases each customer made per year to evaluate customer engagement.

CREATE VIEW vw_SalesCountByCustomerAndYear AS
SELECT 
    c.CustomerID,
    YEAR(soh.OrderDate) AS SalesYear,
    COUNT(soh.SalesOrderID) AS TotalOrders
FROM 
    SalesLT.SalesOrderHeader soh
JOIN 
    SalesLT.Customer c ON soh.CustomerID = c.CustomerID
GROUP BY 
    c.CustomerID, YEAR(soh.OrderDate);


-- 4. Display average order value by month for each customer to identify high-value customers and seasonal trends.

CREATE VIEW vw_AverageOrderValueByMonthAndCustomer AS
SELECT 
    c.CustomerID,
    FORMAT(soh.OrderDate, 'yyyy-MM') AS OrderMonth,
    AVG(sod.LineTotal) AS AverageOrderValue
FROM 
    SalesLT.SalesOrderHeader soh
JOIN 
    SalesLT.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN 
    SalesLT.Customer c ON soh.CustomerID = c.CustomerID
GROUP BY 
    c.CustomerID, FORMAT(soh.OrderDate, 'yyyy-MM');


-- 5. Identify top-selling products by sales revenue each month to track demand and optimize stock.

CREATE VIEW vw_TopProductsBySalesRevenueAndMonth AS
SELECT 
    p.Name AS Product,
    FORMAT(soh.OrderDate, 'yyyy-MM') AS SalesMonth,
    SUM(sod.LineTotal) AS TotalRevenue
FROM 
    SalesLT.SalesOrderHeader soh
JOIN 
    SalesLT.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN 
    SalesLT.Product p ON sod.ProductID = p.ProductID
GROUP BY 
    p.Name, FORMAT(soh.OrderDate, 'yyyy-MM')


-- 6. Track the use of discounts across product categories each month to monitor discounting patterns.

CREATE VIEW vw_DiscountUtilizationByProductCategoryAndMonth AS
SELECT 
    pc.Name AS ProductCategory,
    FORMAT(soh.OrderDate, 'yyyy-MM') AS SalesMonth,
    SUM(sod.UnitPriceDiscount) AS TotalDiscount
FROM 
    SalesLT.SalesOrderHeader soh
JOIN 
    SalesLT.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN 
    SalesLT.Product p ON sod.ProductID = p.ProductID
JOIN 
    SalesLT.ProductCategory pc ON p.ProductCategoryID = pc.ProductCategoryID
GROUP BY 
    pc.Name, FORMAT(soh.OrderDate, 'yyyy-MM');


-- 7. Display the number of units sold for each product by sales channel to assess channel performance.

CREATE VIEW vw_SalesVolumeByProductAndSalesChannel AS
SELECT 
    p.Name AS Product,
    soh.OnlineOrderFlag AS SalesChannel,
    COUNT(sod.SalesOrderDetailID) AS SalesVolume
FROM 
    SalesLT.SalesOrderHeader soh
JOIN 
    SalesLT.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN 
    SalesLT.Product p ON sod.ProductID = p.ProductID
GROUP BY 
    p.Name, soh.OnlineOrderFlag;


-- 8. Show the distribution of customers by location for each product category to guide marketing efforts.

CREATE VIEW vw_CustomerLocationDistributionByProductCategory AS
SELECT 
    pc.Name AS ProductCategory,
    a.City AS CustomerLocation,
    COUNT(c.CustomerID) AS CustomerCount
FROM 
    SalesLT.Customer c
JOIN 
    SalesLT.CustomerAddress ca ON c.CustomerID = ca.CustomerID
JOIN 
    SalesLT.Address a ON ca.AddressID = a.AddressID
JOIN 
    SalesLT.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
JOIN 
    SalesLT.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN 
    SalesLT.Product p ON sod.ProductID = p.ProductID
JOIN 
    SalesLT.ProductCategory pc ON p.ProductCategoryID = pc.ProductCategoryID
GROUP BY 
    pc.Name, a.City;


-- 9. Calculate inventory turnover rate for each product model per month to manage stock more effectively.

CREATE VIEW vw_InventoryTurnoverByProductModelAndMonth AS
SELECT 
    pm.Name AS ProductModel,
    FORMAT(soh.OrderDate, 'yyyy-MM') AS SalesMonth,
    COUNT(sod.SalesOrderDetailID) AS InventoryTurnover
FROM 
    SalesLT.SalesOrderHeader soh
JOIN 
    SalesLT.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN 
    SalesLT.Product p ON sod.ProductID = p.ProductID
JOIN 
    SalesLT.ProductModel pm ON p.ProductModelID = pm.ProductModelID
GROUP BY 
    pm.Name, FORMAT(soh.OrderDate, 'yyyy-MM');


-- 10. Display year-over-year sales growth by product category to track growth and adjust strategies.

CREATE VIEW vw_YearOverYearSalesGrowthByProductCategory AS
SELECT 
    pc.Name AS ProductCategory,
    YEAR(soh.OrderDate) AS SalesYear,
    SUM(sod.LineTotal) AS TotalSales
FROM 
    SalesLT.SalesOrderHeader soh
JOIN 
    SalesLT.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN 
    SalesLT.Product p ON sod.ProductID = p.ProductID
JOIN 
    SalesLT.ProductCategory pc ON p.ProductCategoryID = pc.ProductCategoryID
GROUP BY 
    pc.Name, YEAR(soh.OrderDate);


-- 11. Display the total enrollment count for each program in each year.

CREATE VIEW vw_YearlyEnrollmentByProgram AS
SELECT 
    sp.programCode AS Program,
    YEAR(py.transactionDate) AS Year,
    COUNT(sp.studentNumber) AS TotalEnrollment
FROM 
    StudentProgram sp
JOIN 
    Payment py ON sp.studentNumber = py.studentNumber
JOIN
	Program p ON sp.programCode = p.code
GROUP BY 
    sp.programCode, YEAR(py.transactionDate) ;


-- 12. Show the count of students in each country and academic status, providing insights into geographic diversity and academic performance.

CREATE VIEW vw_StudentByCountryAndAcademicStatus AS
SELECT 
    p.countryCode AS Country,
    s.academicStatusCode AS AcademicStatus,
	acs.explanation as AcademicStatusMeaning,
    COUNT(s.number) AS StudentCount
FROM 
    Student s
JOIN 
	AcademicStatus acs ON s.academicStatusCode = acs.code
JOIN 
    Person p ON s.number = p.number
GROUP BY 
    p.countryCode, s.academicStatusCode, acs.explanation;


-- 13. Display the number of penalties issued to students within each program by year, helping track disciplinary trends.

CREATE VIEW vw_TotalPenaltiesIssuedByProgramAndYear AS
SELECT 
    sp.programCode AS Program,
    YEAR(so.date) AS Year,
    COUNT(so.id) AS PenaltyCount
FROM 
    StudentOffence so
JOIN 
    StudentProgram sp ON so.studentNumber = sp.studentNumber
GROUP BY 
    sp.programCode, YEAR(so.date);


-- 14.	Calculate the total amount of fees collected by each payment method, grouped by year, to identify payment trends and preferences.

CREATE VIEW vw_AnnualFeesCollectedbyPaymentMethod AS
SELECT 
    pm.explanation AS PaymentMethod,
    YEAR(p.transactionDate) AS Year,
    SUM(p.amount) AS TotalCollected
FROM 
    Payment p
JOIN 
    PaymentMethod pm ON p.paymentMethodId = pm.id
GROUP BY 
    pm.explanation, YEAR(p.transactionDate);


-- 15. Display the number of courses offered on each campus per semester, allowing management to see course distribution across campuses.

CREATE VIEW vw_CourseOfferingsBySemesterAndCampus AS
SELECT 
    e.CampusCode AS Campus,
    co.sessionCode AS Semester,
    COUNT(co.id) AS CourseCount
FROM 
    CourseOffering co
JOIN 
    Employee e ON co.employeeNumber = e.number
GROUP BY 
    e.campusCode, co.sessionCode;


-- 16. Display the number of offenses recorded for students, by each academic year and penalty type.

CREATE VIEW vw_StudentOffenseRecordsByAcademicYearAndPenaltyCode AS
SELECT 
    YEAR(so.date) AS AcademicYear,
    so.penaltyCode AS PenaltyCode,
    COUNT(so.id) AS OffenseCount
FROM 
    StudentOffence so
JOIN 
    Student s ON so.studentNumber = s.number
GROUP BY 
    YEAR(so.date), so.penaltyCode;


-- 17. Calculate the average final marks of students for each course within a program, helping to assess student performance in each course.

CREATE VIEW vw_AverageFinalMarksByCourseAndProgram AS
SELECT 
    pc.courseNumber AS Course,
    sp.programCode AS Program,
    AVG(cs.finalMark) AS AverageMark
FROM 
    CourseStudent cs
JOIN 
    StudentProgram sp ON cs.studentNumber = sp.studentNumber
JOIN 
    ProgramCourse pc ON sp.programCode = pc.programCode
GROUP BY 
    pc.courseNumber, sp.programCode;


-- 18. Show the total amount invoiced to students per semester for each program, giving insight into program-specific revenue.

CREATE VIEW vw_StudentInvoiceTotalsBySemesterAndProgram AS
SELECT 
    sp.programCode AS Program,
    sp.semester AS Semester,
    SUM(py.amount) AS TotalInvoiceAmount
FROM 
    Payment py
JOIN 
    StudentProgram sp ON sp.studentNumber = py.studentNumber
GROUP BY 
    sp.programCode, sp.semester;


-- 19. Count the number of logs generated per day, by each user and audit category, to monitor user activity levels and focus areas.

CREATE VIEW vw_DailyAuditLogsByUserAndCategory AS
SELECT 
    a.date AS LogDate,
    a.userId AS UserID,
    ac.explanation AS Category,
    COUNT(a.id) AS LogCount
FROM 
    Audit a
JOIN 
    AuditCategory ac ON a.auditCategoryCode = ac.code
GROUP BY 
    a.date, a.userId, ac.explanation;


-- 20. Display the enrollment count of international and domestic students for each program, by year, showing trends in student demographics.

CREATE VIEW vw_AnnualInternationalVsDomesticStudentEnrollmentByProgram AS
SELECT 
    sp.programCode AS Program,
    YEAR(py.transactionDate) AS Year,
    s.isInternational AS StudentType,
    COUNT(s.number) AS EnrollmentCount
FROM 
    Student s
JOIN 
    StudentProgram sp ON s.number = sp.studentNumber
JOIN 
    Payment py ON s.number = py.studentNumber
GROUP BY 
    sp.programCode, YEAR(py.transactionDate), s.isInternational;


-- 21. Employee count by title and company

CREATE VIEW HR.EmployeeCountByTitleAndCompany AS
SELECT *
FROM (
    SELECT c.name as CompanyName, e.title, COUNT(*) as EmpCount
    FROM HR.Employees e
    JOIN HR.Companies c ON e.companyId = c.companyId
    GROUP BY c.name, e.title
) AS SourceTable
PIVOT (
    SUM(EmpCount)
    FOR title IN ([CEO], [manger], [Certified financial planner], [Network administrator], [Network engineer])
) AS PivotTable;


-- 22. Average employee age by title and courtesy title
CREATE VIEW HR.EmployeeAgeByTitleAndCourtesy AS
SELECT *
FROM (
    SELECT
        title,
        courtesyTitle,
        DATEDIFF(YEAR, birthdate, GETDATE()) as Age
    FROM HR.Employees
) AS SourceTable
PIVOT (
    AVG(Age)
    FOR courtesyTitle IN ([rs])
) AS PivotTable;


-- 23. Employee hire patterns by year and region
CREATE VIEW HR.EmployeeHirePatternsByRegion AS
SELECT *
FROM (
    SELECT
        YEAR(e.hiredate) as HireYear,
        a.region,
        COUNT(*) as HireCount
    FROM HR.Employees e
    JOIN Info.Addresses a ON e.addressId = a.addressId
    GROUP BY YEAR(e.hiredate), a.region
) AS SourceTable
PIVOT (
    SUM(HireCount)
    FOR region IN ([WA], [Waterloo])
) AS PivotTable;


-- 24. Employee distribution across cities and titles
CREATE VIEW HR.vw_EmployeeDistributionByCityTitle AS
SELECT *
FROM (
    SELECT
        a.city,
        e.title,
        COUNT(*) as EmpCount
    FROM HR.Employees e
    JOIN Info.Addresses a ON e.addressId = a.addressId
    GROUP BY a.city, e.title
) AS SourceTable
PIVOT (
    SUM(EmpCount)
    FOR title IN ([CEO], [manger], [Certified financial planner], [Network administrator], [Network engineer])
) AS PivotTable;


-- 25. Employee counts by company size and region
CREATE VIEW HR.vw_EmployeeCountByCompanySizeRegion AS
WITH CompanySize AS (
    SELECT
        c.companyId,
        CASE
            WHEN COUNT(*) <= 10 THEN 'Small'
            WHEN COUNT(*) <= 50 THEN 'Medium'
            ELSE 'Large'
        END as CompanySize
    FROM HR.Companies c
    JOIN HR.Employees e ON c.companyId = e.companyId
    GROUP BY c.companyId
)
SELECT *
FROM (
    SELECT
        cs.CompanySize,
        a.region,
        COUNT(*) as EmpCount
    FROM HR.Employees e
    JOIN CompanySize cs ON e.companyId = cs.companyId
    JOIN Info.Addresses a ON e.addressId = a.addressId
    GROUP BY cs.CompanySize, a.region
) AS SourceTable
PIVOT (
    SUM(EmpCount)
    FOR region IN ([WA], [Waterloo])
) AS PivotTable;


-- 26. Product count by category and supplier
CREATE VIEW Production.vw_ProductCountByCategorySupplier AS
SELECT *
FROM (
    SELECT
        c.name as CategoryName,
        s.supplierId,
        COUNT(*) as ProductCount
    FROM Production.Products p
    JOIN Production.Categories c ON p.categoryId = c.categoryId
    JOIN Production.Suppliers s ON p.supplierId = s.supplierId
    GROUP BY c.name, s.supplierId
) AS SourceTable
PIVOT (
    SUM(ProductCount)
    FOR CategoryName IN ([Electronics], [Kindle], [Device], [Cloth Acces], [Cell Phones], [Camera Photo], [Books], [Beauty], [Baby Prod], [Automotive])
) AS PivotTable;


-- 27. Average product price by category and supplier
CREATE VIEW Production.vw_AvgPriceByCategorySupplier AS
SELECT *
FROM (
    SELECT
        c.name as CategoryName,
        s.supplierId,
        p.price as AvgPrice
    FROM Production.Products p
    JOIN Production.Categories c ON p.categoryId = c.categoryId
    JOIN Production.Suppliers s ON p.supplierId = s.supplierId
) AS SourceTable
PIVOT (
    AVG(AvgPrice)
    FOR CategoryName IN ([Electronics], [Kindle], [Device], [Cloth Acces], [Cell Phones], [Camera Photo], [Books], [Beauty], [Baby Prod], [Automotive])
) AS PivotTable;


-- 28. Discontinued product percentage by category and supplier
CREATE VIEW Production.vw_DiscontinuedProductPercentage AS
SELECT *
FROM (
    SELECT
        c.name as CategoryName,
        s.supplierId,
        CAST(AVG(CAST(discontinued as FLOAT)) * 100 as DECIMAL(5,2)) as DiscontinuedPct
    FROM Production.Products p
    JOIN Production.Categories c ON p.categoryId = c.categoryId
    JOIN Production.Suppliers s ON p.supplierId = s.supplierId
    GROUP BY c.name, s.supplierId
) AS SourceTable
PIVOT (
    AVG(DiscontinuedPct)
    FOR CategoryName IN ([Electronics], [Kindle], [Device], [Cloth Acces], [Cell Phones], [Camera Photo], [Books], [Beauty], [Baby Prod], [Automotive])
) AS PivotTable;


-- 29. Product tag distribution across categories
CREATE VIEW Production.vw_ProductTagDistribution AS
SELECT *
FROM (
    SELECT
        c.name as CategoryName,
        t.tagName,
        COUNT(*) as TagCount
    FROM Production.Products p
    JOIN Production.Categories c ON p.categoryId = c.categoryId
    JOIN Info.Tag t ON p.productId = t.productId
    GROUP BY c.name, t.tagName
) AS SourceTable
PIVOT (
    SUM(TagCount)
    FOR CategoryName IN ([Electronics], [Kindle], [Device], [Cloth Acces], [Cell Phones], [Camera Photo], [Books], [Beauty], [Baby Prod], [Automotive])
) AS PivotTable;


-- 30. Product counts by price ranges and categories
CREATE VIEW Production.vw_ProductCountsByPriceRange AS
WITH PriceRanges AS (
    SELECT
        productId,
        categoryId,
        CASE
            WHEN price < 10 THEN 'Cheap'
            WHEN price < 50 THEN 'Normal'
            ELSE 'Expensive'
        END as PriceRange
    FROM Production.Products
)
SELECT *
FROM (
    SELECT
        pr.PriceRange,
        c.name as CategoryName,
        COUNT(*) as ProductCount
    FROM PriceRanges pr
    JOIN Production.Categories c ON pr.categoryId = c.categoryId
    GROUP BY pr.PriceRange, c.name
) AS SourceTable
PIVOT (
    SUM(ProductCount)
    FOR CategoryName IN ([Electronics], [Kindle], [Device], [Cloth Acces], [Cell Phones], [Camera Photo], [Books], [Beauty], [Baby Prod], [Automotive])
) AS PivotTable;


-- 31. B2B vs B2C customer distribution by city
CREATE VIEW Sales.vw_CustomerDistributionByCity AS
SELECT *
FROM (
    SELECT
        a.city,
        'B2B' as CustomerType,
        COUNT(*) as CustomerCount
    FROM Sales.B2BCustomers b
    JOIN Info.Addresses a ON b.addressId = a.addressId
    GROUP BY a.city
    UNION ALL
    SELECT
        a.city,
        'B2C' as CustomerType,
        COUNT(*) as CustomerCount
    FROM Sales.B2CCustomers c
    JOIN Info.Addresses a ON c.addressId = a.addressId
    GROUP BY a.city
) AS SourceTable
PIVOT (
    SUM(CustomerCount)
    FOR CustomerType IN ([B2B], [B2C])
) AS PivotTable;


-- 32. Frequent customer percentage by region
CREATE VIEW Sales.vw_FrequentCustomerPercentageByRegion AS
SELECT *
FROM (
    SELECT
        a.region,
        'B2B' as CustomerType,
        CAST(AVG(CAST(frequent as FLOAT)) * 100 as DECIMAL(5,2)) as FrequentPct
    FROM Sales.B2BCustomers b
    JOIN Info.Addresses a ON b.addressId = a.addressId
    GROUP BY a.region
    UNION ALL
    SELECT
        a.region,
        'B2C' as CustomerType,
        CAST(AVG(CAST(frequent as FLOAT)) * 100 as DECIMAL(5,2)) as FrequentPct
    FROM Sales.B2CCustomers c
    JOIN Info.Addresses a ON c.addressId = a.addressId
    GROUP BY a.region
) AS SourceTable
PIVOT (
    AVG(FrequentPct)
    FOR CustomerType IN ([B2B], [B2C])
) AS PivotTable;


-- 33. Customer concentration by county and type
CREATE VIEW Sales.vw_CustomerConcentrationByCounty AS
SELECT *
FROM (
    SELECT
        a.county,
        'B2B' as CustomerType,
        COUNT(*) as CustomerCount
    FROM Sales.B2BCustomers b
    JOIN Info.Addresses a ON b.addressId = a.addressId
    GROUP BY a.county
    UNION ALL
    SELECT
        a.county,
        'B2C' as CustomerType,
        COUNT(*) as CustomerCount
    FROM Sales.B2CCustomers c
    JOIN Info.Addresses a ON c.addressId = a.addressId
    GROUP BY a.county
) AS SourceTable
PIVOT (
    SUM(CustomerCount)
    FOR CustomerType IN ([B2B], [B2C])
) AS PivotTable;


-- 34. Company-affiliated vs individual customer distribution by region
CREATE VIEW Sales.vw_CompanyAffiliationByRegion AS
SELECT *
FROM (
    SELECT
        a.region,
        CASE WHEN companyId IS NOT NULL THEN 'Company' ELSE 'Individual' END as AffiliationType,
        COUNT(*) as CustomerCount
    FROM (
        SELECT addressId, companyId FROM Sales.B2BCustomers
        UNION ALL
        SELECT addressId, companyId FROM Sales.B2CCustomers
    ) customers
    JOIN Info.Addresses a ON customers.addressId = a.addressId
    GROUP BY a.region, CASE WHEN companyId IS NOT NULL THEN 'Company' ELSE 'Individual' END
) AS SourceTable
PIVOT (
    SUM(CustomerCount)
    FOR AffiliationType IN ([Company], [Individual])
) AS PivotTable;


-- 35. Customer contact methods distribution by type
CREATE VIEW Sales.vw_CustomerContactMethodDistribution AS
SELECT *
FROM (
    SELECT
        CASE
            WHEN c.fax IS NOT NULL AND c.phone IS NOT NULL THEN 'Both'
            WHEN c.fax IS NOT NULL THEN 'Fax Only'
            ELSE 'Phone Only'
        END as ContactMethod,
        'B2B' as CustomerType,
        COUNT(*) as CustomerCount
    FROM Sales.B2BCustomers b
    JOIN Info.Contacts c ON b.contactId = c.contactId
    GROUP BY CASE
        WHEN c.fax IS NOT NULL AND c.phone IS NOT NULL THEN 'Both'
        WHEN c.fax IS NOT NULL THEN 'Fax Only'
        ELSE 'Phone Only'
    END
    UNION ALL
    SELECT
        CASE
            WHEN c.fax IS NOT NULL AND c.phone IS NOT NULL THEN 'Both'
            WHEN c.fax IS NOT NULL THEN 'Fax Only'
            ELSE 'Phone Only'
        END as ContactMethod,
        'B2C' as CustomerType,
        COUNT(*) as CustomerCount
    FROM Sales.B2CCustomers b
    JOIN Info.Contacts c ON b.contactId = c.contactId
    GROUP BY CASE
        WHEN c.fax IS NOT NULL AND c.phone IS NOT NULL THEN 'Both'
        WHEN c.fax IS NOT NULL THEN 'Fax Only'
        ELSE 'Phone Only'
    END
) AS SourceTable
PIVOT (
    SUM(CustomerCount)
    FOR CustomerType IN ([B2B], [B2C])
) AS PivotTable;


-- 36. Order volume by employee and quarter
CREATE VIEW Sales.vw_OrderVolumeByEmployeeQuarter AS
SELECT *
FROM (
    SELECT
        e.employeeId,
        'Q' + CAST(DATEPART(QUARTER, o.requiredDate) as VARCHAR) as Quarter,
        COUNT(*) as OrderCount
    FROM Sales.B2BOrders o
    JOIN HR.Employees e ON o.employeeId = e.employeeId
    WHERE YEAR(o.requiredDate) = YEAR(GETDATE())
    GROUP BY e.employeeId, DATEPART(QUARTER, o.requiredDate)
) AS SourceTable
PIVOT (
    SUM(OrderCount)
    FOR Quarter IN ([Q1], [Q2], [Q3], [Q4])
) AS PivotTable;


-- 37. Average freight cost by shipper and region
CREATE VIEW Sales.vw_FreightCostByShipperRegion AS
SELECT *
FROM (
    SELECT
        s.shipperId,
        a.region,
        AVG(o.freight) as AvgFreight
    FROM Sales.B2BOrders o
    JOIN Sales.Shippers s ON o.shipperId = s.shipperId
    JOIN Info.Addresses a ON o.shipAddressId = a.addressId
    GROUP BY s.shipperId, a.region
) AS SourceTable
PIVOT (
    AVG(AvgFreight)
    FOR region IN ([WA], [Waterloo])
) AS PivotTable;


-- 38. Shipping delays analysis by shipper and region
CREATE VIEW Sales.vw_ShippingDelaysByRegion AS
SELECT *
FROM (
    SELECT
        s.shipperId,
        a.region,
        AVG(DATEDIFF(day, requiredDate, shippedDate)) as AvgDelay
    FROM Sales.B2BOrders o
    JOIN Sales.Shippers s ON o.shipperId = s.shipperId
    JOIN Info.Addresses a ON o.shipAddressId = a.addressId
    WHERE shippedDate IS NOT NULL
    GROUP BY s.shipperId, a.region
) AS SourceTable
PIVOT (
    AVG(AvgDelay)
    FOR region IN ([WA], [Waterloo])
) AS PivotTable;


-- 39. Order values by customer category and region
CREATE VIEW Sales.vw_OrderValuesByCustomerCategory AS
SELECT *
FROM (
    SELECT
        a.region,
        CASE
            WHEN b.frequent = 1 THEN 'Frequent'
            ELSE 'Regular'
        END as CustomerCategory,
        COUNT(*) as OrderCount
    FROM Sales.B2BOrders o
    JOIN Sales.B2BCustomers b ON o.customerId = b.customerId
    JOIN Info.Addresses a ON b.addressId = a.addressId
    GROUP BY a.region, CASE WHEN b.frequent = 1 THEN 'Frequent' ELSE 'Regular' END
) AS SourceTable
PIVOT (
    SUM(OrderCount)
    FOR region IN ([WA], [Waterloo])
) AS PivotTable;


-- 40. Order distribution by employee and shipper
CREATE VIEW Sales.vw_OrderDistributionByEmployeeShipper AS
SELECT *
FROM (
    SELECT
        e.employeeId,
        s.shipperId,
        COUNT(*) as OrderCount
    FROM Sales.B2BOrders o
    JOIN HR.Employees e ON o.employeeId = e.employeeId
    JOIN Sales.Shippers s ON o.shipperId = s.shipperId
    GROUP BY e.employeeId, s.shipperId
) AS SourceTable
PIVOT (
    SUM(OrderCount)
    FOR shipperId IN ([1], [2], [3], [4])
) AS PivotTable;


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Task-3: Testing the Views of the Business Rules

-- View_1: Display total sales per product category for each month to identify monthly sales trends by category.
Select * from vw_MonthlySalesByProductCategory WHERE TotalSales > 50000;

-- View_2: Show quarterly sales totals for each product in each region to assess product popularity across regions.
Select * from vw_QuarterySalesByProductAndRegion WHERE Region = 'Liverpool';

-- View_3: Display the number of purchases each customer made per year to evaluate customer engagement.
Select * from vw_SalesCountByCustomerAndYear;

-- View_4: Display average order value by month for each customer to identify high-value customers and seasonal trends.
Select * from vw_AverageOrderValueByMonthAndCustomer WHERE AverageOrderValue >= 1000;

-- View_5: Identify top-selling products by sales revenue each month to track demand and optimize stock.
Select * from vw_TopProductsBySalesRevenueAndMonth ORDER BY TotalRevenue DESC;

-- View_6: Track the use of discounts across product categories each month to monitor discounting patterns.
Select * from vw_DiscountUtilizationByProductCategoryAndMonth WHERE TotalDiscount > 1;

-- View_7: Display the number of units sold for each product by sales channel to assess channel performance.
Select * from vw_SalesVolumeByProductAndSalesChannel;

-- View_8: Show the distribution of customers by location for each product category to guide marketing efforts.
Select * from vw_CustomerLocationDistributionByProductCategory WHERE CustomerCount > 10;

-- View_9: Calculate inventory turnover rate for each product model per month to manage stock more effectively.
Select * from vw_InventoryTurnoverByProductModelAndMonth WHERE InventoryTurnover < 10;

-- View_10: Display year-over-year sales growth by product category to track growth and adjust strategies.
Select * from vw_YearOverYearSalesGrowthByProductCategory WHERE TotalSales > 100000;

-- View_11: Display the total enrollment count for each program in each year.
Select * from vw_YearlyEnrollmentByProgram;

-- View_12: Show the count of students in each country and academic status, providing insights into geographic diversity and academic performance.
Select * from vw_StudentByCountryAndAcademicStatus WHERE StudentCount < 20;

-- View_13: Display the number of penalties issued to students within each program by year, helping track disciplinary trends.
Select * from vw_TotalPenaltiesIssuedByProgramAndYear;

-- View_14: Calculate the total amount of fees collected by each payment method, grouped by year, to identify payment trends and preferences.
Select * from vw_AnnualFeesCollectedbyPaymentMethod;

-- View_15: Display the number of courses offered on each campus per semester, allowing management to see course distribution across campuses.
Select * from vw_CourseOfferingsBySemesterAndCampus WHERE Semester='F20';

-- View_16: Display the number of offenses recorded for students, by each academic year and penalty type.
Select * from vw_StudentOffenseRecordsByAcademicYearAndPenaltyCode;

-- View_17: Calculate the average final marks of students for each course within a program, helping to assess student performance in each course.
Select * from vw_AverageFinalMarksByCourseAndProgram WHERE Course ='INFO1570';

-- View_18: Show the total amount invoiced to students per semester for each program, giving insight into program-specific revenue.
Select * from vw_StudentInvoiceTotalsBySemesterAndProgram;

-- View_19: Count the number of logs generated per day, by each user and audit category, to monitor user activity levels and focus areas.
Select * from vw_DailyAuditLogsByUserAndCategory;

-- View_20: Display the enrollment count of international and domestic students for each program, by year, showing trends in student demographics.
Select * from vw_AnnualInternationalVsDomesticStudentEnrollmentByProgram WHERE StudentType = 0;

-- HR Schema Views
-- View_21. Employee count by title and company
SELECT CompanyName, [CEO], [manger] as Managers, [Network administrator] + [Network engineer] as TechStaff
FROM HR.EmployeeCountByTitleAndCompany
WHERE [CEO] > 0
ORDER BY CompanyName;

-- View_22. Employee age by title and courtesy
SELECT title, [rs] as AverageAge
FROM HR.EmployeeAgeByTitleAndCourtesy
WHERE [rs] > 30
ORDER BY [rs] DESC;

-- View_23. Employee hire patterns by region
SELECT HireYear, [WA], [Waterloo]
FROM HR.EmployeeHirePatternsByRegion
WHERE HireYear >= 2020
ORDER BY HireYear;

-- View_24. Employee distribution by city and title
SELECT city, [manger] as Managers, [Network administrator] as AdminStaff
FROM HR.vw_EmployeeDistributionByCityTitle
WHERE [manger] > 0
ORDER BY [manger] DESC;

-- View_25. Employee counts by company size and region
SELECT CompanySize, [WA], [Waterloo]
FROM HR.vw_EmployeeCountByCompanySizeRegion
ORDER BY CompanySize;

-- Production Schema Views
-- View_26. Product count by category and supplier
SELECT supplierId, [Electronics], [Cell Phones], [Books]
FROM Production.vw_ProductCountByCategorySupplier
WHERE [Electronics] > 0
ORDER BY [Electronics] DESC;

-- View_27. Average product price by category and supplier
SELECT supplierId, [Electronics] as ElectronicsAvgPrice, [Books] as BooksAvgPrice
FROM Production.vw_AvgPriceByCategorySupplier
WHERE [Electronics] > 100
ORDER BY [Electronics] DESC;

-- View_28. Discontinued product percentage
SELECT supplierId, [Electronics] as ElectronicsDiscontinued, [Books] as BooksDiscontinued
FROM Production.vw_DiscontinuedProductPercentage
WHERE [Electronics] > 0
ORDER BY [Electronics] DESC;

-- View_29. Product tag distribution
SELECT tagName, [Electronics], [Books], [Beauty]
FROM Production.vw_ProductTagDistribution
WHERE [Electronics] > 0
ORDER BY [Electronics] DESC;

-- View_30. Product counts by price range
SELECT PriceRange, [Electronics], [Books], [Beauty]
FROM Production.vw_ProductCountsByPriceRange
ORDER BY PriceRange;

-- Sales Schema Views
-- View_31. Customer distribution by city
SELECT city, [B2B], [B2C]
FROM Sales.vw_CustomerDistributionByCity
WHERE [B2B] > 0
ORDER BY [B2B] DESC;

-- View_32. Frequent customer percentage by region
SELECT region, [B2B] as B2BFrequent, [B2C] as B2CFrequent
FROM Sales.vw_FrequentCustomerPercentageByRegion
ORDER BY [B2B] DESC;

-- View_33. Customer concentration by county
SELECT county, [B2B], [B2C]
FROM Sales.vw_CustomerConcentrationByCounty
WHERE [B2B] + [B2C] > 100
ORDER BY [B2B] DESC;

-- View_34. Company affiliation by region
SELECT region, [Company], [Individual]
FROM Sales.vw_CompanyAffiliationByRegion
WHERE [Company] > 0
ORDER BY [Company] DESC;

-- View_35. Customer contact method distribution
SELECT ContactMethod, [B2B], [B2C]
FROM Sales.vw_CustomerContactMethodDistribution
ORDER BY ContactMethod;

-- View_36. Order volume by employee quarter
SELECT employeeId, [Q1], [Q2], [Q3], [Q4]
FROM Sales.vw_OrderVolumeByEmployeeQuarter
WHERE [Q1] > 0
ORDER BY [Q1] DESC;

-- View_37. Freight cost by shipper region
SELECT shipperId, [WA], [Waterloo]
FROM Sales.vw_FreightCostByShipperRegion
WHERE [WA] > 50
ORDER BY [WA] DESC;

-- View_38. Shipping delays by region
SELECT shipperId, [WA] as WADelays, [Waterloo] as WaterlooDelays
FROM Sales.vw_ShippingDelaysByRegion
WHERE [WA] > 0
ORDER BY [WA] DESC;

-- View_39. Order values by customer category
SELECT CustomerCategory, [WA], [Waterloo]
FROM Sales.vw_OrderValuesByCustomerCategory
ORDER BY CustomerCategory;

-- View_40. Order distribution by employee and shipper
SELECT employeeId, [1] as Shipper1, [2] as Shipper2, [3] as Shipper3
FROM Sales.vw_OrderDistributionByEmployeeShipper
WHERE [1] > 0
ORDER BY [1] DESC;


-- Note:
-- Hello Professor,
-- In Task-3, the objective was to test the views by performing SELECT, INSERT, UPDATE, and DELETE operations. 
-- However, due to the complexity of the views, we encountered limitations that prevent direct INSERT, UPDATE, and DELETE testing.
-- The views created in this task involve joins, aggregations, and grouped data across multiple tables.
-- SQL Server considers these views as read-only, as they contain calculations and summaries that cannot directly map back to their base tables. For instance:
-- Aggregated Data: Views that include aggregated functions (e.g., SUM, COUNT, AVG) cannot be directly updated or modified
-- because SQL Server has no straightforward way to propagate these changes back to the underlying data.
-- Joins: Views with data joined from multiple tables require explicit instructions on how to handle data modifications,
-- as changes may affect multiple tables in complex ways.