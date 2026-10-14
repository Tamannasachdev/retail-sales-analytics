
--20-- Revenue and order count by country; concentration in top 3 countries
-- Uses vw_sales_clean (genuine sales only). CumulativePercent shows running concentration
-- via SUM() OVER(), same technique as Q5's running total.
-- Finding: Top 3 countries (UK, EIRE, Netherlands) = ~90.9% of total revenue (CR3 ratio),
-- driven overwhelmingly by UK alone (~85%). Consistent with this being a UK-based retailer.
SELECT TOP 3
      Country, 
      COUNT(DISTINCT Invoice) AS Orders,
      SUM(Linerevenue) AS Revenue,
      SUM(Linerevenue)/ (SELECT SUM(Linerevenue) FROM vw_sales_clean) * 100 AS PercentageofRevenue,
      SUM(SUM(LineRevenue)) OVER (ORDER BY SUM(LineRevenue) DESC) 
        / SUM(SUM(LineRevenue)) OVER () * 100 AS CumulativePercent
FROM vw_sales_clean
GROUP BY Country
ORDER BY Revenue DESC;

--21--Cancellation/return rate (by row count and revenue impact), overall and by country
-- Uses retail_transactions (need negative-Quantity rows, excluded by vw_sales_clean).
-- Genuine return filter: Quantity < 0 AND Price > 0 — excludes write-offs/giveaways with
-- Price = 0 (see decision log: StockCode 22351 "Given away", same reasoning as Q11).
-- Threshold HAVING COUNT(*) > 50 excludes countries with too few transactions for a
-- statistically meaningful percentage (e.g., Nigeria: 32 rows, 1 large genuine return
-- caused a 104% revenue-impact figure — real event, but not comparable at that sample size).
-- Overall return rate (unfiltered by country): ~1.88% by row count.

SELECT 
     Country,
     COUNT(CASE WHEN Quantity < 0 AND Price > 0 THEN 1 END) AS ReturnRowCount,
     COUNT(*) AS TotalRowCount,
     COUNT(CASE WHEN Quantity < 0 AND Price > 0 THEN 1 END) * 100.00 /COUNT(*) AS ReturnRatePercent,
     SUM(CASE WHEN Quantity < 0 AND Price > 0 THEN ABS(Quantity*Price) END) AS ValueFromReturns,
     SUM(CASE WHEN Quantity > 0 AND Price > 0 THEN Quantity*Price END) AS GenuineSalesRevenue,
     SUM(CASE WHEN Quantity < 0 AND Price > 0 THEN ABS(Quantity*Price) END) * 100.00/
     SUM(CASE WHEN Quantity > 0 AND Price > 0 THEN Quantity*Price END) AS RevenueImpactPercent
FROM dbo.retail_transactions
GROUP BY Country
HAVING COUNT(*) > 50
ORDER BY RevenueImpactPercent DESC;

-- Finding: Singapore (48.0%), Hong Kong (41.6%), Norway (37.0%) show highest return 
-- revenue-impact among countries with meaningful volume — candidates for shipping/
-- quality/customs review.

---------------------------------------------------------------------------------------

-- Q22: Seasonal pattern in order volume/revenue, peak month vs. yearly average
-- Finding: clear ramp-up Sep-Nov, peaking in November (avg ~£1.48M/month), followed by
-- a sharp December decline — consistent with a B2B/wholesale customer base ordering 
-- holiday stock weeks in advance, rather than a B2C pattern where December itself peaks.
 
WITH CTE_MonthlyRevenue AS 
(
SELECT 
      DATEPART(YEAR,InvoiceDate) AS Year,
      DATEPART(MONTH,InvoiceDate) AS Month,
      SUM(LineRevenue) AS Revenue
FROM vw_sales_clean
GROUP BY DATEPART(YEAR,InvoiceDate), DATEPART(MONTH,InvoiceDate)
),
CTE_MonthlyAvg AS
(
SELECT 
      Month,
      AVG(Revenue) AS AvgRevenueForMonth
FROM CTE_MonthlyRevenue
GROUP BY Month
)
SELECT *, 
        (SELECT AVG(Revenue) FROM CTE_MonthlyRevenue) AS OverallAvg,
        (AvgRevenueForMonth - (SELECT AVG(Revenue) FROM CTE_MonthlyRevenue)) 
        / (SELECT AVG(Revenue) FROM CTE_MonthlyRevenue) * 100 AS PercentAbovePeriodAvg
FROM CTE_MonthlyAvg
ORDER BY MONTH
        
        