# Data

## Source

This project uses the **Online Retail II** dataset, originally from the UCI Machine Learning Repository, available via Kaggle:

🔗 [Online Retail II (UCI) Dataset — Kaggle](https://www.kaggle.com/datasets/cgrymn/online-retail-ii-uci-dataset/data)

The dataset contains all transactions occurring between **01/12/2009 and 09/12/2011** for a UK-based, registered, non-store online retailer specializing in unique, all-occasion giftware. Many customers are wholesalers.

- **Raw size:** ~1.07M rows across two sheets (`Year 2009-2010`, `Year 2010-2011`)
- **Format:** Excel (.xlsx), later converted to CSV for import

## Why the raw/cleaned data isn't included in this repo

The raw dataset exceeds typical GitHub file-size practicality for a portfolio repo. Instead:
- The **source link above** can be used to download the original file directly
- All data cleaning logic is fully documented and reproducible via the scripts in [`/sql/01_data_cleaning.sql`](../sql/01_data_cleaning.sql)
- A full account of every data quality issue found and how it was resolved is in [`data_cleaning_log.md`](../data_cleaning_log.md)

## Reproducing the cleaned dataset

1. Download the dataset from the Kaggle link above
2. Load both year sheets into SQL Server (see `01_data_cleaning.sql` for required schema/type handling — note the known StockCode and InvoiceDate import pitfalls documented in the cleaning log)
3. Run the scripts in `/sql/` in numbered order to reproduce the full cleaning, deduplication, and view-building pipeline
