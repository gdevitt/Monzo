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

TRUNCATE TABLE GD_take_home_task.dim_account_metrics_daily;

INSERT INTO GD_take_home_task.dim_account_metrics_daily (
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

WITH 
-- Generate date range for backfill: 2020-08-01 to 2020-08-12 (12 days)
date_spine AS (
  SELECT date_value AS metric_date
  FROM UNNEST(GENERATE_DATE_ARRAY('2020-08-01', '2020-08-12', INTERVAL 1 DAY)) AS date_value
),

acc_created AS (
  SELECT 
    cre.account_id_hashed,
    cre.user_id_hashed,
    cre.account_type,
    cre.created_ts
  FROM `analytics-take-home-test.monzo_datawarehouse.account_created` cre
),

acc_closed AS (
  SELECT 
    account_id_hashed,
    COUNT(closed_ts) AS total_closures,
    MIN(closed_ts) AS first_closed_ts,
    MAX(closed_ts) AS last_closed_ts
  FROM `analytics-take-home-test.monzo_datawarehouse.account_closed`
  WHERE closed_ts IS NOT NULL
  GROUP BY account_id_hashed
),

acc_reopened AS (
  SELECT 
    account_id_hashed,
    COUNT(reopened_ts) AS total_reopenings,
    MAX(reopened_ts) AS last_reopened_ts
  FROM `analytics-take-home-test.monzo_datawarehouse.account_reopened`
  WHERE reopened_ts IS NOT NULL
  GROUP BY account_id_hashed
),

acc_trans AS (
  SELECT 
    account_id_hashed,
    SUM(transactions_num) AS cumulative_transactions,
    COUNT(DISTINCT date) AS transaction_days
  FROM `analytics-take-home-test.monzo_datawarehouse.account_transactions`
  WHERE date IS NOT NULL
  GROUP BY account_id_hashed
),

acc_trans_7d AS (
  SELECT 
    ds.metric_date,
    att.account_id_hashed,
    SUM(att.transactions_num) AS transactions_last_7d
  FROM date_spine ds
  CROSS JOIN `analytics-take-home-test.monzo_datawarehouse.account_transactions` att
  WHERE att.date BETWEEN DATE_SUB(ds.metric_date, INTERVAL 7 DAY) AND ds.metric_date
  GROUP BY ds.metric_date, att.account_id_hashed
),

acc_trans_30d AS (
  SELECT 
    ds.metric_date,
    att.account_id_hashed,
    SUM(att.transactions_num) AS transactions_last_30d
  FROM date_spine ds
  CROSS JOIN `analytics-take-home-test.monzo_datawarehouse.account_transactions` att
  WHERE att.date BETWEEN DATE_SUB(ds.metric_date, INTERVAL 30 DAY) AND ds.metric_date
  GROUP BY ds.metric_date, att.account_id_hashed
)

SELECT 
  ds.metric_date,
  acc.account_id_hashed,
  acc.user_id_hashed,
  COALESCE(acc.account_type, 'UNKNOWN') AS account_type,
  
  -- Determine current status based on closure/reopening history
  CASE 
    WHEN clo.last_closed_ts IS NULL THEN 'OPEN'
    WHEN reo.last_reopened_ts IS NULL THEN 'CLOSED'
    WHEN reo.last_reopened_ts > clo.last_closed_ts THEN 'OPEN'
    ELSE 'CLOSED'
  END AS account_status,
  
  -- Days since creation
  DATE_DIFF(ds.metric_date, DATE(acc.created_ts), DAY) AS days_since_creation,
  
  -- Days since last closure (NULL if never closed)
  CASE 
    WHEN clo.last_closed_ts IS NOT NULL 
    THEN DATE_DIFF(ds.metric_date, DATE(clo.last_closed_ts), DAY)
    ELSE NULL
  END AS days_since_last_closure,
  
  -- Days since last reopening (NULL if never reopened)
  CASE 
    WHEN reo.last_reopened_ts IS NOT NULL 
    THEN DATE_DIFF(ds.metric_date, DATE(reo.last_reopened_ts), DAY)
    ELSE NULL
  END AS days_since_last_reopening,
  
  -- Activity flags
  CASE WHEN t7d.transactions_last_7d > 0 THEN TRUE ELSE FALSE END AS is_active_7d,
  CASE WHEN t30d.transactions_last_30d > 0 THEN TRUE ELSE FALSE END AS is_active_30d,
  
  -- Transaction metrics
  COALESCE(tra.cumulative_transactions, 0) AS cumulative_transactions,
  COALESCE(t7d.transactions_last_7d, 0) AS transactions_last_7d,
  COALESCE(t30d.transactions_last_30d, 0) AS transactions_last_30d,
  
  CURRENT_TIMESTAMP() AS load_timestamp

FROM date_spine ds
CROSS JOIN acc_created acc
LEFT JOIN acc_closed clo ON acc.account_id_hashed = clo.account_id_hashed
LEFT JOIN acc_reopened reo ON acc.account_id_hashed = reo.account_id_hashed
LEFT JOIN acc_trans tra ON acc.account_id_hashed = tra.account_id_hashed
LEFT JOIN acc_trans_7d t7d ON ds.metric_date = t7d.metric_date AND acc.account_id_hashed = t7d.account_id_hashed
LEFT JOIN acc_trans_30d t30d ON ds.metric_date = t30d.metric_date AND acc.account_id_hashed = t30d.account_id_hashed
;


