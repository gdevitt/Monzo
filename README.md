# Monzo Database Schema Design

A comprehensive dimensional data warehouse schema for Monzo's account and transaction data, designed for analytical reporting and business intelligence dashboards.

## 📋 Quick Start

1. **Read the documentation**: Start with [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) for an overview
2. **Review the schema**: See [DATABASE_SCHEMA_DESIGN.md](DATABASE_SCHEMA_DESIGN.md) for complete specifications
3. **Visualize dashboards**: Check [DASHBOARD_EXAMPLES.md](DASHBOARD_EXAMPLES.md) for dashboard mockups
4. **Execute SQL files**: Run the DDL files in [sql/tables/](sql/tables/) then [sql/views/](sql/views/)

## 📁 Repository Structure

```
Monzo/
├── README.md                           ← You are here
├── DATABASE_SCHEMA_DESIGN.md           ← Comprehensive schema documentation (20KB)
├── DASHBOARD_EXAMPLES.md               ← Visual dashboard examples (22KB)
├── IMPLEMENTATION_SUMMARY.md           ← Quick reference guide (10KB)
├── Project Outline.md                  ← Original requirements
│
└── sql/
    ├── README.md                       ← SQL files guide
    │
    ├── tables/                         ← Table DDL files
    │   ├── dim_accounts.sql
    │   ├── dim_account_metrics_daily.sql
    │   ├── fact_account_trans_daily.sql
    │   └── fact_7d_active_users.sql
    │
    └── views/                          ← View DDL files
        ├── dim_accounts_view.sql
        ├── dim_account_metrics_daily_view.sql
        ├── fact_account_trans_daily_view.sql
        └── fact_7d_active_users_view.sql
```

## 🎯 What's Included

### Database Schema (8 SQL Files)

#### Dimension Tables
- **dim_accounts**: Consolidated account lifecycle tracking with current status
- **dim_account_metrics_daily**: Daily account metrics snapshots for historical analysis

#### Fact Tables
- **fact_account_trans_daily**: Aggregated daily transaction metrics with rolling calculations
- **fact_7d_active_users**: Daily 7-day active user KPI metric calculation

#### Analytical Views
Each table has a corresponding view that adds:
- Calculated fields and business logic
- Segmentation and categorization  
- Time-based dimensions (year, month, quarter)
- Trend indicators and comparisons

### Documentation (3 Files)

#### 1. DATABASE_SCHEMA_DESIGN.md (636 lines)
The comprehensive guide covering:
- Schema architecture and design principles
- Detailed table and view specifications
- Data model relationships
- **4 complete dashboard designs** with SQL queries:
  - Executive KPI Dashboard - "7-Day Active Users"
  - Account Performance Dashboard - "Transaction Insights"
  - User Engagement Dashboard - "Cohort Analysis"
  - Account Health Dashboard - "Status Monitoring"
- Looker/Tableau configuration examples
- ETL loading logic and patterns
- Data quality test specifications
- Best practices for dashboard development

#### 2. DASHBOARD_EXAMPLES.md (350 lines)
Visual ASCII mockups showing:
- 4 complete dashboard layouts
- Example visualizations (charts, tables, scorecards)
- Color coding and formatting standards
- Query performance tips
- Implementation notes for Looker, Tableau, and Power BI

#### 3. IMPLEMENTATION_SUMMARY.md (266 lines)
Quick reference including:
- File structure overview
- Key deliverables summary
- Getting started guide
- Example Looker dashboard output
- Next steps for implementation

## 🚀 Key Features

✅ **Dimensional Modeling**: Star schema with fact and dimension tables  
✅ **Historical Tracking**: Daily snapshots with load timestamps  
✅ **Optimized Performance**: Partitioned tables, pre-aggregated metrics  
✅ **Analytical Flexibility**: Time dimensions, segments, cohort support  
✅ **7-Day Active Users KPI**: Dedicated fact table for the key metric  
✅ **Dashboard Ready**: 4 complete dashboard designs with SQL  
✅ **Well Documented**: 1,300+ lines of comprehensive documentation  
✅ **Production Ready**: Includes ETL patterns and data quality tests

## 📊 Dashboard Examples

### 1. Executive KPI Dashboard
Monitors the 7-day active users metric with trend analysis, scorecards, and performance indicators.

**Key Metrics**: Active rate %, active users, total users, day/week changes

### 2. Transaction Intelligence Dashboard  
Tracks transaction volumes, velocity segments, and lifecycle phase analysis.

**Key Metrics**: Daily volume, 7-day volume, transactions per account

### 3. User Engagement Dashboard
Analyzes user retention through cohort analysis and engagement scoring.

**Key Metrics**: Cohort retention rates, engagement scores, activity segments

### 4. Account Health Dashboard
Monitors account status distribution and identifies churn risk.

**Key Metrics**: Total accounts, open/closed breakdown, lifecycle categories

## 🔧 Technology Stack

**Database**: Google BigQuery (syntax used)
- Easily adaptable for PostgreSQL, MySQL, Snowflake
- See [sql/README.md](sql/README.md) for adaptation notes

**Compatible BI Tools**:
- Looker (LookML examples provided)
- Tableau
- Power BI
- Mode Analytics
- Any SQL-based BI tool

## 📖 Usage

### Creating the Schema

```bash
# 1. Create tables (execute in order)
bq query < sql/tables/dim_accounts.sql
bq query < sql/tables/dim_account_metrics_daily.sql
bq query < sql/tables/fact_account_trans_daily.sql
bq query < sql/tables/fact_7d_active_users.sql

# 2. Create views (any order)
bq query < sql/views/dim_accounts_view.sql
bq query < sql/views/dim_account_metrics_daily_view.sql
bq query < sql/views/fact_account_trans_daily_view.sql
bq query < sql/views/fact_7d_active_users_view.sql
```

### Querying the Data

```sql
-- Example: Get yesterday's 7-day active user rate
SELECT
  metric_date,
  active_rate_7d_pct,
  active_users_7d,
  total_users_with_open_accounts,
  performance_category
FROM fact_7d_active_users_view
WHERE metric_date = CURRENT_DATE() - 1;

-- Example: Analyze transaction velocity distribution
SELECT
  transaction_velocity_7d,
  COUNT(DISTINCT account_id_hashed) AS account_count,
  SUM(transactions_num) AS total_transactions
FROM fact_account_trans_daily_view
WHERE trans_date = CURRENT_DATE() - 1
GROUP BY transaction_velocity_7d;
```

## 📚 Documentation Guide

| Document | Purpose | Read When... |
|----------|---------|--------------|
| **README.md** (this file) | Overview and quick start | Starting the project |
| **IMPLEMENTATION_SUMMARY.md** | Executive summary | Need quick reference |
| **DATABASE_SCHEMA_DESIGN.md** | Complete specifications | Implementing the schema |
| **DASHBOARD_EXAMPLES.md** | Visual mockups | Building dashboards |
| **sql/README.md** | SQL files guide | Executing DDL files |

## 🎯 Requirements Fulfilled

✓ Design fact and dimension tables  
✓ Provide separate SQL files for table DDL  
✓ Provide separate SQL files for view DDL  
✓ Each table has corresponding view  
✓ Timestamped daily snapshots for historical analysis  
✓ Example dashboard designs with SQL queries  
✓ Looker dashboard configuration examples  
✓ Report generation examples  

## 🔍 Design Highlights

### Dimensional Modeling
- **Star Schema**: Fact tables connect to dimension tables via foreign keys
- **Type 2 SCD**: Daily snapshots enable historical point-in-time analysis
- **Grain Definition**: Clear grain for each table (account-level or enterprise-level)

### Performance Optimization
- **Partitioning**: All fact tables partitioned by date for query efficiency
- **Pre-aggregation**: Rolling metrics calculated during load, not at query time
- **Indexed Views**: Views optimized for common analytical queries

### Analytical Flexibility
- **Time Dimensions**: Year, month, quarter, day of week for temporal analysis
- **Segmentation**: Pre-calculated segments ensure consistent analysis
- **Cohort Support**: Creation date tracking enables cohort analysis
- **Trend Analysis**: LAG/LEAD window functions for period comparisons

## 🧪 Data Quality

The documentation includes specifications for:
- **Uniqueness tests**: Primary key validation
- **Referential integrity tests**: Foreign key relationships
- **Null tests**: Required field validation
- **Value range tests**: Business rule validation
- **Freshness tests**: Data recency checks

## 🚦 Next Steps

1. ✅ Review documentation (you're doing it!)
2. ⏭️ Execute table DDL files
3. ⏭️ Execute view DDL files
4. ⏭️ Implement ETL processes (patterns in documentation)
5. ⏭️ Create dashboards (examples provided)
6. ⏭️ Implement data quality tests

## 📞 Support

For detailed information:
- **Schema Design**: See [DATABASE_SCHEMA_DESIGN.md](DATABASE_SCHEMA_DESIGN.md)
- **Dashboard Examples**: See [DASHBOARD_EXAMPLES.md](DASHBOARD_EXAMPLES.md)
- **SQL Files**: See [sql/README.md](sql/README.md)

## 📄 License

This schema design is provided for Monzo's use. All rights reserved.

---

**Schema Version**: 1.0  
**Last Updated**: 2024-10-23  
**Database**: Google BigQuery  
**Status**: ✅ Ready for Implementation
