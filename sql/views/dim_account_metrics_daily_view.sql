-- View: dim_account_metrics_daily_view
-- Purpose: Enhanced view of daily account metrics with additional calculated fields and business logic
-- This view provides analyst-friendly metrics for dashboard reporting and analysis

CREATE OR REPLACE VIEW dim_account_metrics_daily_view AS
SELECT
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
  
  -- Derived activity metrics
  CASE
    WHEN is_active_7d THEN 'ACTIVE_7D'
    WHEN is_active_30d THEN 'ACTIVE_30D'
    ELSE 'INACTIVE'
  END AS activity_segment,
  
  -- Transaction intensity
  CASE
    WHEN transactions_last_7d >= 10 THEN 'HIGH'
    WHEN transactions_last_7d >= 5 THEN 'MEDIUM'
    WHEN transactions_last_7d >= 1 THEN 'LOW'
    ELSE 'NONE'
  END AS transaction_intensity_7d,
  
  -- Account maturity
  CASE
    WHEN days_since_creation <= 30 THEN 'NEW'
    WHEN days_since_creation <= 90 THEN 'GROWING'
    WHEN days_since_creation <= 365 THEN 'ESTABLISHED'
    ELSE 'MATURE'
  END AS account_maturity,
  
  -- Engagement score (simple scoring based on transaction frequency)
  CASE
    WHEN is_active_7d AND transactions_last_7d >= 10 THEN 5
    WHEN is_active_7d AND transactions_last_7d >= 5 THEN 4
    WHEN is_active_7d THEN 3
    WHEN is_active_30d THEN 2
    ELSE 1
  END AS engagement_score,
  
  -- Time-based attributes
  EXTRACT(YEAR FROM metric_date) AS metric_year,
  EXTRACT(MONTH FROM metric_date) AS metric_month,
  EXTRACT(QUARTER FROM metric_date) AS metric_quarter,
  FORMAT_DATE('%Y-%m', metric_date) AS metric_year_month,
  FORMAT_DATE('%A', metric_date) AS day_of_week,
  
  load_timestamp
FROM
  dim_account_metrics_daily
;
