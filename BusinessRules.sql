-- 1. Employee count by title and company
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

-- 2. Average employee age by title and courtesy title
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

-- 3. Employee hire patterns by year and region
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

-- 4. Employee distribution across cities and titles
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

-- 5. Employee counts by company size and region
--- 5. Employee counts by employee count and region
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

-- 6. Product count by category and supplier
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

-- 7. Average product price by category and supplier
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

-- 8. Discontinued product percentage by category and supplier
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

-- 9. Product tag distribution across categories
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

-- 10. Product counts by price ranges and categories
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

-- 11. B2B vs B2C customer distribution by city
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

-- 12. Frequent customer percentage by region
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

-- 13. Customer concentration by county and type
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

-- 14. Company-affiliated vs individual customer distribution by region
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

-- 15. Customer contact methods distribution by type
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

-- 16. Order volume by employee and quarter
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

-- 17. Average freight cost by shipper and region
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

-- 18. Shipping delays analysis by shipper and region
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

-- 19. Order values by customer category and region
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

-- 20. Order distribution by employee and shipper
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



-- HR Schema Views
-- 1. Employee count by title and company
SELECT CompanyName, [CEO], [manger] as Managers, [Network administrator] + [Network engineer] as TechStaff
FROM HR.EmployeeCountByTitleAndCompany
WHERE [CEO] > 0
ORDER BY CompanyName;

-- 2. Employee age by title and courtesy
SELECT title, [rs] as AverageAge
FROM HR.EmployeeAgeByTitleAndCourtesy
WHERE [rs] > 30
ORDER BY [rs] DESC;

-- 3. Employee hire patterns by region
SELECT HireYear, [WA], [Waterloo]
FROM HR.EmployeeHirePatternsByRegion
WHERE HireYear >= 2020
ORDER BY HireYear;

-- 4. Employee distribution by city and title
SELECT city, [manger] as Managers, [Network administrator] as AdminStaff
FROM HR.vw_EmployeeDistributionByCityTitle
WHERE [manger] > 0
ORDER BY [manger] DESC;

-- 5. Employee counts by company size and region
SELECT CompanySize, [WA], [Waterloo]
FROM HR.vw_EmployeeCountByCompanySizeRegion
ORDER BY CompanySize;

-- Production Schema Views
-- 6. Product count by category and supplier
SELECT supplierId, [Electronics], [Cell Phones], [Books]
FROM Production.vw_ProductCountByCategorySupplier
WHERE [Electronics] > 0
ORDER BY [Electronics] DESC;

-- 7. Average product price by category and supplier
SELECT supplierId, [Electronics] as ElectronicsAvgPrice, [Books] as BooksAvgPrice
FROM Production.vw_AvgPriceByCategorySupplier
WHERE [Electronics] > 100
ORDER BY [Electronics] DESC;

-- 8. Discontinued product percentage
SELECT supplierId, [Electronics] as ElectronicsDiscontinued, [Books] as BooksDiscontinued
FROM Production.vw_DiscontinuedProductPercentage
WHERE [Electronics] > 0
ORDER BY [Electronics] DESC;

-- 9. Product tag distribution
SELECT tagName, [Electronics], [Books], [Beauty]
FROM Production.vw_ProductTagDistribution
WHERE [Electronics] > 0
ORDER BY [Electronics] DESC;

-- 10. Product counts by price range
SELECT PriceRange, [Electronics], [Books], [Beauty]
FROM Production.vw_ProductCountsByPriceRange
ORDER BY PriceRange;

-- Sales Schema Views
-- 11. Customer distribution by city
SELECT city, [B2B], [B2C]
FROM Sales.vw_CustomerDistributionByCity
WHERE [B2B] > 0
ORDER BY [B2B] DESC;

-- 12. Frequent customer percentage by region
SELECT region, [B2B] as B2BFrequent, [B2C] as B2CFrequent
FROM Sales.vw_FrequentCustomerPercentageByRegion
ORDER BY [B2B] DESC;

-- 13. Customer concentration by county
SELECT county, [B2B], [B2C]
FROM Sales.vw_CustomerConcentrationByCounty
WHERE [B2B] + [B2C] > 100
ORDER BY [B2B] DESC;

-- 14. Company affiliation by region
SELECT region, [Company], [Individual]
FROM Sales.vw_CompanyAffiliationByRegion
WHERE [Company] > 0
ORDER BY [Company] DESC;

-- 15. Customer contact method distribution
SELECT ContactMethod, [B2B], [B2C]
FROM Sales.vw_CustomerContactMethodDistribution
ORDER BY ContactMethod;

-- 16. Order volume by employee quarter
SELECT employeeId, [Q1], [Q2], [Q3], [Q4]
FROM Sales.vw_OrderVolumeByEmployeeQuarter
WHERE [Q1] > 0
ORDER BY [Q1] DESC;

-- 17. Freight cost by shipper region
SELECT shipperId, [WA], [Waterloo]
FROM Sales.vw_FreightCostByShipperRegion
WHERE [WA] > 50
ORDER BY [WA] DESC;

-- 18. Shipping delays by region
SELECT shipperId, [WA] as WADelays, [Waterloo] as WaterlooDelays
FROM Sales.vw_ShippingDelaysByRegion
WHERE [WA] > 0
ORDER BY [WA] DESC;

-- 19. Order values by customer category
SELECT CustomerCategory, [WA], [Waterloo]
FROM Sales.vw_OrderValuesByCustomerCategory
ORDER BY CustomerCategory;

-- 20. Order distribution by employee and shipper
SELECT employeeId, [1] as Shipper1, [2] as Shipper2, [3] as Shipper3
FROM Sales.vw_OrderDistributionByEmployeeShipper
WHERE [1] > 0
ORDER BY [1] DESC;