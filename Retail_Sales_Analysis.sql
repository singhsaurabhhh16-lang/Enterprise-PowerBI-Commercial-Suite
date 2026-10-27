
---- Business Overview ----

-- Q1: What is the total revenue generated?
SELECT ROUND(SUM(SalesAmount),2) AS TotalRevenue FROM Orders;


-- Q2: What is the total number of orders, customers, products, employees and returns?
SELECT COUNT(OrderID) AS TotalOrders FROM Orders; 
SELECT COUNT(CustomerID)AS TotalCustomers FROM Customers;
SELECT COUNT(ProductID)AS TotalProducts FROM Products;
SELECT COUNT(EmployeeID)AS TotalEmployees FROM Employees;
SELECT COUNT(ReturnID)AS TotalReturns FROM Returns;


-- Q3: What is the average order value?
SELECT ROUND(AVG(SalesAmount),2) AS Average_Order_Value FROM Orders;


-- Q4: What is the overall order return rate?
SELECT ROUND(
    COUNT(DISTINCT R.OrderID) * 100.0
    / (SELECT COUNT(*) FROM Orders),2)
 AS Overall_Return_Rate FROM Returns R;

-- Q5: What is the total profit and profit margin percentage across product categories?
SELECT 
    P.Category,
    ROUND(SUM(O.SalesAmount), 2) AS Total_Revenue,
    ROUND(SUM(O.ProfitAmount), 2) AS Total_Profit,
    ROUND(SUM(O.ProfitAmount) * 100.0 / SUM(O.SalesAmount), 2) AS Profit_Margin_Pct
FROM Orders O
INNER JOIN Products P ON O.ProductID = P.ProductID
GROUP BY P.Category ORDER BY Total_Profit DESC;

---- Customer Analysis ----

-- Q6: Who are the top 10 customers by total revenue?
SELECT TOP 10 C.CustomerName, O.CustomerID, ROUND(SUM(O.SalesAmount),2) AS Total_Revenue
FROM Customers C INNER JOIN Orders O ON C.CustomerID = O.CustomerID
GROUP BY O.CustomerID, C.CustomerName ORDER BY Total_Revenue DESC;


-- Q7: Identify customer who have placed the highest number of orders.
SELECT TOP 1 WITH TIES CustomerID, COUNT(OrderID) AS Total_Orders FROM Orders 
GROUP BY CustomerID ORDER BY Total_Orders DESC;


-- Q8: Which customers have spending above the average customer spending? 
SELECT C.CustomerName, O.CustomerID, ROUND(SUM(O.SalesAmount),2) AS Total_Spending
FROM Customers C INNER JOIN Orders O ON C.CustomerID = O.CustomerID
GROUP BY O.CustomerID, C.CustomerName  HAVING SUM(O.SalesAmount) > 
( SELECT AVG(Total_Spending)FROM
( SELECT O.CustomerID, SUM(O.SalesAmount) AS Total_Spending FROM Orders O
GROUP BY O.CustomerID )AS Avg_Spending ) ORDER BY Total_Spending DESC;


-- Q9: Which customer segments generate the highest revenue?
SELECT C.Segment, ROUND(SUM(O.SalesAmount),2) AS Total_Revenue
FROM Customers C INNER JOIN Orders O ON C.CustomerID = O.CustomerID
GROUP BY C.Segment ORDER BY Total_Revenue DESC;


-- Q10: Which customers have high order volume but also high return activity?
WITH CustomerActivity AS
( SELECT C.CustomerID, C.CustomerName,
  COUNT(DISTINCT O.OrderID) AS Total_Orders, COUNT(DISTINCT R.OrderID) AS Return_Count
  FROM Customers C LEFT JOIN Orders O ON C.CustomerID = O.CustomerID
  LEFT JOIN Returns R ON R.OrderID = O.OrderID GROUP BY C.CustomerID, C.CustomerName),
AverageActivity AS
( SELECT
ROUND(AVG(Total_Orders),2) AS Avg_Orders, ROUND(AVG(Return_Count),2) AS Avg_Returns
FROM CustomerActivity )
  SELECT CA.CustomerID, CA.CustomerName,CA.Total_Orders, CA.Return_Count
  FROM CustomerActivity CA CROSS JOIN AverageActivity AA
  WHERE CA.Total_Orders > AA.Avg_Orders AND CA.Return_Count > AA.Avg_Returns
  ORDER BY CA.Total_Orders DESC, CA.Return_Count DESC;


-- Q11: Which customers have placed orders but never had a return?  
SELECT C.CustomerID, C.CustomerName FROM Customers C WHERE EXISTS 
(SELECT 1 FROM Orders O WHERE O.CustomerID = C.CustomerID) AND NOT EXISTS 
( SELECT 1 FROM Orders O INNER JOIN Returns R  ON O.OrderID = R.OrderID
WHERE O.CustomerID = C.CustomerID);
    


---- Product Analysis ----

-- Q12: What are the top 10 products by revenue?  
SELECT TOP 10 P.ProductID, P.ProductName, ROUND(SUM(O.SalesAmount),2) AS Total_Revenue
FROM Products P INNER JOIN Orders O ON P.ProductID = O.ProductID
GROUP BY P.ProductID, P.ProductName ORDER BY Total_Revenue DESC;


-- Q13: What are the top 10 products by quantity sold?
SELECT TOP 10 P.ProductID, P.ProductName, SUM(O.Quantity) AS Total_Quantity_Sold
FROM Products P INNER JOIN Orders O ON P.ProductID = O.ProductID
GROUP BY P.ProductID, P.ProductName ORDER BY Total_Quantity_Sold DESC;


-- Q14: Which product categories generate the highest revenue? 
SELECT P.Category, ROUND(SUM(O.SalesAmount),2) AS Total_Revenue
FROM Products P INNER JOIN Orders O ON P.ProductID = O.ProductID
GROUP BY P.Category ORDER BY Total_Revenue DESC;


-- Q15: Which products have the highest return rate? 
SELECT P.ProductID, P.ProductName, COUNT(DISTINCT O.OrderID) AS Total_Orders,
COUNT(DISTINCT R.OrderID) AS Total_Returns, 
ROUND(COUNT(DISTINCT R.OrderID)*100.0 / COUNT(DISTINCT O.OrderID),2) AS Product_Return_Rate
FROM Products P INNER JOIN Orders O ON P.ProductID = O.ProductID
LEFT JOIN Returns R ON O.OrderID = R.OrderID GROUP BY P.ProductID, P.ProductName
ORDER BY Product_Return_Rate DESC;
  

-- Q16:Which product generates the highest revenue within each category?
WITH Product_Revenue AS (
SELECT  P.ProductID,P.ProductName, P.Category, SUM(O.SalesAmount) AS Total_Revenue,
RANK()OVER( PARTITION BY P.Category ORDER BY SUM(O.SalesAmount)DESC ) AS Rnk
FROM Products P INNER JOIN Orders O 
ON P.ProductID = O.ProductID  GROUP BY P.ProductID, P.ProductName, P.Category)
SELECT * FROM Product_Revenue WHERE Rnk =1;


-- Q17 : What percentage of total revenue does each product category contribute?
SELECT P.Category, ROUND( SUM(O.SalesAmount) * 100.0 /
(SELECT SUM(SalesAmount) FROM Orders),2) AS Revenue_Percentage,
ROUND( SUM(O.SalesAmount),2) AS Total_Revenue
FROM Orders O INNER JOIN Products P ON O.ProductID = P.ProductID
GROUP BY P.Category ORDER BY Revenue_Percentage DESC;


---- Sales & Time Analysis ----

-- Q18 : Which month generated the highest revenue?
SELECT TOP 1 MONTH(OrderDate) AS MONTH, YEAR(OrderDate) AS YEAR,
ROUND(SUM(SalesAmount),2)AS Total_Revenue
FROM Orders GROUP BY MONTH(OrderDate), YEAR(OrderDate)
ORDER BY Total_Revenue DESC;


-- Q19 : Which month had the highest number of orders?
SELECT TOP 1 MONTH(OrderDate) AS MONTH, YEAR(OrderDate) AS YEAR, COUNT(OrderID)AS Order_Count
FROM Orders GROUP BY MONTH(OrderDate), YEAR(OrderDate) ORDER BY Order_Count DESC;


-- Q20 : What is the monthly revenue trend?
SELECT MONTH(OrderDate) AS MONTH, YEAR(OrderDate) AS YEAR,
ROUND(SUM(SalesAmount),2)AS Total_Revenue
FROM Orders GROUP BY MONTH(OrderDate), YEAR(OrderDate)
ORDER BY YEAR ASC, MONTH ASC;


-- Q21 : What is the month-over-month revenue growth? 
WITH Monthly_Revenue AS(
SELECT MONTH(OrderDate) AS MONTH, YEAR(OrderDate) AS YEAR,
        ROUND(SUM(SalesAmount), 2) AS Total_Revenue
FROM Orders GROUP BY MONTH(OrderDate), YEAR(OrderDate)),
Revenue_With_Previous AS(
SELECT MONTH, YEAR, Total_Revenue, LAG(Total_Revenue) OVER(ORDER BY YEAR ASC, MONTH ASC)
AS Previous_Month_Revenue FROM Monthly_Revenue)
SELECT
MONTH, YEAR, Total_Revenue, Previous_Month_Revenue,
 ROUND(
        (Total_Revenue - Previous_Month_Revenue) * 100.0
        / Previous_Month_Revenue,2
    ) AS MoM_Growth_Percentage
FROM Revenue_With_Previous ORDER BY YEAR ASC, MONTH ASC;

-- Q22: What is the Year-over-Year (YoY) revenue growth percentage?
WITH Yearly_Revenue AS (
    SELECT YEAR(OrderDate) AS [Year],
        ROUND(SUM(SalesAmount), 2) AS Total_Revenue
    FROM Orders
    GROUP BY YEAR(OrderDate)
),
Yearly_With_Prev AS (
    SELECT [Year],Total_Revenue,
        LAG(Total_Revenue) OVER (ORDER BY [Year] ASC) AS Prev_Year_Revenue
    FROM Yearly_Revenue
)
SELECT [Year],Total_Revenue, Prev_Year_Revenue,
    ROUND((Total_Revenue - Prev_Year_Revenue) * 100.0 / Prev_Year_Revenue, 2) AS YoY_Growth_Percentage
FROM Yearly_With_Prev ORDER BY [Year] ASC;

-- Q23 : What is the running total of revenue over time? 
WITH MonthlyRevenue AS (
    SELECT YEAR(OrderDate) AS Year, MONTH(OrderDate) AS Month,
        ROUND(SUM(SalesAmount), 2) AS Total_Revenue
    FROM Orders GROUP BY YEAR(OrderDate), MONTH(OrderDate)
)
SELECT Year, Month, Total_Revenue,
    ROUND(SUM(Total_Revenue) OVER (ORDER BY Year,Month), 2) AS Cumulative_Revenue
FROM MonthlyRevenue ORDER BY Year, Month;



-- Q24: Which quarter generated the highest revenue?
SELECT TOP 1 DATEPART(QUARTER, OrderDate) AS Quarter, YEAR(OrderDate) AS YEAR,
ROUND(SUM(SalesAmount), 2) AS Total_Revenue FROM Orders 
GROUP BY YEAR(OrderDate),DATEPART(QUARTER, OrderDate) ORDER BY Total_Revenue DESC;


---- Returns Analysis ----

-- Q25: What are the most common return reasons?
SELECT ReturnReason, COUNT(*)AS Return_Count FROM Returns 
GROUP BY ReturnReason ORDER BY Return_Count DESC;


-- Q26: Which products have the highest number of returns? 
SELECT P.ProductID, P.ProductName, COUNT(*)AS Return_Count FROM Returns R INNER JOIN
Products P ON R.ProductID =P.ProductID
GROUP BY P.ProductID, P.ProductName ORDER BY Return_Count DESC;
  

-- Q27: Which categories have the highest return rate?
 SELECT P.Category, ROUND((COUNT(DISTINCT R.OrderID)*100.0 / COUNT(DISTINCT O.OrderID)),2)  
 AS ReturnRate FROM Products P
 INNER JOIN Orders O ON P.ProductID = O.ProductID
 LEFT JOIN Returns R ON O.OrderID = R.OrderID
 GROUP BY P.Category ORDER BY ReturnRate DESC;
 

-- Q28: Which month have the highest number of returns?
SELECT TOP 1 MONTH(ReturnDate) AS Month, YEAR(ReturnDate) AS Year,
COUNT(*)AS Return_Count FROM Returns 
GROUP BY YEAR(ReturnDate), MONTH(ReturnDate) ORDER BY Return_Count DESC;


-- Q29: How much revenue is associated with returned orders?
SELECT ROUND(SUM(SalesAmount), 2) AS Returned_Revenue 
FROM Orders 
WHERE OrderID IN (SELECT OrderID FROM Returns);



---- Employee / Operations ----

-- Q30: Which employees generate the highest revenue?
SELECT E.EmployeeID, E.EmployeeName, SUM(O.SalesAmount) AS Total_Revenue FROM Employees E
INNER JOIN  Orders O ON E. EmployeeID = O.EmployeeID
GROUP BY E.EmployeeID, E.EmployeeName ORDER BY Total_Revenue DESC;


-- Q31: Which employees handle the highest number of orders?
SELECT E.EmployeeID, COUNT(O.OrderID) AS Order_Count FROM Employees E
INNER JOIN  Orders O ON E. EmployeeID = O.EmployeeID
GROUP BY E.EmployeeID ORDER BY Order_Count DESC;


-- Q32: Which employees have high order volume but comparatively low revenue?
WITH EmployeeStats AS(
SELECT E.EmployeeID, E.EmployeeName, COUNT(O.OrderID) AS Order_Volume,
ROUND(SUM(O.SalesAmount),2) AS Total_Revenue FROM Employees E
INNER JOIN  Orders O ON E. EmployeeID = O.EmployeeID
GROUP BY E.EmployeeID, E.EmployeeName)
SELECT EmployeeID, EmployeeName, Order_Volume, Total_Revenue FROM EmployeeStats
WHERE Order_Volume > (SELECT AVG(Order_Volume) FROM EmployeeStats)
AND Total_Revenue < (SELECT AVG(Total_Revenue) FROM EmployeeStats)
ORDER BY Order_Volume DESC;

