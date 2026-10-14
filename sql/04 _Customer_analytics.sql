---Customer Analytics (RFM)---


--Q13-15: RFM base values, NTILE scoring, and segment labels
-- Reference date for Recency = '2011-12-31' (last date in dataset), not GETDATE()
-- CustomerID IS NOT NULL required — see decision log Issue #2 (missing CustomerID)
-- Champions requires minimum threshold on all 3 dimensions individually, not just a 
-- high combined score — a sum-only rule let strong Frequency/Monetary mask poor Recency

WITH CTE_RFM AS
(
SELECT 
      CustomerID,
      DATEDIFF(Day, Max(InvoiceDate),'2011-12-31') AS Recency,
      COUNT(DISTINCT Invoice) AS Frequency,
      SUM(LineRevenue) AS Monetary
FROM vw_sales_clean 
WHERE CustomerID IS NOT NULL 
GROUP BY CustomerID
),
CTE_RFM_Score AS 
(
SELECT *,
      NTILE(5) OVER ( ORDER BY Recency DESC) As RecencyScore,
      NTILE(5) OVER ( ORDER BY Frequency ASC) As FrequencyScore,
      NTILE(5) OVER ( ORDER BY Monetary ASC) As MonetaryScore
FROM CTE_RFM
),
CTE_Final AS 
(
SELECT 
    CustomerID, Recency,Frequency,Monetary,
    CONCAT(RecencyScore, FrequencyScore, MonetaryScore) AS RFM,
    CASE 
        WHEN RecencyScore >= 4 AND FrequencyScore >= 4 AND MonetaryScore >= 4 THEN 'Champions'
        WHEN (RecencyScore + FrequencyScore + MonetaryScore) >= 9 AND RecencyScore >= 3 THEN 'Loyal Customers'
        WHEN RecencyScore <= 2 AND (FrequencyScore + MonetaryScore) >= 6 THEN 'At Risk'
        WHEN RecencyScore >= 4 AND FrequencyScore <= 2 THEN 'New Customers'
        WHEN (RecencyScore + FrequencyScore + MonetaryScore) <= 6 THEN 'Lost'
        ELSE 'Other'
    END AS RFM_Segment
FROM CTE_RFM_Score
)
SELECT * FROM CTE_Final;


--16 : Customer count and % of total revenue per RFM segment
-- Finding: Champions = ~21.5% of customers but 67.8% of revenue — sharp concentration,
-- mirrors Q10's product-side Pareto finding (top 20% products = 78% of revenue).
-- At Risk segment alone represents £1.7M (9.8%) in revenue — concrete retention target.

WITH CTE_RFM AS
(
SELECT 
      CustomerID,
      DATEDIFF(Day, Max(InvoiceDate),'2011-12-31') AS Recency,
      COUNT(DISTINCT Invoice) AS Frequency,
      SUM(LineRevenue) AS Monetary
FROM vw_sales_clean 
WHERE CustomerID IS NOT NULL 
GROUP BY CustomerID
),
CTE_RFM_Score AS 
(
SELECT *,
      NTILE(5) OVER ( ORDER BY Recency DESC) As RecencyScore,
      NTILE(5) OVER ( ORDER BY Frequency ASC) As FrequencyScore,
      NTILE(5) OVER ( ORDER BY Monetary ASC) As MonetaryScore
FROM CTE_RFM
),
CTE_Final AS
(
SELECT 
     CustomerID,
     Recency,
     Frequency,
     Monetary,
     CONCAT(RecencyScore, FrequencyScore, MonetaryScore) AS RFM,
CASE 
    WHEN RecencyScore >= 4 AND FrequencyScore >= 4 AND MonetaryScore >= 4 THEN 'Champions'
    WHEN (RecencyScore + FrequencyScore + MonetaryScore) >= 9 AND RecencyScore >= 3 THEN 'Loyal Customers'
    WHEN RecencyScore <= 2 AND (FrequencyScore + MonetaryScore) >= 6 THEN 'At Risk'
    WHEN RecencyScore >= 4 AND FrequencyScore <= 2 THEN 'New Customers'
    WHEN (RecencyScore + FrequencyScore + MonetaryScore) <= 6 THEN 'Lost'
    ELSE 'Other'
END AS RFM_Segment
FROM CTE_RFM_Score
)
SELECT   
    RFM_Segment,
    COUNT(DISTINCT CustomerID) AS NumberOfCustomers,
    SUM(Monetary) AS SegmentRevenue,
    SUM(Monetary)/(SELECT SUM(Monetary) FROM CTE_Final) * 100 AS PercentOfRevenue
FROM CTE_Final
GROUP BY RFM_Segment;


--17 Repeat purchase rate (% of customers with more than 1 order)

WITH CTE_RepeatCustomers AS 
(
SELECT 
     CustomerId,
     COUNT(DISTINCT Invoice) AS Frequency
FROM vw_sales_clean
GROUP BY CustomerID
HAVING COUNT(Distinct Invoice) > 1
)
SELECT 
    COUNT(CustomerId) * 100.0 
    / (SELECT COUNT(DISTINCT CustomerId) FROM vw_sales_clean) AS RepeatRate
FROM CTE_RepeatCustomers;

--18--verage days between a customer's first and second purchase
-- Result: ~97 days (~3 months) — plausible for a wholesale/gift retailer's ordering cadence
WITH CTE_UniquePurchases AS
(
SELECT  
      CustomerID,
      Invoice,
      InvoiceDate
FROM vw_sales_clean
WHERE CustomerID is not null
GROUP BY  CustomerId, Invoice, InvoiceDate
),
CTE_NumberedPurchases AS
(
SELECT
      CustomerID,
      Invoice,
      InvoiceDate,
      ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY InvoiceDate ASC  ) AS PurchaseNumber
      FROM CTE_UniquePurchases
),
CTE_FirstSecond AS
(
SELECT Customerid,
       MAX(Case WHEN PurchaseNumber = 1 THEN InvoiceDate  END) AS FirstPurchase,
       MAX(Case WHEN PurchaseNumber = 2 THEN InvoiceDate  END) AS SecondPurchase
FROM CTE_NumberedPurchases
WHERE PurchaseNumber <=2
GROUP BY CustomerID
),
CTE_Days AS
(
SELECT 
      CustomerID,
      DATEDIFF(DAY, FirstPurchase, SecondPurchase) AS Days
FROM CTE_FirstSecond
)
SELECT 
     AVG(Days) AS AvgDays
FROM CTE_Days;