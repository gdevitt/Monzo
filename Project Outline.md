# Project Outline
The supplied dataset (monzo_datawarehouse) contains four tables:
account_created, account_closed, account_reopened, account_transactions
Each table is fully refreshed on a nightly basis from Monzo's append only logs. These logs
are managed by Backend Engineers and will change over time as the backend systems
changes.
Use your intuition to interpret these source tables. Throughout the task, if anything is unclear
you are free to make common sense assumptions. Please make any assumptions explicit as
we value the process rather than the result.

# Task 1: Accounts
The business needs a very reliable and accurate data model that represents all the different
accounts at Monzo.
Your first task is to create a table using the existing data as outlined above. The most
important requirements are that this model is accurate, complete, intuitive to use and well
documented.
After implementing the model, please outline five of the most important tests that you would
implement to give you the confidence in the output of your process. For this example, you
should assume that upstream tables will change and that source data is not validated using
contracts.

# Task 2: 7-day Active Users
💡 7d_active_users represents the number of users that had a transaction over the last
running 7 days, divided by all the users with at least one open account at that point.
Monzo needs to be able to analyse the activity of our users (remember, one user can be
active across multiple accounts).
In particular, we are looking at a metric aptly named 7d_active_users (defined above). The
goal for this part is to build a data model that will enable analysts on the team to explore this
data very quickly and without friction.
Important requirements:
● The data model should be intuitive to use for others, we should reduce the chances
of misinterpreting the results.
● The design should give people flexibility to answer many different questions, for
example analyse the activity rate for certain age groups or for different signup
cohorts (i.e. when the first account of this user was opened).

● Users with only closed accounts should be excluded from the metric calculation.
● The metric should be calculated for any given day of the year.
● We want this data model to be historically consistent, i.e. if the active rate was
60% on the 2019-01-01 we should be always able to recalculate this number (its
deterministic).

# Monzo DB Tables DDL
CREATE TABLE `account_closed`
(
  closed_ts TIMESTAMP,
  account_id_hashed STRING
);

CREATE TABLE `account_created`
(
  created_ts TIMESTAMP,
  account_type STRING,
  account_id_hashed STRING,
  user_id_hashed STRING
);


CREATE TABLE `account_reopened`
(
  reopened_ts TIMESTAMP,
  account_id_hashed STRING
);


CREATE TABLE `account_transactions`
(
  date DATE,
  account_id_hashed STRING,
  transactions_num INT64
);