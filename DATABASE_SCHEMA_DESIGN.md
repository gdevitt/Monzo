# Monzo Database Schema Design Documentation

## Overview
This document outlines the database schema design for Monzo's data warehouse, implementing a dimensional modeling approach with fact and dimension tables optimized for analytical reporting and dashboard creation.

## Schema Architecture

### Design Principles
1. **Separation of Concerns**: Dimension tables store descriptive attributes, while fact tables store measurable metrics
2. **Historical Consistency**: All tables support point-in-time analysis with load timestamps
3. **Intuitive Design**: Clear naming conventions and comprehensive views for analyst consumption
4. **Scalability**: Partitioned tables for efficient querying and data management
5. **Flexibility**: Schema supports diverse analytical questions without requiring complex joins

## Table Definitions

### Dimension Tables

#### 1. `dim_accounts`
**Purpose**: Master dimension table containing consolidated account information with complete lifecycle status.

**Key Features**:
- Maintains current status of all accounts (OPEN/CLOSED)
- Tracks creation, closure, and reopening events
- Calculates total closures and reopenings per account
- Links accounts to users via `user_id_hashed`

**Use Cases**:
- Account inventory and status reporting
- User account relationship analysis
- Account lifecycle analysis
- Churn and reactivation studies

**Refresh Schedule**: Nightly, fully refreshed from source tables

---

#### 2. `dim_account_metrics_daily`
**Purpose**: Daily snapshot dimension table capturing account-level metrics at specific points in time.

**Key Features**:
- Partitioned by date for efficient querying
- Stores daily snapshots with timestamps for versioning
- Pre-calculated activity flags (7d, 30d)
- Rolling transaction counts
- Days since key lifecycle events

**Use Cases**:
- Historical trend analysis
- Cohort analysis by account creation date
- Account maturity and engagement tracking
- Time-series forecasting

**Refresh Schedule**: Daily incremental load with new metric_date

---

### Fact Tables

#### 3. `fact_account_trans_daily`
**Purpose**: Daily aggregated transaction facts at the account level.

**Key Features**:
- Partitioned by transaction date
- Rolling 7-day and 30-day transaction sums
- First transaction indicators
- Days since last transaction
- Links to account status on transaction date

**Use Cases**:
- Transaction volume analysis
- User engagement metrics
- Transaction velocity tracking
- Cohort transaction behavior analysis

**Refresh Schedule**: Daily, derived from `account_transactions` source table

---

#### 4. `fact_7d_active_users`
**Purpose**: Daily calculation of the 7-day active users KPI metric.

**Key Features**:
- Single row per day with enterprise-level metrics
- Calculates active_rate_7d = (users with transactions in last 7 days) / (users with at least one open account)
- Excludes users with only closed accounts
- Provides both user-level and account-level active rates
- Includes supporting metrics for deeper analysis

**Use Cases**:
- Executive KPI dashboards
- Active user trend monitoring
- User engagement analysis
- Business health indicators

**Refresh Schedule**: Daily

---

## View Definitions

Each table has a corresponding view that adds:
- Derived calculated fields
- Business logic categorizations
- Time-based dimensions (year, month, quarter)
- Segment classifications
- User-friendly formatting

### View Naming Convention
- `{table_name}_view` - e.g., `dim_accounts_view`, `fact_7d_active_users_view`

### View Benefits
1. **Abstraction**: Hides complexity from end users
2. **Consistency**: Ensures consistent business logic across reports
3. **Performance**: Pre-calculated segments reduce query complexity
4. **Flexibility**: Can be modified without changing underlying tables

---

## Data Model Relationships

```
Source Tables (Nightly Refresh)
├── account_created
├── account_closed
├── account_reopened
└── account_transactions

         ↓ ETL Process ↓

Dimension Tables
├── dim_accounts (consolidated account master)
└── dim_account_metrics_daily (daily snapshots)

Fact Tables
├── fact_account_trans_daily (transaction aggregations)
└── fact_7d_active_users (KPI metrics)

         ↓ Views Layer ↓

Analytical Views (for Dashboard Consumption)
├── dim_accounts_view
├── dim_account_metrics_daily_view
├── fact_account_trans_daily_view
└── fact_7d_active_users_view
```

---

## Dashboard Examples

### 1. Executive KPI Dashboard - "7-Day Active Users"

**Data Source**: `fact_7d_active_users_view`

**Key Visualizations**:

#### A. Active Rate Trend (Line Chart)
```sql
-- Looker/Tableau Query Example
SELECT
  metric_date,
  active_rate_7d_pct,
  active_rate_7d_prev_week,
  active_rate_7d_week_change
FROM fact_7d_active_users_view
WHERE metric_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
ORDER BY metric_date;
```
**Visualization**: Line chart showing 90-day trend of active rate with week-over-week change indicators

#### B. Current Performance Scorecard
```sql
SELECT
  active_rate_7d_pct AS "Active Rate %",
  active_users_7d AS "Active Users",
  total_users_with_open_accounts AS "Total Users",
  performance_category AS "Status",
  active_rate_7d_day_change * 100 AS "Daily Change %"
FROM fact_7d_active_users_view
WHERE metric_date = CURRENT_DATE() - 1;
```
**Visualization**: Single value tiles with color coding based on performance_category

#### C. Monthly Active Rate Heatmap
```sql
SELECT
  metric_month,
  metric_day_of_week,
  AVG(active_rate_7d_pct) AS avg_active_rate
FROM fact_7d_active_users_view
WHERE metric_year = EXTRACT(YEAR FROM CURRENT_DATE())
GROUP BY metric_month, metric_day_of_week
ORDER BY metric_month, metric_day_of_week;
```
**Visualization**: Heatmap showing active rates by day of week and month

---

### 2. Account Performance Dashboard - "Transaction Insights"

**Data Source**: `fact_account_trans_daily_view` + `dim_accounts_view`

**Key Visualizations**:

#### A. Transaction Volume by Account Type
```sql
SELECT
  trans_year_month,
  account_type,
  SUM(transactions_num) AS total_transactions,
  COUNT(DISTINCT account_id_hashed) AS active_accounts
FROM fact_account_trans_daily_view
WHERE trans_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH)
GROUP BY trans_year_month, account_type
ORDER BY trans_year_month, account_type;
```
**Visualization**: Stacked bar chart showing monthly transaction volumes by account type

#### B. Transaction Velocity Distribution
```sql
SELECT
  transaction_velocity_7d,
  COUNT(DISTINCT account_id_hashed) AS account_count,
  SUM(transactions_num) AS total_transactions
FROM fact_account_trans_daily_view
WHERE trans_date = CURRENT_DATE() - 1
GROUP BY transaction_velocity_7d
ORDER BY 
  CASE transaction_velocity_7d
    WHEN 'VERY_HIGH' THEN 1
    WHEN 'HIGH' THEN 2
    WHEN 'MEDIUM' THEN 3
    WHEN 'LOW' THEN 4
    ELSE 5
  END;
```
**Visualization**: Pie chart showing distribution of accounts by velocity segment

#### C. Lifecycle Phase Analysis
```sql
SELECT
  lifecycle_phase,
  COUNT(DISTINCT account_id_hashed) AS account_count,
  AVG(transactions_num_7d_rolling) AS avg_transactions_7d
FROM fact_account_trans_daily_view
WHERE trans_date = CURRENT_DATE() - 1
  AND account_status = 'OPEN'
GROUP BY lifecycle_phase
ORDER BY 
  CASE lifecycle_phase
    WHEN 'ACTIVATION' THEN 1
    WHEN 'ONBOARDING' THEN 2
    WHEN 'GROWTH' THEN 3
    ELSE 4
  END;
```
**Visualization**: Bar chart comparing average transaction activity across lifecycle phases

---

### 3. User Engagement Dashboard - "Cohort Analysis"

**Data Source**: `dim_account_metrics_daily_view` + `dim_accounts_view`

**Key Visualizations**:

#### A. Cohort Retention by Activity
```sql
WITH cohorts AS (
  SELECT
    account_id_hashed,
    DATE_TRUNC(DATE(created_ts), MONTH) AS cohort_month
  FROM dim_accounts_view
)
SELECT
  c.cohort_month,
  m.metric_year_month,
  DATE_DIFF(DATE(m.metric_date), DATE(c.cohort_month), MONTH) AS months_since_creation,
  COUNT(DISTINCT m.account_id_hashed) AS active_accounts,
  COUNT(DISTINCT c.account_id_hashed) AS cohort_size,
  COUNT(DISTINCT m.account_id_hashed) / COUNT(DISTINCT c.account_id_hashed) AS retention_rate
FROM cohorts c
JOIN dim_account_metrics_daily_view m
  ON c.account_id_hashed = m.account_id_hashed
WHERE m.is_active_30d = TRUE
  AND c.cohort_month >= '2023-01-01'
GROUP BY c.cohort_month, m.metric_year_month, months_since_creation
ORDER BY c.cohort_month, months_since_creation;
```
**Visualization**: Cohort retention heatmap showing retention rates by cohort and months since creation

#### B. Engagement Score Distribution
```sql
SELECT
  metric_date,
  engagement_score,
  COUNT(DISTINCT account_id_hashed) AS account_count
FROM dim_account_metrics_daily_view
WHERE metric_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
  AND account_status = 'OPEN'
GROUP BY metric_date, engagement_score
ORDER BY metric_date, engagement_score;
```
**Visualization**: Stacked area chart showing evolution of engagement score distribution over time

#### C. Activity Segment Transitions
```sql
SELECT
  curr.activity_segment AS current_segment,
  prev.activity_segment AS previous_segment,
  COUNT(DISTINCT curr.account_id_hashed) AS account_count
FROM dim_account_metrics_daily_view curr
LEFT JOIN dim_account_metrics_daily_view prev
  ON curr.account_id_hashed = prev.account_id_hashed
  AND prev.metric_date = DATE_SUB(curr.metric_date, INTERVAL 30 DAY)
WHERE curr.metric_date = CURRENT_DATE() - 1
  AND curr.account_status = 'OPEN'
GROUP BY current_segment, previous_segment;
```
**Visualization**: Sankey diagram showing flow between activity segments over 30 days

---

### 4. Account Health Dashboard - "Status Monitoring"

**Data Source**: `dim_accounts_view` + `dim_account_metrics_daily_view`

**Key Visualizations**:

#### A. Account Status Summary
```sql
SELECT
  account_lifecycle_category,
  account_type,
  COUNT(*) AS account_count,
  AVG(account_age_days) AS avg_age_days
FROM dim_accounts_view
GROUP BY account_lifecycle_category, account_type
ORDER BY account_lifecycle_category, account_type;
```
**Visualization**: Grouped bar chart showing account counts by lifecycle category and type

#### B. Account Maturity Breakdown
```sql
SELECT
  account_maturity,
  COUNT(DISTINCT account_id_hashed) AS account_count,
  SUM(CASE WHEN is_active_7d THEN 1 ELSE 0 END) AS active_accounts,
  AVG(transactions_last_7d) AS avg_transactions_7d
FROM dim_account_metrics_daily_view
WHERE metric_date = CURRENT_DATE() - 1
  AND account_status = 'OPEN'
GROUP BY account_maturity
ORDER BY 
  CASE account_maturity
    WHEN 'NEW' THEN 1
    WHEN 'GROWING' THEN 2
    WHEN 'ESTABLISHED' THEN 3
    ELSE 4
  END;
```
**Visualization**: Multi-metric table with sparklines for trends

#### C. Churn Risk Identification
```sql
SELECT
  account_id_hashed,
  user_id_hashed,
  account_type,
  days_since_last_closure,
  transactions_last_30d,
  activity_segment,
  engagement_score
FROM dim_account_metrics_daily_view
WHERE metric_date = CURRENT_DATE() - 1
  AND account_status = 'OPEN'
  AND is_active_30d = FALSE
  AND days_since_creation > 90
ORDER BY engagement_score ASC, days_since_creation DESC
LIMIT 100;
```
**Visualization**: Data table with conditional formatting highlighting high-risk accounts

---

## Looker Dashboard Configuration Examples

### Dashboard 1: "7-Day Active Users KPI"

**Looker LookML Explore Definition**:
```lookml
explore: fact_7d_active_users_view {
  label: "7-Day Active Users"
  
  always_filter: {
    filters: [fact_7d_active_users_view.metric_date: "90 days"]
  }
  
  join: dim_accounts_view {
    type: left_outer
    relationship: one_to_many
    sql_on: ${fact_7d_active_users_view.metric_date} = ${dim_accounts_view.created_date} ;;
  }
}
```

**Key Dimensions**:
- `metric_date` (date)
- `metric_year_month` (string)
- `metric_quarter` (string)
- `performance_category` (string)

**Key Measures**:
- `active_rate_7d_pct` (percent, formatted)
- `active_users_7d` (number, formatted with commas)
- `total_users_with_open_accounts` (number)
- `active_rate_7d_week_change` (percent, with up/down indicator)

**Filters**:
- Date Range
- Performance Category
- Minimum Active Rate

**Tiles**:
1. **Scorecard**: Current active rate with day-over-day change
2. **Line Chart**: 90-day trend with target line at 60%
3. **Table**: Weekly summary with key metrics
4. **Area Chart**: Breakdown of active vs inactive users

---

### Dashboard 2: "Transaction Intelligence"

**Key Measures**:
- Total transaction volume
- Average transactions per active account
- Transaction velocity segments
- Weekend vs weekday patterns

**Filters**:
- Date Range
- Account Type
- Transaction Velocity
- Lifecycle Phase

**Tiles**:
1. **Column Chart**: Daily transaction volumes
2. **Pie Chart**: Velocity segment distribution
3. **Heatmap**: Transactions by day of week and hour
4. **Trend Line**: Moving average of transaction counts

---

## Data Quality Tests

### Recommended dbt Tests (if using dbt)

1. **Uniqueness Tests**:
   - `dim_accounts.account_id_hashed` must be unique
   - `dim_account_metrics_daily` combination of `(metric_date, account_id_hashed)` must be unique
   - `fact_7d_active_users.metric_date` must be unique

2. **Referential Integrity Tests**:
   - All `account_id_hashed` in fact tables exist in `dim_accounts`
   - All `user_id_hashed` in dimension tables exist in source `account_created`

3. **Null Tests**:
   - Primary keys should never be null
   - `created_ts` in `dim_accounts` must not be null
   - `transactions_num` in `fact_account_trans_daily` must not be null

4. **Value Range Tests**:
   - `active_rate_7d` should be between 0 and 1
   - `engagement_score` should be between 1 and 5
   - `transactions_num` should be >= 0

5. **Freshness Tests**:
   - All tables should have records within last 24 hours (based on `load_timestamp`)

---

## ETL Loading Logic

### High-Level Load Process

1. **dim_accounts** (Nightly Full Refresh):
```sql
-- Pseudo-code for loading dim_accounts
TRUNCATE TABLE dim_accounts;

INSERT INTO dim_accounts
SELECT
  ac.account_id_hashed,
  ac.user_id_hashed,
  ac.account_type,
  ac.created_ts,
  MIN(acl.closed_ts) AS first_closed_ts,
  MAX(ar.reopened_ts) AS last_reopened_ts,
  CASE
    WHEN MAX(ar.reopened_ts) > MIN(acl.closed_ts) THEN 'OPEN'
    WHEN COUNT(acl.closed_ts) > 0 THEN 'CLOSED'
    ELSE 'OPEN'
  END AS current_status,
  COUNT(DISTINCT acl.closed_ts) AS total_closures,
  COUNT(DISTINCT ar.reopened_ts) AS total_reopenings,
  DATE_DIFF(CURRENT_DATE(), DATE(ac.created_ts), DAY) AS days_active,
  CURRENT_TIMESTAMP() AS load_timestamp
FROM account_created ac
LEFT JOIN account_closed acl ON ac.account_id_hashed = acl.account_id_hashed
LEFT JOIN account_reopened ar ON ac.account_id_hashed = ar.account_id_hashed
GROUP BY 1, 2, 3, 4;
```

2. **dim_account_metrics_daily** (Daily Incremental):
```sql
-- Pseudo-code for loading yesterday's metrics
INSERT INTO dim_account_metrics_daily
SELECT
  CURRENT_DATE() - 1 AS metric_date,
  da.account_id_hashed,
  da.user_id_hashed,
  da.account_type,
  da.current_status AS account_status,
  DATE_DIFF(CURRENT_DATE() - 1, DATE(da.created_ts), DAY) AS days_since_creation,
  -- Calculate 7d and 30d activity flags
  CASE WHEN SUM(t7.transactions_num) > 0 THEN TRUE ELSE FALSE END AS is_active_7d,
  CASE WHEN SUM(t30.transactions_num) > 0 THEN TRUE ELSE FALSE END AS is_active_30d,
  -- Additional metrics...
  CURRENT_TIMESTAMP() AS load_timestamp
FROM dim_accounts da
LEFT JOIN account_transactions t7 
  ON da.account_id_hashed = t7.account_id_hashed
  AND t7.date BETWEEN CURRENT_DATE() - 8 AND CURRENT_DATE() - 1
LEFT JOIN account_transactions t30
  ON da.account_id_hashed = t30.account_id_hashed
  AND t30.date BETWEEN CURRENT_DATE() - 31 AND CURRENT_DATE() - 1
GROUP BY 1, 2, 3, 4, 5, 6;
```

3. **fact_account_trans_daily** (Daily Incremental):
```sql
-- Pseudo-code for loading yesterday's transactions
INSERT INTO fact_account_trans_daily
SELECT
  t.date AS trans_date,
  t.account_id_hashed,
  da.user_id_hashed,
  da.account_type,
  da.current_status AS account_status,
  t.transactions_num,
  SUM(t7.transactions_num) AS transactions_num_7d_rolling,
  SUM(t30.transactions_num) AS transactions_num_30d_rolling,
  -- Additional metrics...
  CURRENT_TIMESTAMP() AS load_timestamp
FROM account_transactions t
JOIN dim_accounts da ON t.account_id_hashed = da.account_id_hashed
LEFT JOIN account_transactions t7 
  ON t.account_id_hashed = t7.account_id_hashed
  AND t7.date BETWEEN t.date - 6 AND t.date
LEFT JOIN account_transactions t30
  ON t.account_id_hashed = t30.account_id_hashed
  AND t30.date BETWEEN t.date - 29 AND t.date
WHERE t.date = CURRENT_DATE() - 1
GROUP BY 1, 2, 3, 4, 5, 6;
```

4. **fact_7d_active_users** (Daily Incremental):
```sql
-- Pseudo-code for calculating yesterday's 7d active users
INSERT INTO fact_7d_active_users
SELECT
  CURRENT_DATE() - 1 AS metric_date,
  COUNT(DISTINCT CASE WHEN da.current_status = 'OPEN' THEN da.user_id_hashed END) AS total_users_with_open_accounts,
  COUNT(DISTINCT CASE WHEN t7.transactions_num > 0 THEN da.user_id_hashed END) AS active_users_7d,
  SAFE_DIVIDE(
    COUNT(DISTINCT CASE WHEN t7.transactions_num > 0 THEN da.user_id_hashed END),
    COUNT(DISTINCT CASE WHEN da.current_status = 'OPEN' THEN da.user_id_hashed END)
  ) AS active_rate_7d,
  -- Additional metrics...
  CURRENT_TIMESTAMP() AS load_timestamp
FROM dim_accounts da
LEFT JOIN (
  SELECT account_id_hashed, SUM(transactions_num) AS transactions_num
  FROM account_transactions
  WHERE date BETWEEN CURRENT_DATE() - 8 AND CURRENT_DATE() - 1
  GROUP BY account_id_hashed
) t7 ON da.account_id_hashed = t7.account_id_hashed;
```

---

## Best Practices for Dashboard Development

1. **Use Views for Reporting**: Always query the `_view` versions for dashboard consumption
2. **Filter Performance**: Add filters on partitioned columns (dates) to improve query performance
3. **Pre-aggregation**: Consider materialized views for frequently accessed aggregations
4. **Incremental Loading**: Load data incrementally to minimize processing time
5. **Data Freshness Indicators**: Include `load_timestamp` in dashboards to show data freshness
6. **Trend Analysis**: Use LAG/LEAD window functions for period-over-period comparisons
7. **Segmentation**: Leverage pre-calculated segments (engagement_score, activity_segment) for consistent analysis
8. **Documentation**: Keep dashboard descriptions updated with metric definitions and calculation logic

---

## Future Enhancements

1. **User Dimension Table**: Create `dim_users` to store user-level attributes and demographics
2. **Date Dimension**: Add `dim_date` table with calendar attributes, holidays, business days
3. **Account Type Dimension**: Expand account_type into a full dimension with attributes
4. **Transaction Details**: Add `fact_transactions` for transaction-level analysis (if needed)
5. **Aggregation Tables**: Create monthly/quarterly aggregation tables for long-term trend analysis
6. **Real-time Metrics**: Consider streaming updates for near real-time dashboards
7. **ML Features**: Add tables for model predictions (churn probability, lifetime value)

---

## Maintenance and Monitoring

1. **Monitor Load Times**: Track ETL execution times and optimize slow queries
2. **Data Volume Growth**: Monitor partition sizes and implement archival strategy
3. **Query Performance**: Review slow dashboard queries and add indexes if needed
4. **Schema Evolution**: Use database migrations for schema changes
5. **Documentation Updates**: Keep this document synchronized with schema changes

---

## Conclusion

This schema design provides a robust, scalable foundation for Monzo's analytical needs. The dimensional model enables:
- Fast, intuitive querying for analysts
- Flexible dashboard creation in Looker or similar BI tools
- Historical consistency for trend analysis
- Clear separation between raw data, transformed data, and analytical views

The design follows industry best practices for data warehousing and is optimized for the specific use cases outlined in the project requirements.
