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
CREATE TABLE fact_account_trans_daily
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

INSERT INTO fact_account_trans_daily (
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

WITH account_base AS (
  -- Get all account information with creation details
  SELECT 
    acc.account_id_hashed,
    acc.user_id_hashed,
    acc.account_type,
    acc.created_ts
  FROM `analytics-take-home-test.monzo_datawarehouse.account_created` acc
),

account_status_logic AS (
  -- Determine account status for each transaction date
  SELECT 
    aba.account_id_hashed,
    aba.user_id_hashed,
    aba.account_type,
    aba.created_ts,
    acl.closed_ts,
    are.reopened_ts,
    -- Determine status based on closure/reopening events
    CASE 
      WHEN acl.closed_ts IS NULL THEN 'OPEN'
      WHEN are.reopened_ts IS NULL THEN 'CLOSED'
      WHEN are.reopened_ts > acl.closed_ts THEN 'OPEN'
      ELSE 'CLOSED'
    END AS current_status
  FROM account_base aba
  LEFT JOIN `analytics-take-home-test.monzo_datawarehouse.account_closed` acl
    ON aba.account_id_hashed = acl.account_id_hashed
  LEFT JOIN `analytics-take-home-test.monzo_datawarehouse.account_reopened` are
    ON aba.account_id_hashed = are.account_id_hashed
),

daily_transactions AS (
  -- Get daily transaction data with account details
  SELECT 
    atr.date AS trans_date,
    atr.account_id_hashed,
    asl.user_id_hashed,
    asl.account_type,
    asl.current_status AS account_status,
    atr.transactions_num,
    asl.created_ts
  FROM `analytics-take-home-test.monzo_datawarehouse.account_transactions` atr
  INNER JOIN account_status_logic asl 
    ON atr.account_id_hashed = asl.account_id_hashed
  WHERE 
    atr.date IS NOT NULL 
    AND atr.transactions_num IS NOT NULL
    AND atr.transactions_num > 0
),

first_transaction_dates AS (
  -- Identify first transaction date for each account
  SELECT 
    account_id_hashed,
    MIN(trans_date) AS first_transaction_date
  FROM daily_transactions
  GROUP BY account_id_hashed
),

rolling_metrics AS (
  -- Calculate rolling transaction sums using window functions
  SELECT 
    dt.*,
    ftd.first_transaction_date,
    
    -- Rolling 7-day sum (including current day)
    SUM(dt.transactions_num) OVER (
      PARTITION BY dt.account_id_hashed 
      ORDER BY dt.trans_date 
      ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS transactions_num_7d_rolling,
    
    -- Rolling 30-day sum (including current day)
    SUM(dt.transactions_num) OVER (
      PARTITION BY dt.account_id_hashed 
      ORDER BY dt.trans_date 
      ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ) AS transactions_num_30d_rolling,
    
    -- Days since last transaction (LAG function)
    COALESCE(
      DATE_DIFF(
        dt.trans_date, 
        LAG(dt.trans_date, 1) OVER (
          PARTITION BY dt.account_id_hashed 
          ORDER BY dt.trans_date
        ), 
        DAY
      ), 
      0
    ) AS days_since_last_transaction
    
  FROM daily_transactions dt
  LEFT JOIN first_transaction_dates ftd 
    ON dt.account_id_hashed = ftd.account_id_hashed
)

SELECT 
  rm.trans_date,
  rm.account_id_hashed,
  rm.user_id_hashed,
  rm.account_type,
  rm.account_status,
  rm.transactions_num,
  rm.transactions_num_7d_rolling,
  rm.transactions_num_30d_rolling,
  
  -- Flag if this is the first transaction for this account
  CASE 
    WHEN rm.trans_date = rm.first_transaction_date THEN TRUE 
    ELSE FALSE 
  END AS is_first_transaction,
  
  -- Days since account was created
  DATE_DIFF(rm.trans_date, DATE(rm.created_ts), DAY) AS days_since_account_created,
  
  -- Days since last transaction (0 for first transaction)
  rm.days_since_last_transaction,
  
  CURRENT_TIMESTAMP() AS load_timestamp

FROM rolling_metrics rm

-- Optional: Order by account and date for consistent results
ORDER BY rm.account_id_hashed, rm.trans_date;
