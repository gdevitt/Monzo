-- View: dim_accounts_view
-- Purpose: Provides a clean, user-friendly view of the dim_accounts table with calculated fields
-- This view adds business logic and derived fields for easier consumption by analysts and reports

CREATE OR REPLACE VIEW dim_accounts_view AS
SELECT
  account_id_hashed,
  user_id_hashed,
  account_type,
  created_ts,
  first_closed_ts,
  last_reopened_ts,
  current_status,
  total_closures,
  total_reopenings,
  days_active,
  
  -- Derived fields
  CASE 
    WHEN total_closures = 0 THEN 'NEVER_CLOSED'
    WHEN total_reopenings > 0 THEN 'REOPENED'
    WHEN current_status = 'CLOSED' THEN 'CLOSED'
    ELSE 'ACTIVE'
  END AS account_lifecycle_category,
  
  CASE
    WHEN total_closures > 0 AND total_reopenings > 0 THEN TRUE
    ELSE FALSE
  END AS has_been_reopened,
  
  DATE(created_ts) AS created_date,
  DATE(first_closed_ts) AS first_closed_date,
  DATE(last_reopened_ts) AS last_reopened_date,
  
  -- Age calculations
  DATE_DIFF(CURRENT_DATE(), DATE(created_ts), DAY) AS account_age_days,
  DATE_DIFF(CURRENT_DATE(), DATE(created_ts), MONTH) AS account_age_months,
  DATE_DIFF(CURRENT_DATE(), DATE(created_ts), YEAR) AS account_age_years,
  
  load_timestamp
FROM
  dim_accounts
;
