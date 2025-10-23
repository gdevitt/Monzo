-- Dimension Table: dim_accounts
-- Purpose: Consolidated view of all accounts with their current status
-- This table maintains the complete lifecycle of each account including creation, closure, and reopening events
-- Updated: Nightly refresh based on source tables

CREATE TABLE dim_accounts
(
  account_id_hashed STRING NOT NULL,
  user_id_hashed STRING NOT NULL,
  account_type STRING,
  created_ts TIMESTAMP NOT NULL,
  first_closed_ts TIMESTAMP,
  last_reopened_ts TIMESTAMP,
  current_status STRING NOT NULL,  -- 'OPEN', 'CLOSED'
  total_closures INT64 DEFAULT 0,
  total_reopenings INT64 DEFAULT 0,
  days_active INT64,  -- Total days account has been active
  load_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  
  -- Primary Key
  PRIMARY KEY (account_id_hashed) NOT ENFORCED
)
COMMENT 'Dimension table containing consolidated account information with lifecycle status';
