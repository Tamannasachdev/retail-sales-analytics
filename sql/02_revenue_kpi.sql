
--Q1-- Total revenue, total number of orders, and total unique customers
SELECT 
     SUM(linerevenue) AS Revenue,
     COUNT(Distinct Invoice) AS [Total Orders],
     COUNT(Distinct CustomerID) As [Unique Customers]
FROM vw_sales_clean;
--Result: Revenue ~£20.97M | 40,077 orders | 5,878 unique customers
-- Note: unique customer count likely undercounted, ~20-25% of rows lack CustomerID

--Q2--Month-over-month revenue trend across the full date range

SELECT 
      DATEPART(Month, InvoiceDate) as Month,
      DATEPART(Year, InvoiceDate) as Year,
      SUM(LineRevenue) AS Revenue 
FROM vw_sales_clean
GROUP BY DATEPART(Year, InvoiceDate), DATEPART(Month, InvoiceDate)
ORDER BY Year, Month;
-- Finding: Clear Nov/Dec seasonal peaks both years; Feb dips both years

---Q3--Month-over-month revenue growth percentage vs previous month

WITH CTE_MonthlyRevenue AS
(SELECT       
      DATEPART(Month, InvoiceDate) as Month,
      DATEPART(Year, InvoiceDate) as Year,
      SUM(LineRevenue) AS Revenue
FROM vw_sales_clean
GROUP BY DATEPART(Year, InvoiceDate), DATEPART(Month, InvoiceDate)
),
CTE_PreviousMonthRevenue AS
(
SELECT *, 
      LAG(Revenue , 1 ) OVER (ORDER BY Year, Month) AS PreviousMonthRevenue  
FROM CTE_MonthlyRevenue
)
SELECT *,
     (Revenue - PreviousMonthRevenue) / PreviousMonthRevenue *100 AS Growth
FROM CTE_PreviousMonthRevenue
-- Note: first month (Dec 2009) returns NULL growth, as expected (no prior month exists)

--Q4: Year-over-year revenue comparison for overlapping months (self-join approach)
-- Note: LAG(Revenue, 12) does not work here since dataset starts mid-year (Dec 2009),
-- breaking the assumption of a clean 12-row-per-year block. Self-join used instead.

WITH CTE_MonthlyRevenue AS
(SELECT       
      DATEPART(Month, InvoiceDate) as Month,
      DATEPART(Year, InvoiceDate) as Year,
      SUM(LineRevenue) AS Revenue
FROM vw_sales_clean
GROUP BY DATEPART(Year, InvoiceDate), DATEPART(Month, InvoiceDate)
)
SELECT a.Year, a.month, a.revenue AS CurrentRevenue, b.revenue AS PreviousYearRevenue
FROM CTE_MonthlyRevenue a
JOIN CTE_MonthlyRevenue b
    ON a.month = b.month AND a.Year = 1+ b.year
ORDER BY MONTH
-- Note: Dec 2009 excluded — no prior-year Dec 2008 exists for comparison
-- Finding: Mar/Apr/May 2011 declined YoY vs 2010 — worth deeper look in seasonality analysis


--Q5--Running (cumulative) total of revenue over time

WITH CTE_MonthlyRevenue AS
(
SELECT 
      DATEPART(Year, InvoiceDate) as Year,
      DATEPART(Month, InvoiceDate) as Month,
      SUM(LineRevenue) AS Revenue 
FROM vw_sales_clean
GROUP BY DATEPART(Year, InvoiceDate), DATEPART(Month, InvoiceDate)
)
SELECT *,
      SUM(Revenue) OVER (ORDER BY Year,Month) As RunningTotal
FROM CTE_MonthlyRevenue
-- Verified: final RunningTotal (~£20.97M) matches Q1 total revenue exactly

-- Q6a: Overall Average Order Value (AOV)
WITH CTE_AOV AS (
    SELECT 
        SUM(LineRevenue) AS Revenue,
        COUNT(DISTINCT Invoice) AS TotalOrders
    FROM vw_sales_clean
)
SELECT (Revenue / TotalOrders) AS AOV
FROM CTE_AOV;
-- Result: AOV = £523.31 (consistent with wholesale/B2B-leaning customer base)

--Q6b AOV trend month over month

WITH CTE_AOV AS 
(
SELECT 
      DATEPART(YEAR, InvoiceDate) AS Year,
      DATEPART(MONTH, InvoiceDate) AS Month,
      SUM(LineRevenue) AS Revenue,
      COUNT( Distinct Invoice) As TotalOrders
FROM vw_sales_clean
GROUP BY DATEPART( YEAR, InvoiceDate), DATEPART( MONTH, InvoiceDate)
)
SELECT *, 
      (Revenue/TotalOrders) AS AOV
FROM CTE_AOV
ORDER BY YEAR, MONTH  

-- Finding: Dec 2010 AOV spikes to £809 — investigated below (Q6c)


-- Q6c: Investigating Dec 2010 AOV spike — top 5 largest individual orders

SELECT TOP 10 Invoice, SUM(LineRevenue) AS OrderValue
FROM vw_sales_clean
WHERE DATEPART(YEAR, InvoiceDate) = 2010 AND DATEPART(MONTH, InvoiceDate) = 12
GROUP BY Invoice
ORDER BY OrderValue DESC;

-- Finding: top 5 orders = ~£122,536 (~9.7% of Dec 2010's total revenue from just 5 of 1,559 orders)
-- Conclusion: Dec 2010 AOV is partly inflated by a handful of large wholesale-style orders,
-- not purely broad-based seasonal spending increase

--- Q7--Order volume and revenue by day of week

SELECT 
      DATEPART( Weekday, InvoiceDate) AS Weekday,
      SUM(LineRevenue) AS Revenue,
      COUNT( Distinct Invoice) As TotalOrders
FROM vw_sales_clean
GROUP BY DATEPART( Weekday, InvoiceDate)
ORDER BY Weekday;

SELECT DATEPART(WEEKDAY, '2024-01-01') AS WeekdayNumber; 
--(2=MONDAY)

--Finding: Saturday (Weekday 7) has near-zero orders (30 orders vs 4,800-8,300 on other days)
-- Interpretation: consistent with B2B/wholesale customer base, not typical B2C weekend shopping

-- Q7b: Order volume and revenue by hour of day
SELECT 
      DATEPART( HOUR, InvoiceDate) AS Hour,
      SUM(LineRevenue) AS Revenue,
      COUNT( Distinct Invoice) As TotalOrders
FROM vw_sales_clean
GROUP BY DATEPART( Hour, InvoiceDate)
ORDER BY HOUR
-- Finding: real order activity begins ~8am, peaks 12pm-1pm, tapers after 4pm, minimal after 6pm
-- Interpretation: consistent with standard UK business hours (9-to-5), reinforcing B2B pattern
