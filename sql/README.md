# Monzo SQL Schema Files

This directory contains the SQL DDL (Data Definition Language) statements for creating the Monzo data warehouse tables and views.

## Directory Structure

```
sql/
├── tables/          # Table DDL definitions
│   ├── dim_accounts.sql
│   ├── dim_account_metrics_daily.sql
│   ├── fact_account_trans_daily.sql
│   └── fact_7d_active_users.sql
│
└── views/           # View definitions
    ├── dim_accounts_view.sql
    ├── dim_account_metrics_daily_view.sql
    ├── fact_account_trans_daily_view.sql
    └── fact_7d_active_users_view.sql
```

## Table Overview

### Dimension Tables (tables/)

1. **dim_accounts.sql**
   - Master dimension table for all accounts
   - Tracks account lifecycle (created, closed, reopened)
   - Contains current status and user relationships

2. **dim_account_metrics_daily.sql**
   - Daily snapshot of account-level metrics
   - Enables historical trend analysis
   - Pre-calculated activity flags and rolling metrics

### Fact Tables (tables/)

3. **fact_account_trans_daily.sql**
   - Daily aggregated transaction metrics
   - Rolling 7-day and 30-day transaction counts
   - Transaction velocity and recency metrics

4. **fact_7d_active_users.sql**
   - Daily calculation of 7-day active user KPI
   - Enterprise-level metrics for executive reporting
   - Historical consistency for trend analysis

## View Overview

Each table has a corresponding view that adds:
- Derived calculated fields
- Business logic categorizations
- Time-based dimensions (year, month, quarter)
- Segment classifications
- User-friendly formatting

### Views (views/)

1. **dim_accounts_view.sql**
   - Enhanced account dimension with lifecycle categories
   - Account age calculations
   - Reopening flags and status indicators

2. **dim_account_metrics_daily_view.sql**
   - Activity segments and transaction intensity
   - Account maturity classifications
   - Engagement scoring
   - Time-based attributes for reporting

3. **fact_account_trans_daily_view.sql**
   - Transaction velocity segments
   - Lifecycle phase categorization
   - Recency segments
   - Weekend/weekday flags

4. **fact_7d_active_users_view.sql**
   - Percentage-formatted metrics
   - Performance categories
   - Trend indicators (day-over-day, week-over-week)
   - User and account ratios

## Execution Order

When creating the schema from scratch, execute files in this order:

1. **Create Tables First**:
   ```sql
   -- Execute all files in tables/ directory
   source tables/dim_accounts.sql
   source tables/dim_account_metrics_daily.sql
   source tables/fact_account_trans_daily.sql
   source tables/fact_7d_active_users.sql
   ```

2. **Create Views Second**:
   ```sql
   -- Execute all files in views/ directory
   source views/dim_accounts_view.sql
   source views/dim_account_metrics_daily_view.sql
   source views/fact_account_trans_daily_view.sql
   source views/fact_7d_active_users_view.sql
   ```

## Database Compatibility

These SQL files are written for **Google BigQuery** syntax, featuring:
- `STRING` and `INT64` data types
- `TIMESTAMP` with `CURRENT_TIMESTAMP()` function
- `PARTITION BY DATE()` for table partitioning
- `PRIMARY KEY ... NOT ENFORCED` constraints
- `CREATE OR REPLACE VIEW` statements

**For other databases (PostgreSQL, MySQL, Snowflake, etc.)**, you may need to adjust:
- Data type names (STRING → VARCHAR, INT64 → BIGINT)
- Timestamp functions
- Partitioning syntax
- Primary key enforcement

## Usage in BI Tools

For dashboard development in Looker, Tableau, Power BI, or other BI tools:

1. **Always use the views** (not the base tables) as data sources
2. The views provide analyst-friendly field names and pre-calculated metrics
3. Filter on date columns for optimal performance (tables are partitioned by date)
4. Refer to `DATABASE_SCHEMA_DESIGN.md` for detailed dashboard examples

## Data Loading

These DDL files only create the table structures. For ETL/data loading logic, refer to:
- `DATABASE_SCHEMA_DESIGN.md` - Section "ETL Loading Logic"
- Your ETL tool documentation (dbt, Airflow, etc.)

## Testing

Recommended data quality tests:
- Uniqueness of primary keys
- Non-null checks on required fields
- Referential integrity between tables
- Value range validations
- Data freshness checks (load_timestamp)

See `DATABASE_SCHEMA_DESIGN.md` for detailed test specifications.

## Support

For detailed documentation including:
- Schema design rationale
- Dashboard examples with sample queries
- Looker configuration examples
- Data quality tests
- ETL loading patterns

Refer to: **`DATABASE_SCHEMA_DESIGN.md`** in the root directory.
