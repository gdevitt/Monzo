-- View: fact_account_trans_daily_view
-- Purpose: Enhanced view of daily transaction facts with calculated metrics for reporting
-- This view adds business context and time-based attributes for easier dashboard creation

CREATE OR REPLACE VIEW fact_account_trans_daily_view AS
SELECT
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
  
  -- Transaction velocity metrics
  CASE
    WHEN transactions_num_7d_rolling >= 20 THEN 'VERY_HIGH'
    WHEN transactions_num_7d_rolling >= 10 THEN 'HIGH'
    WHEN transactions_num_7d_rolling >= 5 THEN 'MEDIUM'
    WHEN transactions_num_7d_rolling >= 1 THEN 'LOW'
    ELSE 'NONE'
  END AS transaction_velocity_7d,
  
  -- Account lifecycle phase
  CASE
    WHEN is_first_transaction THEN 'ACTIVATION'
    WHEN days_since_account_created <= 30 THEN 'ONBOARDING'
    WHEN days_since_account_created <= 90 THEN 'GROWTH'
    ELSE 'MATURE'
  END AS lifecycle_phase,
  
  -- Recency segment
  CASE
    WHEN days_since_last_transaction = 0 THEN 'CURRENT'
    WHEN days_since_last_transaction <= 7 THEN 'RECENT'
    WHEN days_since_last_transaction <= 30 THEN 'CASUAL'
    ELSE 'DORMANT'
  END AS recency_segment,
  
  -- Time-based dimensions for reporting
  EXTRACT(YEAR FROM trans_date) AS trans_year,
  EXTRACT(MONTH FROM trans_date) AS trans_month,
  EXTRACT(QUARTER FROM trans_date) AS trans_quarter,
  EXTRACT(DAYOFWEEK FROM trans_date) AS trans_day_of_week,
  FORMAT_DATE('%Y-%m', trans_date) AS trans_year_month,
  FORMAT_DATE('%Y-Q%Q', trans_date) AS trans_year_quarter,
  FORMAT_DATE('%A', trans_date) AS trans_day_name,
  
  -- Flags for analysis
  CASE WHEN EXTRACT(DAYOFWEEK FROM trans_date) IN (1, 7) THEN TRUE ELSE FALSE END AS is_weekend,
  
  load_timestamp
FROM
  fact_account_trans_daily
;
