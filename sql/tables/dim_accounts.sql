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
CREATE TABLE GD_take_home_task.dim_accounts
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


-- ETL Query to populate dim_accounts table
-- BACKFILL VERSION: This query runs for date range 2020-08-01 to 2020-08-12
-- This creates daily snapshots of account dimension with point-in-time metrics

-- For single date: DECLARE TARGET_DATE DATE DEFAULT '2020-08-12';
-- For backfill: Use date range generation below

-- TRUNCATE TABLE GD_take_home_task.dim_accounts;
INSERT INTO GD_take_home_task.dim_accounts
WITH 
-- Generate date range for backfill: 2020-08-01 to 2020-08-12 (12 days)
date_spine AS (
  SELECT date_value AS metric_date
  FROM UNNEST(GENERATE_DATE_ARRAY('2020-08-01', '2020-08-12', INTERVAL 1 DAY)) AS date_value
),

-- Calculate transaction metrics as of each metric date
transaction_metrics AS (
  SELECT 
    ds.metric_date,
    att.account_id_hashed,
    -- Cumulative transactions up to metric date
    SUM(att.transactions_num) AS total_transactions,
    COUNT(DISTINCT att.date) AS total_transaction_days,
    MIN(att.date) AS first_transaction_date,
    MAX(att.date) AS last_transaction_date,
    ROUND(AVG(att.transactions_num), 2) AS avg_daily_transactions,
    MAX(att.transactions_num) AS max_daily_transactions,
    -- Days since last transaction as of metric date
    DATE_DIFF(ds.metric_date, MAX(att.date), DAY) AS days_since_last_transaction
  FROM date_spine ds
  CROSS JOIN `analytics-take-home-test.monzo_datawarehouse.account_transactions` att
  WHERE 
    att.date <= ds.metric_date  -- Only transactions up to metric date
    AND att.date IS NOT NULL 
    AND att.transactions_num IS NOT NULL
  GROUP BY ds.metric_date, att.account_id_hashed
),

-- Calculate 7-day rolling transactions as of each metric date
transactions_7d AS (
  SELECT 
    ds.metric_date,
    att.account_id_hashed,
    SUM(att.transactions_num) AS transactions_last_7d
  FROM date_spine ds
  CROSS JOIN `analytics-take-home-test.monzo_datawarehouse.account_transactions` att
  WHERE 
    att.date BETWEEN DATE_SUB(ds.metric_date, INTERVAL 6 DAY) AND ds.metric_date
    AND att.transactions_num > 0
  GROUP BY ds.metric_date, att.account_id_hashed
),

-- Calculate 30-day rolling transactions as of each metric date
transactions_30d AS (
  SELECT 
    ds.metric_date,
    att.account_id_hashed,
    SUM(att.transactions_num) AS transactions_last_30d
  FROM date_spine ds
  CROSS JOIN `analytics-take-home-test.monzo_datawarehouse.account_transactions` att
  WHERE 
    att.date BETWEEN DATE_SUB(ds.metric_date, INTERVAL 29 DAY) AND ds.metric_date
    AND att.transactions_num > 0
  GROUP BY ds.metric_date, att.account_id_hashed
)

SELECT
  ds.metric_date,
  ac.account_id_hashed,
  ac.user_id_hashed,
  case 
    when ac.account_type = 'uk_retail_pot' then 'Savings AC'
    when ac.account_type = 'uk_retail_joint' then 'Joint AC'
    when ac.account_type = 'uk_retail' then 'Current AC'
    else 'Unclassified AC'
  end as account_type,
  ac.created_ts,
  -- Get first closure that happened before or on metric date
  MIN(CASE 
    WHEN DATE(acl.closed_ts) <= ds.metric_date THEN acl.closed_ts 
    ELSE NULL 
  END) AS first_closed_ts,
  
  -- Get last reopening that happened before or on metric date
  MAX(CASE 
    WHEN DATE(ar.reopened_ts) <= ds.metric_date THEN ar.reopened_ts 
    ELSE NULL 
  END) AS last_reopened_ts,
  -- Determine account status as of metric date
  CASE
    WHEN MAX(CASE WHEN DATE(ar.reopened_ts) <= ds.metric_date THEN ar.reopened_ts END) > 
         MIN(CASE WHEN DATE(acl.closed_ts) <= ds.metric_date THEN acl.closed_ts END) THEN 'OPEN'
    WHEN COUNT(CASE WHEN DATE(acl.closed_ts) <= ds.metric_date THEN acl.closed_ts END) > 0 THEN 'CLOSED'
    ELSE 'OPEN'
  END AS current_status,
  
  -- Count closures and reopenings up to metric date
  COUNT(CASE WHEN DATE(acl.closed_ts) <= ds.metric_date THEN acl.closed_ts END) AS total_closures,
  COUNT(CASE WHEN DATE(ar.reopened_ts) <= ds.metric_date THEN ar.reopened_ts END) AS total_reopenings,
  -- Days active as of metric date
  DATE_DIFF(ds.metric_date, DATE(ac.created_ts), DAY) AS days_active,
  
  -- Transaction metrics (with defaults for accounts with no transactions)
  COALESCE(tm.total_transactions, 0) AS total_transactions,
  COALESCE(tm.total_transaction_days, 0) AS total_transaction_days,
  tm.first_transaction_date,
  tm.last_transaction_date,
  tm.avg_daily_transactions,
  COALESCE(tm.max_daily_transactions, 0) AS max_daily_transactions,
  COALESCE(t7d.transactions_last_7d, 0) AS transactions_last_7d,
  COALESCE(t30d.transactions_last_30d, 0) AS transactions_last_30d,
  tm.days_since_last_transaction,
  
  CURRENT_TIMESTAMP() AS load_timestamp

FROM date_spine ds

CROSS JOIN `analytics-take-home-test.monzo_datawarehouse.account_created` ac

LEFT JOIN `analytics-take-home-test.monzo_datawarehouse.account_closed` acl 
ON ac.account_id_hashed = acl.account_id_hashed

LEFT JOIN `analytics-take-home-test.monzo_datawarehouse.account_reopened` ar 
ON ac.account_id_hashed = ar.account_id_hashed

LEFT JOIN transaction_metrics tm 
  ON ds.metric_date = tm.metric_date AND ac.account_id_hashed = tm.account_id_hashed
LEFT JOIN transactions_7d t7d 
  ON ds.metric_date = t7d.metric_date AND ac.account_id_hashed = t7d.account_id_hashed
LEFT JOIN transactions_30d t30d 
  ON ds.metric_date = t30d.metric_date AND ac.account_id_hashed = t30d.account_id_hashed

WHERE 
  -- Only include accounts that existed as of the metric date
  DATE(ac.created_ts) <= ds.metric_date

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
  t7d.transactions_last_7d,
  t30d.transactions_last_30d,
  tm.days_since_last_transaction
  ;
