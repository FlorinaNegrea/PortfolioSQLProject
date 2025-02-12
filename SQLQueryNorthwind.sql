-- ============================
--        ORDERS (Comenzi)
-- ============================

-- 1. Display all orders from the Orders table, sorted by OrderDate.
SELECT * 
FROM Orders
ORDER BY OrderDate;

-- 2. Display only the orders placed in the year 1997, sorted by OrderDate.
SELECT * 
FROM Orders
WHERE YEAR(OrderDate) = 1997
ORDER BY OrderDate;

-- 3. Display the total number of orders placed in each month of 1997, sorted in ascending order by month.
SELECT MONTH(OrderDate) AS Month, COUNT(*) AS TotalOrders
FROM Orders
WHERE YEAR(OrderDate) = 1997
GROUP BY MONTH(OrderDate)
ORDER BY MONTH(OrderDate);

-- 4. Display the top 5 months with the highest number of orders placed in 1997.
SELECT TOP 5 MONTH(OrderDate) AS Month, COUNT(*) AS TotalOrders
FROM Orders
WHERE YEAR(OrderDate) = 1997
GROUP BY MONTH(OrderDate)
ORDER BY COUNT(*) DESC;


-- ============================
--      CUSTOMERS (Clienți)
-- ============================

-- 5. Display the total number of orders placed by each customer in 1997, including the customer name, sorted in descending order by order count.
SELECT c.CompanyName, COUNT(*) AS TotalOrders
FROM Orders o
JOIN Customers c ON o.CustomerID = c.CustomerID
WHERE YEAR(OrderDate) = 1997
GROUP BY c.CompanyName
ORDER BY COUNT(*) DESC;

-- 6. Classify customers based on their total spending in 1997 into three categories.
SELECT c.CompanyName, SUM(od.UnitPrice * od.Quantity) AS TotalSalesAmount,
    CASE
        WHEN SUM(od.UnitPrice * od.Quantity) >= 10000 THEN 'High Spender'
        WHEN SUM(od.UnitPrice * od.Quantity) >= 5000 THEN 'Medium Spender'
        ELSE 'Low Spender'
    END AS SpendingCategory
FROM Orders o
JOIN Customers c ON o.CustomerID = c.CustomerID
JOIN [Order Details] od ON o.OrderID = od.OrderID
WHERE YEAR(OrderDate) = 1997
GROUP BY c.CompanyName
ORDER BY TotalSalesAmount DESC;


-- ============================
--     EMPLOYEES (Angajați)
-- ============================

-- 7. Display the employee who processed the most orders in 1997.
SELECT TOP 1 e.LastName + ' ' + e.FirstName AS EmployeeName, COUNT(*) AS TotalOrders
FROM Employees e
JOIN Orders o ON e.EmployeeID = o.EmployeeID
WHERE YEAR(OrderDate) = 1997
GROUP BY e.LastName, e.FirstName
ORDER BY COUNT(*) DESC;

-- 8. Display each employee's full name, job title, and their adjusted salary.
SELECT LastName + ' ' + FirstName AS EmployeeName, Title,
    CASE
        WHEN Title = 'Sales Representative' THEN 50000 + (50000 * 0.10)
        WHEN Title = 'Vice President, Sales' THEN 90000 + (90000 * 0.05)
        WHEN Title = 'Sales Manager' THEN 75000 + (75000 * 0.03)
        WHEN Title = 'Inside Sales Coordinator' THEN 60000 + (60000 * 0.02)
        ELSE 55000 + (55000 * 0.02)
    END AS AdjustedSalary
FROM Employees;


-- ============================
-- PRODUCTS & SALES (Produse și Vânzări)
-- ============================

-- 9. Display the top 3 products with the highest total revenue.
SELECT TOP 3 p.ProductName, SUM(od.UnitPrice * od.Quantity) AS TotalSalesAmount
FROM [Order Details] od
JOIN Products p ON od.ProductID = p.ProductID
GROUP BY p.ProductName
ORDER BY TotalSalesAmount DESC;

-- 10. Display the average order value (AOV) for each customer in 1997.
SELECT c.CompanyName, SUM(od.UnitPrice * od.Quantity) / COUNT(*) AS AOV
FROM Orders o
JOIN Customers c ON o.CustomerID = c.CustomerID
JOIN [Order Details] od ON o.OrderID = od.OrderID
WHERE YEAR(OrderDate) = 1997
GROUP BY c.CompanyName
ORDER BY AOV DESC;


-- ============================
--   SUPPLIERS (Furnizori)
-- ============================

-- 11. Display suppliers who supply more than 3 different products.
SELECT s.CompanyName, COUNT(DISTINCT p.ProductID) AS NumberOfProducts
FROM Products p
JOIN Suppliers s ON p.SupplierID = s.SupplierID
GROUP BY s.CompanyName
HAVING COUNT(DISTINCT p.ProductID) > 3;


-- ============================
--  CTEs & Advanced Queries
-- ============================

-- 12. Retrieve the hierarchy of employees, starting from top-level employees down to lower-level employees.
WITH EmployeeHierarchy AS (
    SELECT EmployeeID, FirstName, LastName, ReportsTo, 1 AS HierarchyLevel
    FROM Employees
    WHERE ReportsTo IS NULL  
    UNION ALL
    SELECT e.EmployeeID, e.FirstName, e.LastName, e.ReportsTo, eh.HierarchyLevel + 1
    FROM Employees e
    JOIN EmployeeHierarchy eh ON e.ReportsTo = eh.EmployeeID
)
SELECT * FROM EmployeeHierarchy
ORDER BY HierarchyLevel;

-- 13. Display each employee's full name, title, total sales amount, and their rank within the company based on total sales.
WITH RankedEmployees AS (
    SELECT 
        e.LastName + ' ' + e.FirstName AS EmployeeName, 
        e.Title, 
        SUM(od.Quantity * od.UnitPrice) AS TotalSales,
        RANK() OVER (PARTITION BY e.Title ORDER BY SUM(od.Quantity * od.UnitPrice) DESC) AS EmployeeRank
    FROM Employees e
    JOIN Orders o ON e.EmployeeID = o.EmployeeID
    JOIN [Order Details] od ON o.OrderID = od.OrderID
    GROUP BY e.Title, e.LastName, e.FirstName
)
SELECT * FROM RankedEmployees
ORDER BY Title, EmployeeRank;

-- 14. Find Employees Who Processed More Than 10 Orders.
WITH EmployeesOrders AS (
    SELECT e.EmployeeID, e.LastName, e.FirstName, COUNT(*) AS TotalOrders
    FROM Employees e
    JOIN Orders o ON e.EmployeeID = o.EmployeeID
    GROUP BY e.EmployeeID, e.LastName, e.FirstName
)
SELECT * FROM EmployeesOrders
WHERE TotalOrders > 10;

-- 15. Display each order placed by a customer, 
--along with the difference in days compared to the previous order.
SELECT 
    CustomerID,
    OrderID,
    OrderDate,
    LAG(OrderDate) OVER (PARTITION BY CustomerID ORDER BY OrderDate) AS PreviousOrderDate,
    DATEDIFF(DAY, LAG(OrderDate) OVER (PARTITION BY CustomerID ORDER BY OrderDate), OrderDate) AS DaysSinceLastOrder
FROM Orders;


-- ============================
-- TEMPORARY TABLES & STORED PROCEDURES
-- ============================

-- Create a temporary table that stores customers and their total spending in 1997.
DROP TABLE IF EXISTS #TopCustomers;
CREATE TABLE #TopCustomers(
    CustomerID NVARCHAR(10), 
    CompanyName NVARCHAR(255),
    TotalSpending DECIMAL(18,2)
);

INSERT INTO #TopCustomers
SELECT c.CustomerID, c.CompanyName, SUM(od.Quantity*od.UnitPrice) TotalSpending
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN [Order Details] od ON o.OrderID = od.OrderID
WHERE YEAR(o.OrderDate) = 1997
GROUP BY c.CustomerID, c.CompanyName;

SELECT * 
FROM #TopCustomers
WHERE TotalSpending > 5000
ORDER BY TotalSpending DESC;

-- Create a Stored Procedure to Retrieve the Top N Employees by Sales.
DROP PROCEDURE IF EXISTS GetTopEmployeesBySales;
GO

CREATE PROCEDURE GetTopEmployeesBySales
    @Year INT,
    @TopN INT
AS
BEGIN
    DROP TABLE IF EXISTS #TopEmployees;

    CREATE TABLE #TopEmployees (
        EmployeeID INT, 
        EmployeeName NVARCHAR(255),
        TotalSales DECIMAL(18,2)
    );

    INSERT INTO #TopEmployees
    SELECT 
        e.EmployeeID, 
        e.LastName + ' ' + e.FirstName AS EmployeeName, 
        SUM(od.Quantity * od.UnitPrice) AS TotalSales
    FROM Employees e
    JOIN Orders o ON e.EmployeeID = o.EmployeeID
    JOIN [Order Details] od ON o.OrderID = od.OrderID
    WHERE YEAR(o.OrderDate) = @Year
    GROUP BY e.EmployeeID, e.LastName, e.FirstName;

    SELECT TOP (@TopN) *
    FROM #TopEmployees
    ORDER BY TotalSales DESC;
END;
GO

EXEC GetTopEmployeesBySales @Year = 1997, @TopN = 5;
