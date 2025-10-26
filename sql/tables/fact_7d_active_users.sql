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
-- This query implements the 7d_active_users metric as defined:
-- Users with transactions in last 7 days / Users with at least one open account
-- Designed for historical consistency and can be run for any date

-- USAGE: Replace @TARGET_DATE with the specific date you want to calculate
-- For daily ETL: SET @TARGET_DATE = CURRENT_DATE()
-- For historical: SET @TARGET_DATE = '2019-01-01'

-- Set date as 2020-08-11 for example
DECLARE TARGET_DATE DATE DEFAULT '2020-08-11';

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
-- Define the target date and 7-day window
date_params AS (
  SELECT 
    TARGET_DATE AS metric_date,
    DATE_SUB(TARGET_DATE, INTERVAL 6 DAY) AS window_start_date,
    TARGET_DATE AS window_end_date
),

-- Get all accounts with their temporal status as of the metric date
accounts_with_status AS (
  SELECT 
    acc.account_id_hashed,
    acc.user_id_hashed,
    acc.account_type,
    acc.created_ts,
    
    -- Get the most recent closure before or on metric date
    MAX(CASE 
      WHEN DATE(acl.closed_ts) <= TARGET_DATE THEN acl.closed_ts 
      ELSE NULL 
    END) AS last_closed_before_metric_date,
    
    -- Get the most recent reopening before or on metric date
    MAX(CASE 
      WHEN DATE(ar.reopened_ts) <= TARGET_DATE THEN ar.reopened_ts 
      ELSE NULL 
    END) AS last_reopened_before_metric_date,
    
    -- Determine account status as of metric date
    CASE 
      WHEN MAX(CASE WHEN DATE(acl.closed_ts) <= TARGET_DATE THEN acl.closed_ts END) IS NULL THEN 'OPEN'
      WHEN MAX(CASE WHEN DATE(ar.reopened_ts) <= TARGET_DATE THEN ar.reopened_ts END) IS NULL THEN 'CLOSED'
      WHEN MAX(CASE WHEN DATE(ar.reopened_ts) <= TARGET_DATE THEN ar.reopened_ts END) > 
           MAX(CASE WHEN DATE(acl.closed_ts) <= TARGET_DATE THEN acl.closed_ts END) THEN 'OPEN'
      ELSE 'CLOSED'
    END AS account_status_on_metric_date
    
  FROM `analytics-take-home-test.monzo_datawarehouse.account_created` acc
  LEFT JOIN `analytics-take-home-test.monzo_datawarehouse.account_closed` acl
    ON acc.account_id_hashed = acl.account_id_hashed
  LEFT JOIN `analytics-take-home-test.monzo_datawarehouse.account_reopened` ar
    ON acc.account_id_hashed = ar.account_id_hashed
  WHERE 
    -- Only include accounts created before or on the metric date
    DATE(acc.created_ts) <= TARGET_DATE
  GROUP BY 
    acc.account_id_hashed, acc.user_id_hashed, acc.account_type, acc.created_ts
),

-- Get only accounts that are OPEN as of the metric date
open_accounts_on_metric_date AS (
  SELECT 
    account_id_hashed,
    user_id_hashed,
    account_type
  FROM accounts_with_status
  WHERE account_status_on_metric_date = 'OPEN'
),

-- Get users who have at least one open account (denominator for the metric)
users_with_open_accounts AS (
  SELECT DISTINCT 
    user_id_hashed,
    COUNT(DISTINCT account_id_hashed) AS open_account_count
  FROM open_accounts_on_metric_date
  GROUP BY user_id_hashed
),

-- Get transactions in the 7-day window for open accounts only
transactions_7d_window AS (
  SELECT 
    att.account_id_hashed,
    oa.user_id_hashed,
    SUM(att.transactions_num) AS account_transactions_7d
  FROM `analytics-take-home-test.monzo_datawarehouse.account_transactions` att
  INNER JOIN open_accounts_on_metric_date oa 
    ON att.account_id_hashed = oa.account_id_hashed
  CROSS JOIN date_params dp
  WHERE 
    att.date BETWEEN dp.window_start_date AND dp.window_end_date
    AND att.transactions_num > 0
  GROUP BY att.account_id_hashed, oa.user_id_hashed
),

-- Get users who had transactions in the 7-day window (numerator for the metric)
users_active_7d AS (
  SELECT 
    user_id_hashed,
    COUNT(DISTINCT account_id_hashed) AS active_account_count,
    SUM(account_transactions_7d) AS user_total_transactions_7d
  FROM transactions_7d_window
  GROUP BY user_id_hashed
),

-- Get accounts that had transactions in the 7-day window
accounts_active_7d AS (
  SELECT DISTINCT 
    account_id_hashed,
    user_id_hashed,
    account_transactions_7d
  FROM transactions_7d_window
),

-- Calculate aggregate metrics
aggregated_metrics AS (
  SELECT 
    dp.metric_date,
    
    -- Denominator: Users with at least one open account
    COUNT(DISTINCT uoa.user_id_hashed) AS total_users_with_open_accounts,
    
    -- Numerator: Users with transactions in 7-day window
    COUNT(DISTINCT ua7d.user_id_hashed) AS active_users_7d,
    
    -- Account-level metrics for additional insights
    COUNT(DISTINCT oa.account_id_hashed) AS total_open_accounts,
    COUNT(DISTINCT aa7d.account_id_hashed) AS active_accounts_7d,
    
    -- Transaction volume metrics
    COALESCE(SUM(ua7d.user_total_transactions_7d), 0) AS total_transactions_7d
    
  FROM date_params dp
  CROSS JOIN users_with_open_accounts uoa
  LEFT JOIN users_active_7d ua7d 
    ON uoa.user_id_hashed = ua7d.user_id_hashed
  CROSS JOIN open_accounts_on_metric_date oa
  LEFT JOIN accounts_active_7d aa7d 
    ON oa.account_id_hashed = aa7d.account_id_hashed
  GROUP BY dp.metric_date
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
