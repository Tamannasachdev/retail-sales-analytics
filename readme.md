# Retail Sales & Customer Analysis

 Analyzed over 1 million retail transactions to understand where revenue was coming from, which products and markets were driving sales, and which customers were most valuable. I used SQL Server to clean and analyze the data, applied RFM segmentation to understand customer value, and built an interactive Excel dashboard to turn the findings into clear business insights.

 ## Business Problem

 ### Questions this project answers-

 - How much revenue does the business generate, and how is it trending month over month and year over year?
- Which products and countries drive the most revenue?
- Who are the best customers, and how can customers be segmented by value (RFM)?
- How much revenue cannot be tied to an identifiable customer, and what does that mean for analysis?

 ## Dataset

 - Source: Online Retail II (kaggle)
- Period: 1 Dec 2009 to 9 Dec 2011
- Size: \~1.07 million rows after removing duplicates

 ## Tools Used

 - SQL Server (SSMS) - Data cleaning, SQL analysis and creating views
- Excel - PivotTables, PivotCharts, slicers and interactive dashboard
- GitHub - Project documentation and version control

 ## Approach

 ### Data Cleaning - SQL

 I first cleaned the raw transaction data in SQL Server and documented the issues I found along the way in my decisionLog.md file

 Some of the main problems were:

Product Code Issue: StockCode was imported as a number, causing codes like 85123A to become NULL. I re-imported the data and stored product codes as text.

Date Format Issue: Many InvoiceDate values became NULL due to the date format. I corrected the conversion by specifying the correct format.

Returns and Adjustments: Negative quantities included returns and other stock adjustments. I excluded them from revenue calculations and kept them separate for analysis.

Missing CustomerID: I kept these records for overall sales analysis but excluded them from customer-level analysis such as RFM.

 After cleaning the data, I created SQL views for the cleaned sales data, customer RFM analysis and product-level summaries.

 ## SQL Analysis

 Once the data was cleaned, I used SQL to analyze:

 - Revenue and monthly/yearly trends
- Product performance
- Country-level revenue
- Customer purchasing behaviour
- RFM customer segments

 I used £20.48M as the total revenue figure to reconcile and cross-check my results throughout the analysis.

 ## Excel Dashboard

 I connected Excel directly to the SQL Server data so the analysis can be refreshed when the underlying data changes. created PivotTables, PivotCharts and slicers to build a dashboard showing the main sales and customer KPIs.

 ## Key Findings

 - Total revenue: £20.48M over the period.
- 2011 vs 2010: revenue is roughly flat (about -0.14% YoY).
- The 2010 vs 2009 comparison is not meaningful, because 2009 contains only one month of data.
- Unidentified customers: about 15% of revenue (£3.10M) comes from transactions with no CustomerID. These are labelled "Unknown" in the RFM analysis rather than excluded, so totals still reconcile. Customer segment results therefore describe roughly 85% of revenue.
- Top Countries- United Kingdom , EIRE , Netherlands
- Customer Segmentation: Champions represent 21.5% of customers but generate 67.8% of revenue, while the At Risk segment contributes £1.7M (9.8%), highlighting an important customer retention opportunity.

## Key Business Insights
Since the Champions segment generates the highest revenue, focusing on retaining these customers could help protect a major share of revenue.

Regular performance monitoring can help identify unusual sales movements and examine changes in revenue over time.

A targeted win-back campaign could prioritize at-risk customers based on purchase recency and historical customer revenue.


## Lessons Learned

Importing data can sometimes change data types and damage codes, so checking data types is important.

Incorrect date formats can create NULL values, making it important to verify dates after loading.

Checking totals at each stage helps identify duplicates and other data issues early.

 ## How to Reproduce

 Import the Online Retail II data into SQL Server database PortfolioProject (import text columns as text, not FLOAT).

 Run the scripts in sql/ in numeric order.

 Open the Excel workbook in excel/ and refresh the data connection

