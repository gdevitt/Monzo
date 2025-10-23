-- View: fact_7d_active_users_view
-- Purpose: Enhanced view of 7-day active user metrics with trend indicators and time dimensions
-- This view is optimized for business KPI dashboards and executive reporting

CREATE OR REPLACE VIEW GD_take_home_task.fact_7d_active_users_view AS
SELECT
  metric_date,
  total_users_with_open_accounts,
  active_users_7d,
  ROUND(active_rate_7d * 100, 2) AS active_rate_7d_pct,  -- Convert to percentage
  total_open_accounts,
  active_accounts_7d,
  ROUND(active_accounts_rate_7d * 100, 2) AS active_accounts_rate_7d_pct,
  total_transactions_7d,
  ROUND(avg_transactions_per_active_user, 2) AS avg_transactions_per_active_user,
  ROUND(avg_transactions_per_active_account, 2) AS avg_transactions_per_active_account,
  
  -- User and account ratios
  ROUND(SAFE_DIVIDE(total_open_accounts, total_users_with_open_accounts), 2) AS accounts_per_user,
  
  -- Engagement metrics
  total_users_with_open_accounts - active_users_7d AS inactive_users_7d,
  ROUND((1 - active_rate_7d) * 100, 2) AS inactive_rate_7d_pct,
  
  -- Time-based dimensions
  EXTRACT(YEAR FROM metric_date) AS metric_year,
  EXTRACT(MONTH FROM metric_date) AS metric_month,
  EXTRACT(QUARTER FROM metric_date) AS metric_quarter,
  EXTRACT(DAYOFWEEK FROM metric_date) AS metric_day_of_week,
  FORMAT_DATE('%Y-%m', metric_date) AS metric_year_month,
  FORMAT_DATE('%Y-Q%Q', metric_date) AS metric_year_quarter,
  FORMAT_DATE('%B %Y', metric_date) AS metric_month_name,
  FORMAT_DATE('%A', metric_date) AS metric_day_name,
  
  -- Performance indicators
  CASE
    WHEN active_rate_7d >= 0.7 THEN 'EXCELLENT'
    WHEN active_rate_7d >= 0.5 THEN 'GOOD'
    WHEN active_rate_7d >= 0.3 THEN 'AVERAGE'
    ELSE 'NEEDS_ATTENTION'
  END AS performance_category,
  
  -- LAG functions for trend analysis (comparing to previous day)
  LAG(active_rate_7d, 1) OVER (ORDER BY metric_date) AS active_rate_7d_prev_day,
  active_rate_7d - LAG(active_rate_7d, 1) OVER (ORDER BY metric_date) AS active_rate_7d_day_change,
  
  -- LAG for week-over-week comparison
  LAG(active_rate_7d, 7) OVER (ORDER BY metric_date) AS active_rate_7d_prev_week,
  active_rate_7d - LAG(active_rate_7d, 7) OVER (ORDER BY metric_date) AS active_rate_7d_week_change,
  
  load_timestamp
FROM
  GD_take_home_task.fact_7d_active_users
WHERE metric_date = CURRENT_DATE()
;
