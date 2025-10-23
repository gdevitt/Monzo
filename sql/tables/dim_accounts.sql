/*
Dimension Table: dim_accounts
Purpose: Consolidated view of all accounts with their current status
This table maintains the complete lifecycle of each account including 
creation, closure, and reopening events
Updated: Nightly refresh based on source tables

Query Version: 1.0
Created By: Geoffrey Devitt
Created Date: 2025-10-21
------------------------------------------------------------------
Last Update By:
Last Updated Date:
Query Version:
Pull Request ID: provide GIT pull request if available.
------------------------------------------------------------------
*/


-- DDL for table dim_accounts
CREATE TABLE dim_accounts
(
  metric_date DATE NOT NULL,
  account_id_hashed STRING NOT NULL,
  user_id_hashed STRING NOT NULL,
  account_type STRING,
  created_ts TIMESTAMP NOT NULL,
  first_closed_ts TIMESTAMP,
  last_reopened_ts TIMESTAMP,
  current_status STRING NOT NULL,  -- 'OPEN', 'CLOSED'
  total_closures INT64 DEFAULT 0,
  total_reopenings INT64 DEFAULT 0,
  days_active INT64,  -- Total days account has been active
  
  -- Transaction metrics
  total_transactions INT64 DEFAULT 0,  -- Lifetime total transactions
  total_transaction_days INT64 DEFAULT 0,  -- Number of days with transactions
  first_transaction_date DATE,  -- Date of first transaction
  last_transaction_date DATE,  -- Date of last transaction
  avg_daily_transactions FLOAT64,  -- Average transactions per active day
  max_daily_transactions INT64,  -- Maximum transactions in a single day
  transactions_last_7d INT64 DEFAULT 0,  -- Transactions in last 7 days
  transactions_last_30d INT64 DEFAULT 0,  -- Transactions in last 30 days
  days_since_last_transaction INT64,  -- Days since last transaction
  
  load_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP()
)
OPTIONS(
  description="Dimension table containing consolidated account information with lifecycle status and transaction metrics"
);


-- DDL for table dim_accounts
CREATE TABLE GD_take_home_task.dim_accounts
(
  account_id_hashed STRING NOT NULL,
  user_id_hashed STRING NOT NULL,
  account_type STRING,
  created_ts TIMESTAMP NOT NULL,
  first_closed_ts TIMESTAMP,
  last_reopened_ts TIMESTAMP,
  current_status STRING NOT NULL,
  total_closures INT64 DEFAULT 0,
  total_reopenings INT64 DEFAULT 0,
  days_active INT64,
  load_timestamp TIMESTAMP NOT NULL 
)
OPTIONS(
  description="Dimension table containing consolidated account information with lifecycle status"
);


-- TRUNCATE TABLE GD_take_home_task.dim_accounts;
INSERT INTO GD_take_home_task.dim_accounts
WITH date_spine AS (
  -- Generate date range for daily snapshots
  SELECT CURRENT_DATE() AS metric_date
),
transaction_metrics AS (
  -- Calculate all transaction metrics per account
  SELECT 
    account_id_hashed,
    SUM(transactions_num) AS total_transactions,
    COUNT(DISTINCT date) AS total_transaction_days,
    MIN(date) AS first_transaction_date,
    MAX(date) AS last_transaction_date,
    ROUND(AVG(transactions_num), 2) AS avg_daily_transactions,
    MAX(transactions_num) AS max_daily_transactions,
    -- Transactions in last 7 days
    SUM(CASE 
      WHEN date BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY) AND CURRENT_DATE() 
      THEN transactions_num 
      ELSE 0 
    END) AS transactions_last_7d,
    -- Transactions in last 30 days
    SUM(CASE 
      WHEN date BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY) AND CURRENT_DATE() 
      THEN transactions_num 
      ELSE 0 
    END) AS transactions_last_30d,
    -- Days since last transaction
    DATE_DIFF(CURRENT_DATE(), MAX(date), DAY) AS days_since_last_transaction
  FROM `analytics-take-home-test.monzo_datawarehouse.account_transactions`
  WHERE date IS NOT NULL AND transactions_num IS NOT NULL
  GROUP BY account_id_hashed
)

SELECT
  ds.metric_date,
  ac.account_id_hashed,
  ac.user_id_hashed,
  ac.account_type,
  ac.created_ts,
  MIN(acl.closed_ts) AS first_closed_ts,
  MAX(ar.reopened_ts) AS last_reopened_ts,
  CASE
    WHEN MAX(ar.reopened_ts) > MIN(acl.closed_ts) THEN 'OPEN'
    WHEN COUNT(acl.closed_ts) > 0 THEN 'CLOSED'
    ELSE 'OPEN'
  END AS current_status,
  COUNT(DISTINCT acl.closed_ts) AS total_closures,
  COUNT(DISTINCT ar.reopened_ts) AS total_reopenings,
  DATE_DIFF(CURRENT_DATE(), DATE(ac.created_ts), DAY) AS days_active,
  
  -- Transaction metrics (with defaults for accounts with no transactions)
  COALESCE(tm.total_transactions, 0) AS total_transactions,
  COALESCE(tm.total_transaction_days, 0) AS total_transaction_days,
  tm.first_transaction_date,
  tm.last_transaction_date,
  tm.avg_daily_transactions,
  COALESCE(tm.max_daily_transactions, 0) AS max_daily_transactions,
  COALESCE(tm.transactions_last_7d, 0) AS transactions_last_7d,
  COALESCE(tm.transactions_last_30d, 0) AS transactions_last_30d,
  tm.days_since_last_transaction,
  
  CURRENT_TIMESTAMP() AS load_timestamp

FROM date_spine ds

CROSS JOIN `analytics-take-home-test.monzo_datawarehouse.account_created` ac

LEFT JOIN `analytics-take-home-test.monzo_datawarehouse.account_closed` acl 
ON ac.account_id_hashed = acl.account_id_hashed

LEFT JOIN `analytics-take-home-test.monzo_datawarehouse.account_reopened` ar 
ON ac.account_id_hashed = ar.account_id_hashed

LEFT JOIN transaction_metrics tm 
ON ac.account_id_hashed = tm.account_id_hashed

GROUP BY   
  ds.metric_date,
  ac.account_id_hashed,
  ac.user_id_hashed,
  ac.account_type,
  ac.created_ts,
  tm.total_transactions,
  tm.total_transaction_days, 
  tm.first_transaction_date,
  tm.last_transaction_date,
  tm.avg_daily_transactions,
  tm.max_daily_transactions,
  tm.transactions_last_7d,
  tm.transactions_last_30d,
  tm.days_since_last_transaction
;
