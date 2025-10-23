-- Fact Table: fact_7d_active_users
-- Purpose: Daily calculation of 7-day active user metrics
-- This table calculates the 7d_active_users metric: users with transactions in last 7 days / users with at least one open account
-- Updated: Nightly to maintain historical consistency and enable time-series analysis

CREATE TABLE fact_7d_active_users
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
  load_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  
  -- Primary Key
  PRIMARY KEY (metric_date) NOT ENFORCED
)
PARTITION BY DATE(metric_date)
COMMENT 'Daily 7-day active user metrics for business KPI tracking and analysis';
