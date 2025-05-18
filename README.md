# README for Query 1

## 1. Approach

This query identifies customers who have funded both regular savings plans and investment funds, and ranks them by their total deposits.

- **Tables Used**:  
  - `users_customuser` (to get user info)  
  - `savings_savingsaccount` (to get savings and investment transactions)  
  - `plans_plan` (to classify plans as regular savings or investment funds)

- **Logic**:  
  - Two subqueries aggregate counts and sums of confirmed deposits separately for regular savings (`is_regular_savings = 1`) and investments (`is_a_fund = 1`), grouping by owner_id.  
  - The main query left joins these aggregations to the users table.  
  - Only users with at least one regular savings and one investment plan (`s.savings_count > 0 AND i.investment_count > 0`) are included.  
  - The total deposits are calculated by summing the savings and investment deposits (dividing by 100 to get actual currency amounts).  
  - Results are ordered by total deposits descending, limited to 5000 records.

## 2. Challenges

- **Handling users without both products:**  
  Some users only have savings or investments. To filter for users with both, I applied conditions on the aggregated counts in the `WHERE` clause, which required careful placement after the LEFT JOINs to avoid excluding users prematurely.

- **Dealing with null values:**  
  When users have no savings or investments, aggregation results are null. Using `COALESCE` ensures those values default to zero for counts and sums, preventing errors in calculations.

- **Ensuring accurate sums:**  
  The confirmed amounts are stored in cents, so dividing by 100 converts them to standard currency values.

- **Performance considerations:**  
  Aggregations on large transaction tables can be slow. I indexed the filtering conditions and ensured the joins use indexed keys for better query speed (assuming proper DB indexing).



# README for Query 2

## 1. Approach

This query analyzes customer transaction frequency by calculating their average number of transactions per month and categorizing them into frequency groups.

- **Step 1: Calculate monthly transactions**  
  Using a CTE (`transactions_per_month`), we count the total transactions per user (`owner_id`) for each year and month.

- **Step 2: Compute average monthly transactions**  
  Another CTE (`avg_transactions`) calculates the average transactions per month per user by averaging the monthly counts.

- **Step 3: Categorize users by transaction frequency**  
  In the `categorized` CTE, users are classified into three categories based on their average monthly transactions:  
  - High Frequency: 10 or more transactions per month  
  - Medium Frequency: 3 to 9 transactions per month  
  - Low Frequency: less than 3 transactions per month

- **Final Output:**  
  The outer query groups users by frequency category, counting how many customers fall into each category and reporting the average monthly transactions for each group. The results are ordered with High Frequency first.

## 2. Challenges

- **Accurately calculating monthly transactions:**  
  Ensuring that transactions were grouped correctly by both year and month to avoid mixing data across different months or years.

- **Handling months with no transactions:**  
  Since only months with transactions appear in the data, some months without any transactions for a user are not represented. This means the average is calculated over months with activity only, which might slightly skew the interpretation.

- **Categorization boundaries:**  
  Choosing sensible cutoff points for frequency categories required domain knowledge or assumptions about transaction behavior.

- **Ordering categories in a custom sequence:**  
  SQL's `ORDER BY FIELD(...)` was used to preserve the desired order of categories in the result, which is not alphabetical.


# README for Query 3

## 1. Approach

This query identifies accounts (plans) that have been inactive for more than 365 days or have never had a confirmed transaction.

- **Tables Used:**  
  - `plans_plan` to get the plan details and owner  
  - `savings_savingsaccount` to get transaction history linked to each plan

- **Logic:**  
  - A `LEFT JOIN` from plans to savings accounts includes all plans, even those without transactions.  
  - For each plan, the most recent confirmed transaction date (`confirmed_amount > 0`) is calculated using `MAX(sa.transaction_date)`.  
  - The `DATEDIFF` function calculates how many days have passed since the last confirmed transaction.  
  - The `HAVING` clause filters plans that either have no confirmed transactions (`MAX(sa.transaction_date) IS NULL`) or whose last confirmed transaction was over 365 days ago.  
  - Plans are categorized by type (`Savings`, `Investment`, or `Other`) based on flags in `plans_plan`.  
  - Results are ordered by inactivity days in descending order to highlight the most inactive accounts.

## 2. Challenges

- **Handling plans with no transactions:**  
  Using a `LEFT JOIN` ensures plans without any transactions still appear, and the `MAX(sa.transaction_date) IS NULL` condition captures these correctly.

- **Filtering confirmed transactions:**  
  Only transactions with `confirmed_amount > 0` are relevant, so the join includes this condition to avoid counting unconfirmed or zero-value transactions.

- **Date calculations:**  
  Calculating inactivity required correctly using `DATEDIFF` between the current date and the last transaction date.

- **Accurate categorization:**  
  Ensuring each plan is labeled as `Savings`, `Investment`, or `Other` correctly based on the flags `is_regular_savings` and `is_a_fund`.

---

# README for Query 4

## 1. Approach

This query estimates the Customer Lifetime Value (CLV) for users based on their transaction history and tenure.

- **Step 1: Calculate user tenure**  
  The CTE `user_tenure` finds the date of each user’s first transaction to determine how long they have been active.

- **Step 2: Aggregate user transactions**  
  The CTE `user_transactions` calculates the total number of transactions and the average transaction value (converted from cents to currency units) for each user.

- **Main Query:**  
  - Joins user information from `users_customuser` with the tenure and transactions data.  
  - Calculates tenure in months using `TIMESTAMPDIFF`.  
  - Computes an estimated CLV with this formula:  
    \[
    \text{estimated CLV} = \frac{\text{total transactions}}{\text{tenure in months}} \times 12 \times \text{average transaction value} \times 0.001
    \]  
    - This estimates the annualized transaction volume and scales it by the average transaction value and a factor (0.001) to normalize or convert units.  
  - Filters out users with no recorded transactions or zero months of tenure.  
  - Orders the results by estimated CLV in descending order to identify the highest-value customers.

## 2. Challenges

- **Handling users without transactions:**  
  Using `LEFT JOIN`s ensures all users are included, but filtering out those with no first transaction date removes irrelevant records.

- **Avoiding division by zero:**  
  The formula divides by tenure months, so I used `NULLIF` to prevent division by zero when tenure is zero.

- **Unit conversions:**  
  Transactions amounts are stored in cents, so dividing by 100 converts to currency. The additional multiplication by 0.001 adjusts scale, which needed to be consistent for interpretation.

- **Estimating CLV simplistically:**  
  This is a basic proxy based on transaction count and average value; more complex models could include retention rates, costs, or other factors.

---


