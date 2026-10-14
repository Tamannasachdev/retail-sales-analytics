Data Cleaning Findings & Decisions
1. Cancelled / Returned Orders — Negative Quantity
The dataset does not consistently use the “C%” invoice format to identify returns. I therefore used negative quantities as the main indicator.

Negative-quantity records make up around 2–2.3% of rows each year. Some are genuine returns, while others relate to damaged or missing stock.

Decision: Removed these records from revenue calculations but kept them separately in returns_and_adjustments for future return-rate analysis.

2. Missing CustomerID
Approximately 20–25% of rows per year have a missing CustomerID.

These transactions can still provide useful information for overall revenue, product and country analysis, but they cannot reliably be linked to an individual customer.

Decision:Kept them for sales analysis but excluded them from customer-level analysis such as RFM, retention, and CLV.

3. Zero / Negative Price

Rows with Price <= 0 substantially overlap with the negative-quantity records. Many are associated with damages, stock losses or other adjustments. A small number, such as "Adjust bad debt", are financial adjustments rather than product sales.

Decision: Excluded all Price <= 0 rows from revenue KPIs and treat them as part of the same non-sale category as returns and adjustments.

4. Duplicate Excel Metadata Tables

The original Excel file contained extra tables named _xlnm#_FilterDatabase. These were not additional sales data. They were created by Excel to store information about filters used in the worksheets.

The number of rows in these tables matched the original data ranges, confirming that they were only Excel filter information.

Decision: Excluded these tables from the project and used only:
Year 2009-2010$
Year 2010-2011$

5. StockCode Import Type Mismatch — Data Loss

During the initial import of the 2009–2010 data, SQL Server automatically inferred StockCode as FLOAT. This caused alphanumeric product codes such as "85123A" to be converted to NULL.

This affected 80,112 of 525,461 rows (15.2%). The issue was identified by comparing the NULL rate with the 2010–2011 data, where StockCode was correctly stored as text.

Solution: I Re-imported the source through a staging table with columns initially stored as NVARCHAR, then safely converted fields using TRY_CAST where appropriate. Known product codes and row counts were checked after the fix.

6. Schema Standardization Across Years

The two source tables contained inconsistent data types. For example, Invoice was stored as FLOAT in one table and NVARCHAR in the other.

Since Invoice and StockCode are identifiers rather than numeric measures, converting them to numeric types was unnecessary and created problems when combining the datasets.

Decision: Standardize the schemas before combining both years into retail_transactions, with identifiers such as Invoice and StockCode stored as NVARCHAR.

This prevented type conflicts during UNION ALL and ensured consistent downstream analysis.

7. InvoiceDate — Ambiguous Date Format

After combining the two years, a monthly revenue check revealed 299,493 rows (~28% of the dataset) with a NULL InvoiceDate. 
The problem was mainly in the 2009–2010 data. The dates were stored as text in the dd-mm-yyyy format.
Initially, I used 
TRY_CAST(InvoiceDate AS DATETIME)

This caused problems because SQL Server could interpret the dates differently depending on the day and month. Dates where the day was greater than 12 could become blank, while dates where both numbers were 12 or below could be interpreted incorrectly without showing an error.

Solution: I changed the conversion to:

TRY_CONVERT(DATETIME, InvoiceDate, 105)

This tells SQL Server specifically that the dates are in the dd-mm-yyyy format.

After making the change, I rebuilt the affected cleaning steps and checked the results using row counts and monthly sales figures.

The corrected data produced much more sensible monthly patterns, including the expected increase in sales during November and December.
