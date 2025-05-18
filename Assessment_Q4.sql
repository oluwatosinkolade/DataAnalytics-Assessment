WITH user_tenure AS (
    SELECT 
        sa.owner_id,
        MIN(sa.transaction_date) AS first_transaction_date
    FROM savings_savingsaccount sa
    GROUP BY sa.owner_id
),
user_transactions AS (
    SELECT
        sa.owner_id,
        COUNT(sa.id) AS total_transactions,
        AVG(sa.confirmed_amount / 100.0) AS avg_transaction_value
    FROM savings_savingsaccount sa
    GROUP BY sa.owner_id
)
SELECT
    u.id AS customer_id,
    CONCAT(u.first_name, ' ', u.last_name) AS name,
    TIMESTAMPDIFF(MONTH, ut.first_transaction_date, CURDATE()) AS tenure_months,
    COALESCE(utx.total_transactions, 0) AS total_transactions,
    ROUND(
        (COALESCE(utx.total_transactions, 0) / NULLIF(TIMESTAMPDIFF(MONTH, ut.first_transaction_date, CURDATE()), 0)) 
        * 12 
        * COALESCE(utx.avg_transaction_value, 0) * 0.001, 
        2
    ) AS estimated_clv
FROM users_customuser u
LEFT JOIN user_tenure ut ON u.id = ut.owner_id
LEFT JOIN user_transactions utx ON u.id = utx.owner_id
WHERE ut.first_transaction_date IS NOT NULL
  AND TIMESTAMPDIFF(MONTH, ut.first_transaction_date, CURDATE()) > 0
ORDER BY estimated_clv DESC;
