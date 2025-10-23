    # Monzo Data Warehouse ERD (Entity Relationship Diagram)

    This ERD shows the complete data model for the Monzo data warehouse, including source tables and derived analytics tables.

    ## Mermaid ERD Code (Copy this into Lucidchart)

    ```mermaid
    erDiagram
        %% Source Tables (Raw Data)
        account_created {
            string account_id_hashed PK
            string user_id_hashed
            string account_type
            timestamp created_ts
        }
        
        account_closed {
            string account_id_hashed PK
            timestamp closed_ts
        }
        
        account_reopened {
            string account_id_hashed PK
            timestamp reopened_ts
        }
        
        account_transactions {
            date date PK
            string account_id_hashed PK
            int64 transactions_num
        }
        
        %% Dimension Tables (Analytics Layer)
        dim_accounts {
            string account_id_hashed PK
            string user_id_hashed
            string account_type
            timestamp created_ts
            timestamp first_closed_ts
            timestamp last_reopened_ts
            string current_status
            int64 total_closures
            int64 total_reopenings
            int64 days_active
            int64 total_transactions
            int64 total_transaction_days
            date first_transaction_date
            date last_transaction_date
            float64 avg_daily_transactions
            int64 max_daily_transactions
            int64 transactions_last_7d
            int64 transactions_last_30d
            int64 days_since_last_transaction
            timestamp load_timestamp
        }
        
        dim_account_metrics_daily {
            date metric_date PK
            string account_id_hashed PK
            string user_id_hashed
            string account_type
            string account_status
            int64 days_since_creation
            int64 days_since_last_closure
            int64 days_since_last_reopening
            boolean is_active_7d
            boolean is_active_30d
            int64 cumulative_transactions
            int64 transactions_last_7d
            int64 transactions_last_30d
            timestamp load_timestamp
        }
        
        %% Fact Tables (Analytics Layer)
        fact_account_trans_daily {
            date trans_date PK
            string account_id_hashed PK
            string user_id_hashed
            string account_type
            string account_status
            int64 transactions_num
            int64 transactions_num_7d_rolling
            int64 transactions_num_30d_rolling
            boolean is_first_transaction
            int64 days_since_account_created
            int64 days_since_last_transaction
            timestamp load_timestamp
        }
        
        fact_7d_active_users {
            date metric_date PK
            int64 total_users_with_open_accounts
            int64 active_users_7d
            float64 active_rate_7d
            int64 total_open_accounts
            int64 active_accounts_7d
            float64 active_accounts_rate_7d
            int64 total_transactions_7d
            float64 avg_transactions_per_active_user
            float64 avg_transactions_per_active_account
            timestamp load_timestamp
        }
        
        %% Relationships - Source to Analytics
        account_created ||--o{ dim_accounts : "account_id_hashed"
        account_closed ||--o{ dim_accounts : "account_id_hashed"
        account_reopened ||--o{ dim_accounts : "account_id_hashed"
        account_transactions ||--o{ dim_accounts : "account_id_hashed"
        
        account_created ||--o{ dim_account_metrics_daily : "account_id_hashed"
        account_closed ||--o{ dim_account_metrics_daily : "account_id_hashed"
        account_reopened ||--o{ dim_account_metrics_daily : "account_id_hashed"
        account_transactions ||--o{ dim_account_metrics_daily : "account_id_hashed"
        
        account_created ||--o{ fact_account_trans_daily : "account_id_hashed"
        account_closed ||--o{ fact_account_trans_daily : "account_id_hashed"
        account_reopened ||--o{ fact_account_trans_daily : "account_id_hashed"
        account_transactions ||--|| fact_account_trans_daily : "account_id_hashed, date"
        
        account_created ||--o{ fact_7d_active_users : "aggregated"
        account_closed ||--o{ fact_7d_active_users : "aggregated"
        account_reopened ||--o{ fact_7d_active_users : "aggregated"
        account_transactions ||--o{ fact_7d_active_users : "aggregated"
        
        %% Analytics Relationships
        dim_accounts ||--o{ dim_account_metrics_daily : "account_id_hashed"
        dim_accounts ||--o{ fact_account_trans_daily : "account_id_hashed"
    ```

    ## Table Descriptions

    ### 📊 **Source Tables (Raw Data Layer)**
    - **`account_created`**: Account creation events with user mapping
    - **`account_closed`**: Account closure timestamps
    - **`account_reopened`**: Account reopening events
    - **`account_transactions`**: Daily transaction volumes per account

    ### 🏗️ **Dimension Tables (Analytics Layer)**
    - **`dim_accounts`**: Master account dimension with lifecycle & transaction metrics
    - **`dim_account_metrics_daily`**: Daily snapshots of account metrics for trend analysis

    ### 📈 **Fact Tables (Analytics Layer)**
    - **`fact_account_trans_daily`**: Daily transaction facts with rolling metrics
    - **`fact_7d_active_users`**: Daily KPI metrics for 7-day active users

    ## Key Relationships

    1. **One-to-Many**: Each account can have multiple closure/reopening events
    2. **One-to-Many**: Each account can have multiple daily transaction records
    3. **Many-to-One**: Multiple source records aggregate into dimension/fact tables
    4. **Time-Series**: All analytics tables partitioned by date for performance

    ## Business Keys

    - **Primary Business Key**: `account_id_hashed` (links all account-related data)
    - **Secondary Key**: `user_id_hashed` (enables user-level analytics)
    - **Time Dimension**: `date/metric_date` (enables time-series analysis)

    ## Data Flow

    ```
    Raw Data → ETL Processing → Analytics Tables → Views → BI Dashboards
    ```

    This ERD supports comprehensive customer analytics, transaction monitoring, and business KPI tracking.