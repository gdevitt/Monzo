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

WITH date_spine AS (
  -- Generate date for daily metric calculation
  SELECT CURRENT_DATE() AS metric_date
),

-- Get all open accounts as of the metric date
open_accounts AS (
  SELECT DISTINCT
    ac.account_id_hashed,
    ac.user_id_hashed,
    ac.account_type
  FROM `analytics-take-home-test.monzo_datawarehouse.account_created` ac
  LEFT JOIN `analytics-take-home-test.monzo_datawarehouse.account_closed` acl
    ON ac.account_id_hashed = acl.account_id_hashed
  LEFT JOIN `analytics-take-home-test.monzo_datawarehouse.account_reopened` ar
    ON ac.account_id_hashed = ar.account_id_hashed
  WHERE 
    -- Account is currently open based on closure/reopening logic
    (acl.closed_ts IS NULL OR 
     (ar.reopened_ts IS NOT NULL AND ar.reopened_ts > acl.closed_ts))
),

-- Get users with open accounts
users_with_open_accounts AS (
  SELECT DISTINCT 
    user_id_hashed,
    COUNT(DISTINCT account_id_hashed) AS open_accounts_count
  FROM open_accounts
  GROUP BY user_id_hashed
),

-- Get accounts with transactions in the last 7 days
accounts_active_7d AS (
  SELECT 
    att.account_id_hashed,
    oa.user_id_hashed,
    SUM(att.transactions_num) AS transactions_7d
  FROM `analytics-take-home-test.monzo_datawarehouse.account_transactions` att
  INNER JOIN open_accounts oa 
    ON att.account_id_hashed = oa.account_id_hashed
  WHERE 
    att.date BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY) AND CURRENT_DATE()
    AND att.transactions_num > 0
  GROUP BY att.account_id_hashed, oa.user_id_hashed
),

-- Get users with transactions in the last 7 days
users_active_7d AS (
  SELECT 
    user_id_hashed,
    COUNT(DISTINCT account_id_hashed) AS active_accounts_count,
    SUM(transactions_7d) AS user_transactions_7d
  FROM accounts_active_7d
  GROUP BY user_id_hashed
),

-- Get total transactions in last 7 days across all accounts
total_transactions_7d AS (
  SELECT 
    SUM(att.transactions_num) AS total_transactions_7d
  FROM `analytics-take-home-test.monzo_datawarehouse.account_transactions` att
  INNER JOIN open_accounts oa 
    ON att.account_id_hashed = oa.account_id_hashed
  WHERE 
    att.date BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY) AND CURRENT_DATE()
    AND att.transactions_num > 0
),

-- Calculate final metrics
metrics AS (
  SELECT 
    ds.metric_date,
    
    -- User metrics
    COUNT(DISTINCT uoa.user_id_hashed) AS total_users_with_open_accounts,
    COUNT(DISTINCT ua7d.user_id_hashed) AS active_users_7d,
    
    -- Account metrics
    COUNT(DISTINCT oa.account_id_hashed) AS total_open_accounts,
    COUNT(DISTINCT aa7d.account_id_hashed) AS active_accounts_7d,
    
    -- Transaction metrics
    COALESCE(tt7d.total_transactions_7d, 0) AS total_transactions_7d,
    
    -- Averages
    CASE 
      WHEN COUNT(DISTINCT ua7d.user_id_hashed) > 0 
      THEN ROUND(COALESCE(tt7d.total_transactions_7d, 0) / COUNT(DISTINCT ua7d.user_id_hashed), 2)
      ELSE 0 
    END AS avg_transactions_per_active_user,
    
    CASE 
      WHEN COUNT(DISTINCT aa7d.account_id_hashed) > 0 
      THEN ROUND(COALESCE(tt7d.total_transactions_7d, 0) / COUNT(DISTINCT aa7d.account_id_hashed), 2)
      ELSE 0 
    END AS avg_transactions_per_active_account
    
  FROM date_spine ds
  CROSS JOIN users_with_open_accounts uoa
  CROSS JOIN open_accounts oa
  LEFT JOIN users_active_7d ua7d ON uoa.user_id_hashed = ua7d.user_id_hashed
  LEFT JOIN accounts_active_7d aa7d ON oa.account_id_hashed = aa7d.account_id_hashed
  CROSS JOIN total_transactions_7d tt7d
  GROUP BY ds.metric_date, tt7d.total_transactions_7d
)

SELECT 
  metric_date,
  total_users_with_open_accounts,
  active_users_7d,
  
  -- Calculate active rate with safe division
  CASE 
    WHEN total_users_with_open_accounts > 0 
    THEN ROUND(CAST(active_users_7d AS FLOAT64) / CAST(total_users_with_open_accounts AS FLOAT64), 4)
    ELSE 0.0 
  END AS active_rate_7d,
  
  total_open_accounts,
  active_accounts_7d,
  
  -- Calculate active account rate with safe division
  CASE 
    WHEN total_open_accounts > 0 
    THEN ROUND(CAST(active_accounts_7d AS FLOAT64) / CAST(total_open_accounts AS FLOAT64), 4)
    ELSE 0.0 
  END AS active_accounts_rate_7d,
  
  total_transactions_7d,
  avg_transactions_per_active_user,
  avg_transactions_per_active_account,
  CURRENT_TIMESTAMP() AS load_timestamp

FROM metrics;
