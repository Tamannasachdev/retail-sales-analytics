
-- 01_data_cleaning.sql
-- Project: Retail Sales Performance Analytics
-- Purpose: Fix StockCode import bug, combine years, build clean view


-- Step 1: Staging table to safely import 2009-2010 data as text
-- (fixes StockCode being wrongly auto-typed as FLOAT, wiping alphanumeric codes)
CREATE TABLE Year_2009_2010_staging
(
    Invoice NVARCHAR(255),
    StockCode NVARCHAR(255),
    Description NVARCHAR(255),
    Quantity NVARCHAR(255),
    InvoiceDate NVARCHAR(255),
    Price NVARCHAR(255),
    Customer_ID NVARCHAR(255),
    Country NVARCHAR(255)
);
-- (data imported via Import Flat File wizard)

-- Step 2: Clean table with correct types, converted via TRY_CAST
CREATE TABLE Year_2009_2010_clean
(
    Invoice NVARCHAR(50),
    StockCode NVARCHAR(50),
    Description NVARCHAR(255),
    Quantity FLOAT,
    InvoiceDate DATETIME,
    Price FLOAT,
    [Customer ID] FLOAT,
    Country NVARCHAR(255)
);

INSERT INTO Year_2009_2010_clean
SELECT 
    Invoice,
    StockCode,
    Description,
    TRY_CAST(Quantity AS FLOAT),
    TRY_CAST(InvoiceDate AS DATETIME),
    TRY_CAST(Price AS FLOAT),
    TRY_CAST(Customer_ID AS FLOAT),
    Country
FROM Year_2009_2010_staging;

-- Step 3: Combine both years into one unified table
SELECT 
    CAST(Invoice AS NVARCHAR(50)) AS Invoice,
    CAST(StockCode AS NVARCHAR(50)) AS StockCode,
    CAST(Description AS NVARCHAR(255)) AS Description,
    CAST(Quantity AS FLOAT) AS Quantity,
    CAST(InvoiceDate AS DATETIME) AS InvoiceDate,
    CAST(Price AS FLOAT) AS Price,
    CAST([Customer ID] AS FLOAT) AS CustomerID,
    CAST(Country AS NVARCHAR(255)) AS Country
INTO retail_transactions
FROM Year_2009_2010_clean

UNION ALL

SELECT 
    CAST(Invoice AS NVARCHAR(50)),
    CAST(StockCode AS NVARCHAR(50)),
    CAST(Description AS NVARCHAR(255)),
    CAST(Quantity AS FLOAT),
    CAST(InvoiceDate AS DATETIME),
    CAST(Price AS FLOAT),
    CAST([Customer ID] AS FLOAT),
    CAST(Country AS NVARCHAR(255))
FROM [Year 2010-2011$];

-- Step 4: Clean sales view — excludes returns/write-offs, adds LineRevenue
CREATE VIEW vw_sales_clean AS
SELECT Invoice, StockCode, Description, Quantity, InvoiceDate, Price, CustomerID, Country,
       (Quantity * Price) AS LineRevenue
FROM retail_transactions
WHERE Quantity > 0 AND Price > 0;

-----FIXING OF NULL INVOICEDATE FROM 2009-2010 staging table and combining the data again----
DROP TABLE Year_2009_2010_clean;

CREATE TABLE Year_2009_2010_clean (
    Invoice NVARCHAR(50),
    StockCode NVARCHAR(50),
    Description NVARCHAR(255),
    Quantity FLOAT,
    InvoiceDate DATETIME,
    Price FLOAT,
    [Customer ID] FLOAT,
    Country NVARCHAR(255)
);

INSERT INTO Year_2009_2010_clean
SELECT 
    Invoice,
    StockCode,
    Description,
    TRY_CAST(Quantity AS FLOAT),
    TRY_CONVERT(DATETIME, InvoiceDate, 105),
    TRY_CAST(Price AS FLOAT),
    TRY_CAST(Customer_ID AS FLOAT),
    Country
FROM Year_2009_2010_staging;

SELECT COUNT(*) FROM Year_2009_2010_clean;
SELECT COUNT(*) FROM Year_2009_2010_clean WHERE InvoiceDate IS NULL;

DROP VIEW vw_sales_clean;
DROP TABLE retail_transactions;


SELECT 
    CAST(Invoice AS NVARCHAR(50)) AS Invoice,
    CAST(StockCode AS NVARCHAR(50)) AS StockCode,
    CAST(Description AS NVARCHAR(255)) AS Description,
    CAST(Quantity AS FLOAT) AS Quantity,
    CAST(InvoiceDate AS DATETIME) AS InvoiceDate,
    CAST(Price AS FLOAT) AS Price,
    CAST([Customer ID] AS FLOAT) AS CustomerID,
    CAST(Country AS NVARCHAR(255)) AS Country
INTO retail_transactions
FROM Year_2009_2010_clean

UNION ALL

SELECT 
    CAST(Invoice AS NVARCHAR(50)),
    CAST(StockCode AS NVARCHAR(50)),
    CAST(Description AS NVARCHAR(255)),
    CAST(Quantity AS FLOAT),
    CAST(InvoiceDate AS DATETIME),
    CAST(Price AS FLOAT),
    CAST([Customer ID] AS FLOAT),
    CAST(Country AS NVARCHAR(255))
FROM dbo.['Year 2010-2011$'];


CREATE VIEW vw_sales_clean AS 
SELECT Invoice, StockCode, Description, Quantity, InvoiceDate, Price, CustomerID, Country,
       (Quantity * Price) AS LineRevenue
FROM retail_transactions
WHERE Quantity > 0 AND Price > 0;


SELECT COUNT(*) FROM retail_transactions;
SELECT COUNT(*) FROM vw_sales_clean WHERE InvoiceDate is NULL;