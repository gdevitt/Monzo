-- Dimension Table: dim_account_metrics_daily
-- Purpose: Daily snapshot of account-level metrics and status
-- This table stores historical daily snapshots to enable time-series analysis and trend reporting
-- Updated: Daily with timestamp to track when values were captured

CREATE TABLE dim_account_metrics_daily
(
  metric_date DATE NOT NULL,
  account_id_hashed STRING NOT NULL,
  user_id_hashed STRING NOT NULL,
  account_type STRING,
  account_status STRING NOT NULL,  -- 'OPEN', 'CLOSED' as of metric_date
  days_since_creation INT64,
  days_since_last_closure INT64,
  days_since_last_reopening INT64,
  is_active_7d BOOLEAN,  -- Had transactions in last 7 days
  is_active_30d BOOLEAN,  -- Had transactions in last 30 days
  cumulative_transactions INT64,  -- Total transactions since account creation
  transactions_last_7d INT64,
  transactions_last_30d INT64,
  load_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  
  -- Composite Primary Key
  PRIMARY KEY (metric_date, account_id_hashed) NOT ENFORCED
)
PARTITION BY DATE(metric_date)
COMMENT 'Daily snapshot of account metrics for historical analysis and trending';
