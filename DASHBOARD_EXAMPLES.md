# Monzo Dashboard Examples - Visual Guide

This document provides ASCII visualizations of how the Monzo dashboards would look when implemented in tools like Looker, Tableau, or Power BI.

---

## Dashboard 1: Executive KPI - "7-Day Active Users"

**Purpose**: High-level monitoring of user engagement for executives
**Data Source**: `fact_7d_active_users_view`
**Refresh**: Daily

```
╔══════════════════════════════════════════════════════════════════════════════╗
║                    MONZO - 7-DAY ACTIVE USERS DASHBOARD                      ║
║                         Last Updated: 2024-10-22 08:00 UTC                   ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║  ┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐   ║
║  │   ACTIVE RATE       │  │   ACTIVE USERS      │  │   STATUS            │   ║
║  │                     │  │                     │  │                     │   ║
║  │      62.4%          │  │      47,829         │  │       GOOD          │   ║
║  │                     │  │                     │  │                     │   ║
║  │   ▲ +1.2% (day)     │  │   76,632 total      │  │   ▲ +1.2% today     │   ║
║  │   ▲ +3.5% (week)    │  │   62.5% of users    │  │   ▲ +3.5% week      │   ║
║  └─────────────────────┘  └─────────────────────┘  └─────────────────────┘   ║
║                                                                              ║
║  ┌─────────────────────────────────────────────────────────────────────────┐ ║
║  │  ACTIVE RATE TREND - LAST 90 DAYS                                       │ ║
║  │                                                                         │ ║
║  │  65% ┤                                   ╭─────╮                        │ ║
║  │  63% ┤                          ╭────────╯     ╰──╮                     │ ║
║  │  61% ┤                 ╭────────╯                 ╰─                    │ ║
║  │  59% ┤        ╭────────╯                                                │ ║
║  │  57% ┤  ╭─────╯                                                         │ ║
║  │  55% ┤──╯                                                               │ ║
║  │      └────┬────┬────┬────┬────┬────┬────┬────┬────┬────┬                │ ║
║  │         Jul   Aug   Sep   Oct                                           │ ║
║  │                                                                         │ ║
║  │  Target: 60% ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━       │ ║
║  └─────────────────────────────────────────────────────────────────────────┘ ║
║                                                                              ║
║  ┌─────────────────────────────────────────────────────────────────────────┐ ║
║  │  WEEKLY SUMMARY                                                         │ ║
║  ├──────────────┬──────────────┬──────────────┬──────────────┬─────────────┤ ║
║  │  Week Ending │  Active Rate │ Active Users │ Total Users  │  WoW Change │ ║
║  ├──────────────┼──────────────┼──────────────┼──────────────┼─────────────┤ ║
║  │  Oct 20      │    62.4%  🟢 │    47,829    │    76,632    │   ▲ +1.2%  │ ║
║  │  Oct 13      │    61.7%  🟢 │    47,250    │    76,584    │   ▲ +0.8%  │ ║
║  │  Oct 6       │    61.2%  🟢 │    46,892    │    76,622    │   ▼ -0.3%  │ ║
║  │  Sep 29      │    61.4%  🟢 │    46,723    │    76,102    │   ▲ +2.1%  │ ║
║  │  Sep 22      │    60.2%  🟢 │    45,892    │    76,218    │   ▲ +1.5%  │ ║
║  └──────────────┴──────────────┴──────────────┴──────────────┴─────────────┘ ║
║                                                                              ║
║  ┌────────────────────────┐  ┌────────────────────────────────────────────┐  ║
║  │  BREAKDOWN             │  │  DAILY PATTERN                             │  ║
║  │                        │  │                                            │  ║
║  │  Active Users: 47,829  │  │  Mon ██████████████ 63.2%                  │  ║
║  │  ███████████████ 62.4% │  │  Tue ████████████████ 65.1%                │  ║
║  │                        │  │  Wed ████████████████ 64.8%                │  ║
║  │  Inactive: 28,803      │  │  Thu █████████████ 62.9%                   │  ║
║  │  ██████████  37.6%     │  │  Fri ████████████ 61.2%                    │  ║
║  │                        │  │  Sat ██████████ 58.7%                      │  ║
║  │                        │  │  Sun █████████ 57.3%                       │  ║
║  └────────────────────────┘  └────────────────────────────────────────────┘  ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

### Key Features:
- **Real-time KPIs**: Active rate, user counts, and status indicators
- **Trend Visualization**: 90-day line chart with target line
- **Weekly Summary**: Tabular view with week-over-week changes
- **Breakdowns**: Pie chart and daily pattern analysis
- **Color Coding**: Green (>60%), Yellow (50-60%), Red (<50%)

---

## Dashboard 2: Transaction Intelligence

**Purpose**: Monitor transaction volumes and patterns
**Data Source**: `fact_account_trans_daily_view`, `dim_accounts_view`
**Refresh**: Daily

```
╔═══════════════════════════════════════════════════════════════════════════════╗
║                    MONZO - TRANSACTION INTELLIGENCE                           ║
║                         Last Updated: 2024-10-22 08:00 UTC                    ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║  ┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐               ║
║  │  DAILY VOLUME    │ │  7-DAY VOLUME    │ │  AVG PER ACCOUNT │               ║
║  │                  │ │                  │ │                  │               ║
║  │    342,567       │ │   2,398,219      │ │       4.8        │               ║
║  │   ▲ +2.3%        │ │   ▲ +5.1%        │ │   ▲ +0.3         │               ║
║  └──────────────────┘ └──────────────────┘ └──────────────────┘               ║
║                                                                               ║
║  ┌──────────────────────────────────────────────────────────────────────────┐ ║
║  │  MONTHLY TRANSACTION VOLUME BY ACCOUNT TYPE                              │ ║
║  │                                                                          │ ║
║  │  400K ┤  ████████                                                        │ ║
║  │  350K ┤  ████████  ████████                                              │ ║
║  │  300K ┤  ████████  ████████  ████████                                    │ ║
║  │  250K ┤  ████████  ████████  ████████  ████████                          │ ║
║  │  200K ┤  ████████  ████████  ████████  ████████  ████████                │ ║
║  │  150K ┤  ████████  ████████  ████████  ████████  ████████  ████████      │ ║
║  │  100K ┤  ████████  ████████  ████████  ████████  ████████  ████████      │ ║
║  │   50K ┤  ████████  ████████  ████████  ████████  ████████  ████████      │ ║
║  │       └─────┬────────┬────────┬────────┬────────┬────────┬──────         │ ║
║  │           May      Jun      Jul      Aug      Sep      Oct               │ ║
║  │                                                                          │ ║
║  │  Legend: ▓▓▓ Current  ▒▒▒ Savings  ░░░ Business                          │ ║
║  └──────────────────────────────────────────────────────────────────────────┘ ║
║                                                                               ║
║  ┌──────────────────────────────────────┐ ┌────────────────────────────────┐  ║
║  │  TRANSACTION VELOCITY DISTRIBUTION   │ │  LIFECYCLE PHASE BREAKDOWN     │  ║
║  │                                      │ │                                │  ║
║  │         VERY HIGH                    │ │  ACTIVATION      ███ 8.2%      │  ║
║  │           12.3%                      │ │  ONBOARDING    █████ 15.4%     │  ║
║  │      ╱────────────╲                 │ │  GROWTH    ███████████ 31.8%    │  ║
║  │   LOW╱   HIGH      ╲NONE            │ │  MATURE   ██████████████44.6%   │  ║
║  │  18.9%  42.1%     26.7%             │ │                                 │  ║
║  │     ╲             ╱                  │ │  Avg Transactions (7d):        │  ║
║  │      ╲───────────╱                   │ │  • Activation:   1.2           │  ║
║  │        MEDIUM                        │ │  • Onboarding:   3.8           │  ║
║  │                                      │ │  • Growth:       6.4           │  ║
║  │                                      │ │  • Mature:       5.1           │  ║
║  └──────────────────────────────────────┘ └────────────────────────────────┘  ║
║                                                                               ║
║  ┌──────────────────────────────────────────────────────────────────────────┐ ║
║  │  TOP PERFORMING SEGMENTS                                                 │ ║
║  ├──────────────────┬─────────────┬──────────────┬──────────────────────────┤ ║
║  │  Segment         │  Accounts   │  Transactions│  Avg per Account         │ ║
║  ├──────────────────┼─────────────┼──────────────┼──────────────────────────┤ ║
║  │  HIGH Velocity   │    18,234   │    234,567   │    12.9                  │ ║
║  │  Growth Phase    │    32,891   │    210,502   │     6.4                  │ ║
║  │  Mature Current  │    25,671   │    189,234   │     7.4                  │ ║
║  └──────────────────┴─────────────┴──────────────┴──────────────────────────┘ ║
╚═══════════════════════════════════════════════════════════════════════════════╝
```

### Key Features:
- **Volume Metrics**: Daily and weekly transaction counts
- **Time-series Analysis**: Stacked bar chart by account type
- **Segmentation**: Velocity and lifecycle phase distributions
- **Top Performers**: Table showing high-performing segments

---

## Dashboard 3: User Engagement & Cohorts

**Purpose**: Analyze user retention and engagement patterns
**Data Source**: `dim_account_metrics_daily_view`, `dim_accounts_view`
**Refresh**: Daily

```
╔════════════════════════════════════════════════════════════════════════════════╗
║                    MONZO - USER ENGAGEMENT & COHORTS                           ║
║                         Last Updated: 2024-10-22 08:00 UTC                     ║
╠════════════════════════════════════════════════════════════════════════════════╣
║                                                                                ║
║  ┌──────────────────────────────────────────────────────────────────────────┐  ║
║  │  COHORT RETENTION HEATMAP (by Account Creation Month)                    │  ║
║  │                                                                          │  ║
║  │  Cohort   │  M0   │  M1   │  M2   │  M3   │  M6   │  M12  │              │  ║
║  │  ─────────┼───────┼───────┼───────┼───────┼───────┼───────┤              │  ║
║  │  Jan 2024 │  100% │  87%  │  78%  │  72%  │  65%  │   -   │              │  ║
║  │           │  ████ │  ███▓ │  ███░ │  ███  │  ██▓  │       │              │  ║
║  │  ─────────┼───────┼───────┼───────┼───────┼───────┼───────┤              │  ║
║  │  Feb 2024 │  100% │  89%  │  81%  │  74%  │  68%  │   -   │              │  ║
║  │           │  ████ │  ███▓ │  ███░ │  ███  │  ██▓  │       │              │  ║
║  │  ─────────┼───────┼───────┼───────┼───────┼───────┼───────┤              │  ║
║  │  Mar 2024 │  100% │  91%  │  83%  │  77%  │  71%  │   -   │              │  ║
║  │           │  ████ │  ████ │  ███▓ │  ███░ │  ███  │       │              │  ║
║  │  ─────────┼───────┼───────┼───────┼───────┼───────┼───────┤              │  ║
║  │  Apr 2024 │  100% │  92%  │  85%  │  79%  │  73%  │   -   │              │  ║
║  │           │  ████ │  ████ │  ███▓ │  ███░ │  ███  │       │              │  ║
║  │                                                                          │  ║
║  │  Color Scale: ████ 90-100%  ███▓ 80-90%  ███░ 70-80%  ███ 60-70%         │  ║
║  └──────────────────────────────────────────────────────────────────────────┘  ║
║                                                                                ║
║  ┌──────────────────────────────────────┐ ┌────────────────────────────────┐   ║
║  │  ENGAGEMENT SCORE DISTRIBUTION       │ │  ACTIVITY SEGMENT EVOLUTION    │   ║
║  │                                      │ │                                │   ║
║  │  Score 5 (Highest) ████████ 22.3%   │ │  100%┤                          │   ║
║  │  Score 4         ██████████ 28.7%   │ │   90%┤  ▓▓▓▓▓▓▓▓▓▓▓▓            │   ║
║  │  Score 3       ███████████ 31.2%    │ │   80%┤  ▓▓▓▓▓▓▓▓▓▓▓▓            │   ║
║  │  Score 2      ███████ 12.5%         │ │   70%┤  ▓▓▓▓▓▓▓▓▓▓▓▓            │   ║
║  │  Score 1      ███ 5.3%              │ │   60%┤  ▒▒▒▒▒▒▒▒▒▒▒▒            │   ║
║  │                                      │ │   50%┤  ▒▒▒▒▒▒▒▒▒▒▒▒           │   ║
║  │  Avg: 3.8 (Good)                    │ │   40%┤  ▒▒▒▒▒▒▒▒▒▒▒▒            │   ║
║  │                                      │ │   30%┤  ░░░░░░░░░░░░           │   ║
║  │  Trend: ▲ +0.2 vs last month        │ │   20%┤  ░░░░░░░░░░░░            │   ║
║  │                                      │ │   10%┤  ░░░░░░░░░░░░           │   ║
║  │                                      │ │      └───┬────┬────┬──         │   ║
║  │                                      │ │        Aug   Sep   Oct         │   ║
║  │                                      │ │                                │   ║
║  │                                      │ │  ▓▓▓ ACTIVE_7D                 │   ║
║  │                                      │ │  ▒▒▒ ACTIVE_30D                │   ║
║  │                                      │ │  ░░░ INACTIVE                  │   ║
║  └──────────────────────────────────────┘ └────────────────────────────────┘   ║
║                                                                                ║
║  ┌─────────────────────────────────────────────────────────────────────────┐   ║
║  │  ACCOUNT MATURITY ANALYSIS                                              │   ║
║  ├────────────────┬──────────────┬──────────────┬──────────────────────────┤   ║
║  │  Maturity      │  Total Accts │  Active (7d) │  Avg Transactions        │   ║
║  ├────────────────┼──────────────┼──────────────┼──────────────────────────┤   ║
║  │  NEW           │     8,234    │    6,892     │    2.3                   │   ║
║  │  GROWING       │    15,671    │   12,234     │    4.8                   │   ║
║  │  ESTABLISHED   │    28,891    │   19,567     │    6.2                   │   ║
║  │  MATURE        │    42,387    │   28,903     │    5.8                   │   ║
║  └────────────────┴──────────────┴──────────────┴──────────────────────────┘   ║
╚════════════════════════════════════════════════════════════════════════════════╝
```

### Key Features:
- **Cohort Retention**: Month-over-month retention heatmap
- **Engagement Scoring**: Distribution of engagement scores 1-5
- **Segment Evolution**: Stacked area chart showing activity changes
- **Maturity Analysis**: Account performance by age

---

## Dashboard 4: Account Health Monitor

**Purpose**: Monitor account status and identify churn risks
**Data Source**: `dim_accounts_view`, `dim_account_metrics_daily_view`
**Refresh**: Daily

```
╔════════════════════════════════════════════════════════════════════════════════╗
║                    MONZO - ACCOUNT HEALTH MONITOR                              ║
║                         Last Updated: 2024-10-22 08:00 UTC                     ║
╠════════════════════════════════════════════════════════════════════════════════╣
║                                                                                ║
║  ┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐                ║
║  │  TOTAL ACCOUNTS  │ │  OPEN ACCOUNTS   │ │  CLOSED ACCOUNTS │                ║
║  │                  │ │                  │ │                  │                ║
║  │     95,183       │ │     89,234       │ │      5,949       │                ║
║  │   ▲ +234 (day)   │ │   ▲ +198 (day)   │ │   ▲ +36 (day)    │                ║
║  └──────────────────┘ └──────────────────┘ └──────────────────┘                ║
║                                                                                ║
║  ┌──────────────────────────────────────────────────────────────────────────┐  ║
║  │  ACCOUNT LIFECYCLE DISTRIBUTION                                          │  ║
║  │                                                                          │  ║
║  │  NEVER_CLOSED    ████████████████████████████ 67.8%  (60,492 accounts)   │  ║
║  │  ACTIVE          ████████████ 23.5%  (20,987 accounts)                   │  ║
║  │  REOPENED        ████ 6.3%  (5,623 accounts)                             │  ║
║  │  CLOSED          ██ 2.4%  (2,081 accounts)                               │  ║
║  └──────────────────────────────────────────────────────────────────────────┘  ║
║                                                                                ║
║  ┌──────────────────────────────────────────────────────────────────────────┐  ║
║  │  ACCOUNT STATUS BY TYPE                                                  │  ║
║  │                                                                          │  ║
║  │              │  CURRENT        │  SAVINGS        │  BUSINESS             │  ║
║  │  ────────────┼─────────────────┼─────────────────┼──────────────────     │  ║
║  │  OPEN        │  ████████ 58K   │  ████ 22K       │  ██ 9K                │  ║
║  │  CLOSED      │  ██ 3K          │  █ 2K           │  █ 1K                 │  ║
║  │              │                 │                 │                       │  ║
║  │  Open Rate   │  95.1%          │  91.7%          │  90.0%                │  ║
║  └──────────────────────────────────────────────────────────────────────────┘  ║
║                                                                                ║
║  ┌──────────────────────────────────────────────────────────────────────────┐  ║
║  │  HIGH RISK ACCOUNTS (Churn Risk Scoring)                                 │  ║
║  ├──────────┬────────────┬───────────────┬────────────┬─────────────────────┤  ║
║  │  Acct ID │  User ID   │  Days No Txn  │  Engage    │  Risk Level         │  ║
║  ├──────────┼────────────┼───────────────┼────────────┼─────────────────────┤  ║
║  │  ...a8f2 │  ...b3e4   │      67       │     1      │  🔴 CRITICAL        │  ║
║  │  ...c1d9 │  ...f7a2   │      58       │     2      │  🔴 CRITICAL        │  ║
║  │  ...e4b7 │  ...d9c3   │      45       │     1      │  🟠 HIGH            │  ║
║  │  ...g8h3 │  ...k2m8   │      42       │     2      │  🟠 HIGH            │  ║
║  │  ...j5n1 │  ...p4q7   │      38       │     2      │  🟠 HIGH            │  ║
║  │  ...r6s9 │  ...t1u8   │      35       │     3      │  🟡 MEDIUM          │  ║
║  │  ...v2w4 │  ...x7y3   │      31       │     2      │  🟡 MEDIUM          │  ║
║  └──────────┴────────────┴───────────────┴────────────┴─────────────────────┘  ║
║                                                                                ║
║  ┌────────────────────────────────────────┐ ┌────────────────────────────────┐ ║
║  │  REOPENING SUCCESS RATE                │ │  AVERAGE ACCOUNT AGE           │ ║
║  │                                        │ │                                │ ║
║  │  Total Reopenings: 5,623               │ │  All Accounts:  287 days       │ ║
║  │  Currently Open:   4,892 (87%)         │ │  Open Only:     312 days       │ ║
║  │  Re-closed:          731 (13%)         │ │  Closed Only:   142 days       │ ║
║  │                                        │ │                                │ ║
║  │  Trend: Improving ▲                    │ │  By Type:                      │ ║
║  │                                        │ │  • Current:     298 days       │ ║
║  │  Last Quarter: 85%                     │ │  • Savings:     245 days       │ ║
║  │  This Quarter: 89%                     │ │  • Business:    312 days       │ ║
║  └────────────────────────────────────────┘ └────────────────────────────────┘ ║
╚════════════════════════════════════════════════════════════════════════════════╝
```

### Key Features:
- **Account Counts**: Total, open, and closed account metrics
- **Lifecycle Distribution**: Horizontal bar chart of status categories
- **Status by Type**: Grouped comparison of account types
- **Churn Risk Table**: Identified high-risk accounts with scoring
- **Reopening Analysis**: Success rates for reactivated accounts

---

## Implementation Notes

### For Looker:
1. Create an Explore for each view
2. Use LookML to define dimensions and measures
3. Set up drill-down paths for detailed analysis
4. Configure dashboard filters and date ranges
5. Enable scheduled delivery for stakeholders

### For Tableau:
1. Connect to database views as data sources
2. Create calculated fields for derived metrics
3. Build worksheets for each visualization
4. Assemble into dashboard with filters
5. Publish to Tableau Server/Cloud

### For Power BI:
1. Import views using DirectQuery or Import mode
2. Create measures using DAX for calculations
3. Design report pages with visuals
4. Add slicers for interactivity
5. Publish to Power BI Service

### Color Coding Standards:
- 🟢 **Green/Good**: Metrics above target (>60% active rate, high engagement)
- 🟡 **Yellow/Warning**: Metrics near target (50-60% active rate, medium engagement)
- 🔴 **Red/Critical**: Metrics below target (<50% active rate, low engagement)
- 🟠 **Orange/High**: Secondary warning state for risk indicators

---

## Query Performance Tips

1. **Always filter by date**: All tables are partitioned by date
2. **Use views for reporting**: Pre-calculated fields improve performance
3. **Limit lookback periods**: Use DATE_SUB for reasonable date ranges
4. **Cache frequently used queries**: Enable caching in BI tool
5. **Schedule refresh during off-peak**: Run ETL during low-usage hours

---

## Accessing the Dashboards

Once implemented, users can access these dashboards:

1. **Executives**: Dashboard 1 (7-Day Active Users) - High-level KPIs
2. **Product Teams**: Dashboard 2 (Transaction Intelligence) - Feature usage
3. **Growth Teams**: Dashboard 3 (User Engagement) - Cohort analysis
4. **Operations**: Dashboard 4 (Account Health) - Status monitoring

Each dashboard refreshes daily at 8:00 AM UTC with previous day's data.
