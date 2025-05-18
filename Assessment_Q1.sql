SELECT
    u.id AS owner_id,
    CONCAT(u.first_name, ' ', u.last_name) AS name,
    COALESCE(s.savings_count, 0) AS savings_count,
    COALESCE(i.investment_count, 0) AS investment_count,
    COALESCE(s.total_savings_deposits, 0) + COALESCE(i.total_investment_deposits, 0) AS total_deposits
FROM users_customuser u
LEFT JOIN (
    SELECT 
        sa.owner_id,
        COUNT(DISTINCT sa.plan_id) AS savings_count,
        SUM(sa.confirmed_amount) / 100.0 AS total_savings_deposits
    FROM savings_savingsaccount sa
    JOIN plans_plan p ON sa.plan_id = p.id
    WHERE p.is_regular_savings = 1
      AND sa.confirmed_amount > 0
    GROUP BY sa.owner_id
) s ON u.id = s.owner_id
LEFT JOIN (
    SELECT 
        sa.owner_id,
        COUNT(DISTINCT sa.plan_id) AS investment_count,
        SUM(sa.confirmed_amount) / 100.0 AS total_investment_deposits
    FROM savings_savingsaccount sa
    JOIN plans_plan p ON sa.plan_id = p.id
    WHERE p.is_a_fund = 1
      AND sa.confirmed_amount > 0
    GROUP BY sa.owner_id
) i ON u.id = i.owner_id
WHERE s.savings_count > 0 
  AND i.investment_count > 0
ORDER BY total_deposits DESC
LIMIT 5000 OFFSET 0;
