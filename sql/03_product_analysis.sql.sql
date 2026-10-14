
--Product Performance


--Q8--Top 10 products by revenue, and % of total company revenue they represent

SELECT TOP 10
     StockCode ,
     Description,
     SUM(linerevenue) AS Revenue,
     SUM(linerevenue)/ (SELECT SUM(linerevenue) FROM vw_sales_clean) * 100 AS [Revenue Percentage]
FROM vw_sales_clean
WHERE StockCode NOT IN ('POST', 'DOT', 'M', 'ADJUST', 'ADJUST2', 'C2', 'BANK CHARGES', 'D', 'AMAZONFEE', 'TEST001', 'S', 'B', 'TEST002')
GROUP BY StockCode , Description
ORDER BY Revenue DESC;
-- Finding: Top product (22423, Regency Cakestand 3 Tier) = 1.64% of product revenue.
-- No single dominant product; revenue spread fairly evenly across top performers.


--Q9--Bottom 10 products by revenue (minimum 10 distinct orders, to exclude thin-sample noise)
-- Threshold justified by inspecting order-count distribution: ~900 products have <10 orders total

SELECT TOP 10
       StockCode,
       Description,
       COUNT(Distinct Invoice) As [Number of Orders],
       SUM(LineRevenue) AS Revenue
 FROM vw_sales_clean
 WHERE StockCode NOT IN ('POST', 'DOT', 'M', 'ADJUST', 'ADJUST2', 'C2', 'BANK CHARGES', 'D', 'AMAZONFEE', 'TEST001', 'S', 'B', 'TEST002', 'PADS')
 GROUP BY StockCode, Description 
 HAVING COUNT(Distinct Invoice) >= 10
 ORDER BY Revenue ASC

 --Q10--What % of total revenue comes from the top 20% of products? (Pareto/80-20 check)
 WITH CTE_RevenueRange AS
 (
 SELECT 
       Stockcode,
       SUM(linerevenue) AS Revenue ,
       RANK() OVER (ORDER BY SUM(linerevenue) DESC) AS RevenueRank,
       NTILE(5) OVER (ORDER BY SUM(linerevenue) DESC) AS RevenueRange
  FROM vw_sales_clean
  WHERE StockCode NOT IN ('POST', 'DOT', 'M', 'ADJUST', 'ADJUST2', 'C2', 'BANK CHARGES', 'D', 'AMAZONFEE', 'TEST001', 'S', 'B', 'TEST002', 'PADS') 
  GROUP BY StockCode
  )
 SELECT 
    (SELECT SUM(Revenue) FROM CTE_RevenueRange WHERE RevenueRange = 1) AS Top20PercentRevenue,
    (SELECT SUM(Revenue) FROM CTE_RevenueRange) AS TotalProductRevenue,
    (SELECT SUM(Revenue) FROM CTE_RevenueRange WHERE RevenueRange = 1) 
        / (SELECT SUM(Revenue) FROM CTE_RevenueRange) * 100 AS PercentOfRevenue
-- Finding: Top 20% of products generate ~78% of product revenue


 ---Q11-- Products with highest return quantity, and return quantity as % of quantity sold
WITH CTE_ReturnPercentage AS 
(
SELECT 
     StockCode,
     SUM(CASE WHEN Quantity > 0 THEN Quantity ELSE 0 END) AS TotalSold,
     SUM(CASE WHEN Quantity < 0 AND Price > 0 THEN ABS(Quantity)ELSE 0 END) AS TotalReturned
FROM retail_transactions
WHERE StockCode NOT IN ('POST', 'DOT', 'M', 'ADJUST', 'ADJUST2', 'C2', 'BANK CHARGES', 'D', 'AMAZONFEE', 'TEST001', 'S', 'B', 'TEST002', 'PADS') 
      AND Invoice IS NOT NULL 
GROUP BY StockCode
HAVING SUM(CASE WHEN Quantity > 0 THEN Quantity ELSE 0 END) > 50
)
SELECT TOP 10 *,
       ( CAST(TotalReturned AS DECIMAL(10,2))/ NULLIF(TotalSold,0) * 100) AS ReturnPercentage
FROM CTE_ReturnPercentage
WHERE  ( CAST(TotalReturned AS DECIMAL(10,2))/ NULLIF(TotalSold,0) * 100) < 100
ORDER BY ReturnPercentage DESC;

-- Note: results capped at ReturnPercentage <= 100 to exclude cases where a single 
-- large cancellation event exceeds a product's typical sales volume (e.g., StockCode 
-- 20879: one -96 unit cancellation vs 75 total units sold = 128%, mathematically 
-- valid but not representative of a chronic return pattern). 
  
