/*
Dimension Table: dim_account_metrics_daily
Purpose: Daily snapshot of account-level metrics and status
This table stores historical daily snapshots to enable time-series analysis and trend reporting
Updated: Daily with timestamp to track when values were captured
Query Version: 1.0
Created By: Geoffrey Devitt
Created Date: 2025-10-21
------------------------------------------------------------------
Last Update By:
Last Updated Date:
Query Version:
Pull Request ID: provide GIT pull request if available.
*/

-- DROP TABLE GD_take_home_task.account_detail_customer;

-- CREATE TABLE GD_take_home_task.dim_account_metrics_daily
-- (
--   metric_date DATE NOT NULL,
--   account_id_hashed STRING NOT NULL,
--   user_id_hashed STRING NOT NULL,
--   account_type STRING,
--   account_status STRING NOT NULL,  -- 'OPEN', 'CLOSED' as of metric_date
--   days_since_creation INT64,
--   days_since_last_closure INT64,
--   days_since_last_reopening INT64,
--   is_active_7d BOOLEAN,  -- Had transactions in last 7 days
--   is_active_30d BOOLEAN,  -- Had transactions in last 30 days
--   cumulative_transactions INT64,  -- Total transactions since account creation
--   transactions_last_7d INT64,
--   transactions_last_30d INT64,
--   load_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP()
-- )
-- PARTITION BY metric_date
-- OPTIONS(
--   description="Daily snapshot of account metrics for historical analysis and trending"
-- );

-- ETL Query to populate dim_account_metrics_daily table
-- BACKFILL VERSION: This query runs for date range 2020-08-01 to 2020-08-12
-- This creates daily snapshots of account metrics for historical analysis

-- For single date: DECLARE TARGET_DATE DATE DEFAULT '2020-08-12';
-- For backfill: Use date range generation below

TRUNCATE TABLE GD_take_home_task.dim_accounts_metrics_daily;

INSERT INTO GD_take_home_task.dim_accounts_metrics_daily (
  metric_date,
  account_id_hashed,
  user_id_hashed,
  account_type,
  account_status,
  days_since_creation,
  days_since_last_closure,
  days_since_last_reopening,
  is_active_7d,
  is_active_30d,
  cumulative_transactions,
  transactions_last_7d,
  transactions_last_30d,
  load_timestamp
)

-- Simplified query leveraging pre-calculated metrics from dim_accounts table
-- This approach eliminates complex CTEs by using the already computed account metrics
SELECT 
  da.metric_date,
  da.account_id_hashed,
  da.user_id_hashed,
  COALESCE(da.account_type, 'UNKNOWN') AS account_type,
  da.current_status AS account_status,
  
  -- Days since creation (calculated from dim_accounts)
  da.days_active AS days_since_creation,
  
  -- Days since last closure (calculated from dim_accounts first_closed_ts)
  CASE 
    WHEN da.first_closed_ts IS NOT NULL 
    THEN DATE_DIFF(da.metric_date, DATE(da.first_closed_ts), DAY)
    ELSE NULL
  END AS days_since_last_closure,
  
  -- Days since last reopening (calculated from dim_accounts last_reopened_ts)
  CASE 
    WHEN da.last_reopened_ts IS NOT NULL 
    THEN DATE_DIFF(da.metric_date, DATE(da.last_reopened_ts), DAY)
    ELSE NULL
  END AS days_since_last_reopening,
  
  -- Activity flags based on pre-calculated transaction metrics
  CASE WHEN da.transactions_last_7d > 0 THEN TRUE ELSE FALSE END AS is_active_7d,
  CASE WHEN da.transactions_last_30d > 0 THEN TRUE ELSE FALSE END AS is_active_30d,
  
  -- Transaction metrics directly from dim_accounts
  da.total_transactions AS cumulative_transactions,
  da.transactions_last_7d,
  da.transactions_last_30d,
  
  CURRENT_TIMESTAMP() AS load_timestamp

FROM GD_take_home_task.dim_accounts da
WHERE da.metric_date BETWEEN '2020-08-01' AND '2020-08-12'  -- Backfill date range
;

