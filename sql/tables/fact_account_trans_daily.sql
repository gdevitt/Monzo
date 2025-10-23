-- Fact Table: fact_account_trans_daily
-- Purpose: Daily aggregated transaction metrics at account level
-- This table is derived from account_transactions and provides aggregated daily transaction data
-- Updated: Nightly based on source transaction data

CREATE TABLE fact_account_trans_daily
(
  trans_date DATE NOT NULL,
  account_id_hashed STRING NOT NULL,
  user_id_hashed STRING NOT NULL,
  account_type STRING,
  account_status STRING NOT NULL,  -- Status on trans_date
  transactions_num INT64 NOT NULL DEFAULT 0,
  transactions_num_7d_rolling INT64,  -- Rolling 7-day sum including trans_date
  transactions_num_30d_rolling INT64,  -- Rolling 30-day sum including trans_date
  is_first_transaction BOOLEAN,  -- Is this the first transaction day for this account
  days_since_account_created INT64,
  days_since_last_transaction INT64,
  load_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  
  -- Composite Primary Key
  PRIMARY KEY (trans_date, account_id_hashed) NOT ENFORCED
)
PARTITION BY DATE(trans_date)
COMMENT 'Daily aggregated transaction facts at account level with rolling metrics';
