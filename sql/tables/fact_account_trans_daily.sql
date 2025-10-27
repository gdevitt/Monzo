/*
Fact Table: fact_account_trans_daily
Purpose: Daily aggregated transaction metrics at account level
This table is derived from account_transactions and provides aggregated daily transaction data
Updated: Nightly based on source transaction data

Query Version: 1.0
Created By: Geoffrey Devitt
Created Date: 2025-10-21
------------------------------------------------------------------
Last Update By:
Last Updated Date:
Query Version:
Pull Request ID: provide GIT pull request if available.
*/

-- DDL for table fact_account_trans_daily
CREATE TABLE GD_take_home_task.fact_account_trans_daily
(
  trans_date DATE NOT NULL,
  account_id_hashed STRING NOT NULL,
  user_id_hashed STRING NOT NULL,
  account_type STRING,
  account_status STRING NOT NULL,  -- Status on trans_date
  transactions_num INT64 NOT NULL DEFAULT 0,
  transactions_num_7d_rolling INT64,  -- Rolling 7-day sum including trans_date
  transactions_num_30d_rolling INT64,  -- Rolling 30-day sum including trans_date
  is_first_transaction BOOLEAN,  -- Is this the first transaction day for this account
  days_since_account_created INT64,
  days_since_last_transaction INT64,
  load_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP()
)
PARTITION BY DATE(trans_date)
OPTIONS(
  description="Daily aggregated transaction facts at account level with rolling metrics"
);

-- ETL Query to populate fact_account_trans_daily table
-- This query should be run daily to update account-level transaction metrics

-- DECLARE TARGET_DATE DATE DEFAULT '2020-08-11';

INSERT INTO GD_take_home_task.fact_account_trans_daily (
  trans_date,
  account_id_hashed,
  user_id_hashed,
  account_type,
  account_status,
  transactions_num,
  transactions_num_7d_rolling,
  transactions_num_30d_rolling,
  is_first_transaction,
  days_since_account_created,
  days_since_last_transaction,
  load_timestamp
)

-- Simplified ETL leveraging pre-calculated metrics from dim_accounts
-- This approach reuses rolling window calculations instead of recalculating them
WITH 
-- Get daily transaction data from source
daily_transactions AS (
  SELECT 
    atr.date AS trans_date,
    atr.account_id_hashed,
    atr.transactions_num
  FROM `analytics-take-home-test.monzo_datawarehouse.account_transactions` atr
  WHERE 
    atr.date IS NOT NULL 
    AND atr.transactions_num IS NOT NULL
    AND atr.transactions_num > 0
),

-- Identify first transaction date for each account
first_transaction_dates AS (
  SELECT 
    account_id_hashed,
    MIN(trans_date) AS first_transaction_date
  FROM daily_transactions
  GROUP BY account_id_hashed
)

-- Main SELECT: Join transaction data with pre-calculated account metrics
SELECT 
  dt.trans_date,
  da.account_id_hashed,
  da.user_id_hashed,
  da.account_type,
  da.current_status AS account_status,
  dt.transactions_num,
  
  -- Reuse pre-calculated rolling metrics from dim_accounts
  da.transactions_last_7d AS transactions_num_7d_rolling,
  da.transactions_last_30d AS transactions_num_30d_rolling,
  
  -- Flag if this is the first transaction for this account
  CASE 
    WHEN dt.trans_date = ftd.first_transaction_date THEN TRUE 
    ELSE FALSE 
  END AS is_first_transaction,
  
  -- Reuse pre-calculated days since creation from dim_accounts
  da.days_active AS days_since_account_created,
  
  -- Reuse pre-calculated days since last transaction from dim_accounts
  COALESCE(da.days_since_last_transaction, 0) AS days_since_last_transaction,
  
  CURRENT_TIMESTAMP() AS load_timestamp

FROM daily_transactions dt
INNER JOIN GD_take_home_task.dim_accounts da 
  ON dt.account_id_hashed = da.account_id_hashed 
  AND dt.trans_date = da.metric_date  -- Join on the same date for point-in-time accuracy
LEFT JOIN first_transaction_dates ftd 
  ON dt.account_id_hashed = ftd.account_id_hashed

-- Optional: Order by account and date for consistent results
ORDER BY da.account_id_hashed, dt.trans_date;
