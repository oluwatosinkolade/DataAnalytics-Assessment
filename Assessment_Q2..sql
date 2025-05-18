WITH transactions_per_month AS (
    SELECT
        sa.owner_id,
        YEAR(sa.transaction_date) AS year,
        MONTH(sa.transaction_date) AS month,
        COUNT(*) AS transactions_in_month
    FROM savings_savingsaccount sa
    GROUP BY sa.owner_id, year, month
),
avg_transactions AS (
    SELECT
        owner_id,
        AVG(transactions_in_month) AS avg_transactions_per_month
    FROM transactions_per_month
    GROUP BY owner_id
),
categorized AS (
    SELECT
        owner_id,
        CASE
            WHEN avg_transactions_per_month >= 10 THEN 'High Frequency'
            WHEN avg_transactions_per_month BETWEEN 3 AND 9 THEN 'Medium Frequency'
            ELSE 'Low Frequency'
        END AS frequency_category,
        avg_transactions_per_month
    FROM avg_transactions
)
SELECT
    frequency_category,
    COUNT(*) AS customer_count,
    ROUND(AVG(avg_transactions_per_month), 2) AS avg_transactions_per_month
FROM categorized
GROUP BY frequency_category
ORDER BY 
    FIELD(frequency_category, 'High Frequency', 'Medium Frequency', 'Low Frequency');
