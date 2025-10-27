/*
Fact Table: fact_7d_active_users
Purpose: Daily calculation of 7-day active user metrics
This table calculates the 7d_active_users metric: 
users with transactions in last 7 days / users with at least one open account
Updated: Nightly to maintain historical consistency and enable time-series analysis

Query Version: 1.0
Created By: Geoffrey Devitt
Created Date: 2025-10-21
------------------------------------------------------------------
Last Update By:
Last Updated Date:
Query Version:
Pull Request ID: provide GIT pull request if available.
*/

CREATE TABLE GD_take_home_task.fact_7d_active_users
(
  metric_date DATE NOT NULL,
  total_users_with_open_accounts INT64 NOT NULL,  -- Users with at least one open account
  active_users_7d INT64 NOT NULL,  -- Users with transactions in last 7 days
  active_rate_7d FLOAT64 NOT NULL,  -- active_users_7d / total_users_with_open_accounts
  total_open_accounts INT64 NOT NULL,
  active_accounts_7d INT64 NOT NULL,  -- Accounts with transactions in last 7 days
  active_accounts_rate_7d FLOAT64 NOT NULL,  -- active_accounts_7d / total_open_accounts
  total_transactions_7d INT64 NOT NULL,  -- Total transactions across all accounts in last 7 days
  avg_transactions_per_active_user FLOAT64,  -- Average transactions per active user
  avg_transactions_per_active_account FLOAT64,  -- Average transactions per active account
  load_timestamp TIMESTAMP NOT NULL
)
PARTITION BY metric_date
OPTIONS(
  description="Daily 7-day active user metrics for business KPI tracking and analysis"
);

-- ETL Query to populate fact_7d_active_users table
-- This query leverages existing dim_accounts table which already has account status and 7d transaction metrics
-- SINGLE DATE VERSION: This query processes one date at a time for optimal performance with large tables
-- For backfill: Run this query multiple times, once for each date

-- Set the target date for processing
DECLARE TARGET_DATE DATE DEFAULT '2020-08-11';

-- For backfill, run this query once for each date:
-- Example: '2020-08-01', '2020-08-02', '2020-08-03', ... '2020-08-12'

INSERT INTO GD_take_home_task.fact_7d_active_users (
  metric_date,
  total_users_with_open_accounts,
  active_users_7d,
  active_rate_7d,
  total_open_accounts,
  active_accounts_7d,
  active_accounts_rate_7d,
  total_transactions_7d,
  avg_transactions_per_active_user,
  avg_transactions_per_active_account,
  load_timestamp
)

WITH

-- Use pre-calculated account metrics from dim_accounts for the target date
account_metrics AS (
  SELECT 
    da.account_id_hashed,
    da.user_id_hashed,
    da.current_status,
    da.transactions_last_7d
  FROM GD_take_home_task.dim_accounts da
  WHERE da.metric_date = TARGET_DATE
    AND da.current_status = 'OPEN'  -- Only open accounts
),

-- Get users with at least one open account (denominator)
users_with_open_accounts AS (
  SELECT 
    user_id_hashed,
    COUNT(account_id_hashed) AS open_account_count
  FROM account_metrics
  GROUP BY user_id_hashed
),

-- Get users who had transactions in last 7 days (numerator)
users_active_7d AS (
  SELECT 
    user_id_hashed,
    COUNT(account_id_hashed) AS active_account_count,
    SUM(transactions_last_7d) AS user_total_transactions_7d
  FROM account_metrics
  WHERE transactions_last_7d > 0
  GROUP BY user_id_hashed
),

-- Get accounts that had transactions in last 7 days
accounts_active_7d AS (
  SELECT 
    account_id_hashed,
    user_id_hashed,
    transactions_last_7d
  FROM account_metrics
  WHERE transactions_last_7d > 0
),

-- Calculate aggregate metrics for the target date
aggregated_metrics AS (
  SELECT 
    TARGET_DATE AS metric_date,
    
    -- Denominator: Users with at least one open account
    COUNT(DISTINCT uoa.user_id_hashed) AS total_users_with_open_accounts,
    
    -- Numerator: Users with transactions in 7-day window
    COUNT(DISTINCT ua7d.user_id_hashed) AS active_users_7d,
    
    -- Account-level metrics for additional insights
    COUNT(DISTINCT am.account_id_hashed) AS total_open_accounts,
    COUNT(DISTINCT aa7d.account_id_hashed) AS active_accounts_7d,
    
    -- Transaction volume metrics
    COALESCE(SUM(ua7d.user_total_transactions_7d), 0) AS total_transactions_7d
    
  FROM account_metrics am
  LEFT JOIN users_with_open_accounts uoa ON am.user_id_hashed = uoa.user_id_hashed
  LEFT JOIN users_active_7d ua7d ON am.user_id_hashed = ua7d.user_id_hashed
  LEFT JOIN accounts_active_7d aa7d ON am.account_id_hashed = aa7d.account_id_hashed
)

-- Final output with calculated rates and averages
SELECT 
  metric_date,
  total_users_with_open_accounts,
  active_users_7d,
  
  -- The core 7d_active_users metric
  CASE 
    WHEN total_users_with_open_accounts > 0 
    THEN ROUND(CAST(active_users_7d AS FLOAT64) / CAST(total_users_with_open_accounts AS FLOAT64), 6)
    ELSE 0.0 
  END AS active_rate_7d,
  
  total_open_accounts,
  active_accounts_7d,
  
  -- Account-level active rate for additional insights
  CASE 
    WHEN total_open_accounts > 0 
    THEN ROUND(CAST(active_accounts_7d AS FLOAT64) / CAST(total_open_accounts AS FLOAT64), 6)
    ELSE 0.0 
  END AS active_accounts_rate_7d,
  
  total_transactions_7d,
  
  -- Average transactions per active user
  CASE 
    WHEN active_users_7d > 0 
    THEN ROUND(CAST(total_transactions_7d AS FLOAT64) / CAST(active_users_7d AS FLOAT64), 2)
    ELSE 0.0 
  END AS avg_transactions_per_active_user,
  
  -- Average transactions per active account
  CASE 
    WHEN active_accounts_7d > 0 
    THEN ROUND(CAST(total_transactions_7d AS FLOAT64) / CAST(active_accounts_7d AS FLOAT64), 2)
    ELSE 0.0 
  END AS avg_transactions_per_active_account,
  
  CURRENT_TIMESTAMP() AS load_timestamp

FROM aggregated_metrics;
