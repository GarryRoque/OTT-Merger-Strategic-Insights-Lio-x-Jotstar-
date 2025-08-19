-- 1: Subscribers

-- Retrieve top 20 subscribers
SELECT TOP 20 * FROM subscribers;

-- Total number of subscribers
SELECT COUNT(user_id) AS total_subscribers FROM subscribers;

-- Subscribers by month
SELECT COUNT(user_id) AS total_count, FORMAT(subscription_date, 'yyyy-MM') AS month_year
FROM subscribers
GROUP BY FORMAT(subscription_date, 'yyyy-MM')
ORDER BY FORMAT(subscription_date, 'yyyy-MM');

-- Growth rate by month
WITH MonthlyUsers AS (
    SELECT 
        FORMAT(subscription_date, 'yyyy-MM') AS month_year,
        COUNT(user_id) AS total_users
    FROM subscribers
    GROUP BY FORMAT(subscription_date, 'yyyy-MM')
)
SELECT 
    month_year,
    total_users,
    LAG(total_users) OVER (ORDER BY month_year) AS prev_month_users,
    ROUND(
        ((total_users - LAG(total_users) OVER (ORDER BY month_year)) * 100.0 
        / NULLIF(LAG(total_users) OVER (ORDER BY month_year), 0)), 2
    ) AS growth_rate
FROM MonthlyUsers
ORDER BY month_year;

-- 2: Content Library

-- Retrieve top 20 sports content
SELECT TOP 20 * FROM contents WHERE content_type='Sports';

-- Count by content type
SELECT COUNT(*) AS count, content_type
FROM contents
GROUP BY content_type
ORDER BY count DESC;

-- Count by content type and genre
SELECT COUNT(*) AS count, content_type, genre
FROM contents
GROUP BY content_type, genre
ORDER BY content_type, count DESC, genre DESC;

-- Count by language
SELECT COUNT(*) AS count, language
FROM contents
GROUP BY language
ORDER BY count DESC;

-- 3: User Demographics

-- Age group distribution
SELECT COUNT(*) AS count, age_group
FROM subscribers
GROUP BY age_group
ORDER BY count DESC;

-- Categorization by city tier
SELECT COUNT(*) AS count, city_tier
FROM subscribers
GROUP BY city_tier
ORDER BY count DESC;

-- Subscription plan analysis
SELECT COUNT(*) AS count, subscription_plan
FROM subscribers
GROUP BY subscription_plan
ORDER BY count DESC;

-- 4: Active vs Inactive Users

-- Active vs inactive users
SELECT 
    COUNT(CASE WHEN last_active_date IS NOT NULL 
                AND last_active_date >= DATEADD(DAY, -60, GETDATE()) 
               THEN user_id END) AS active_users,
    COUNT(CASE WHEN last_active_date IS NULL 
                OR last_active_date < DATEADD(DAY, -60, GETDATE()) 
               THEN user_id END) AS inactive_users
FROM subscribers;

-- Active vs Inactive Users by Month
SELECT FORMAT(subscription_date, 'yyyy-MM') AS year_month, COUNT(user_id) AS total_count,
    COUNT(CASE WHEN last_active_date IS NOT NULL 
        AND last_active_date >= DATEADD(DAY, -30, subscription_date) 
        THEN user_id END) AS active_users,
    COUNT(CASE WHEN last_active_date IS NULL 
        OR last_active_date < DATEADD(DAY, -30, subscription_date) 
        THEN user_id END) AS inactive_users
FROM subscribers
GROUP BY FORMAT(subscription_date, 'yyyy-MM')
ORDER BY FORMAT(subscription_date, 'yyyy-MM');

-- 5: Content Consumption

-- Retrieve all content consumption data
SELECT * FROM content_consumption;

-- Average watch time in hours
SELECT AVG(total_watch_time_mins) / 60 AS avg_watch_time_in_hrs
FROM content_consumption;

-- Average watch time by device type
SELECT device_type, AVG(total_watch_time_mins) / 60 AS avg_watch_time_in_hrs
FROM content_consumption
GROUP BY device_type
ORDER BY avg_watch_time_in_hrs DESC;

-- 6: Upgrade Patterns

-- Plan transition by city (upgrade or downgrade)
SELECT COUNT(*) AS count, city_tier, subscription_plan, new_subscription_plan
FROM subscribers
GROUP BY city_tier, subscription_plan, new_subscription_plan
ORDER BY city_tier, subscription_plan, new_subscription_plan;

-- Downgrade Trends
WITH plan_changes AS (
    SELECT 
        user_id,
        subscription_plan AS old_plan,
        new_subscription_plan AS new_plan,
        plan_change_date,
        CASE 
            WHEN subscription_plan = 'Premium' AND new_subscription_plan = 'Basic' THEN 'Premium to Basic'
            WHEN subscription_plan = 'Premium' AND new_subscription_plan = 'Free' THEN 'Premium to Free'
            WHEN subscription_plan = 'Basic' AND new_subscription_plan = 'Free' THEN 'Basic to Free'
            ELSE NULL 
        END AS downgrade_type
    FROM subscribers
    WHERE plan_change_date IS NOT NULL
)
SELECT 
    downgrade_type,
    COUNT(user_id) AS total_downgrades,
    COUNT(user_id) * 100.0 / (SELECT COUNT(*) FROM subscribers) AS downgrade_rate
FROM plan_changes
WHERE downgrade_type IS NOT NULL
GROUP BY downgrade_type
ORDER BY total_downgrades DESC;

-- 7: Paid Distribution

-- Proportion of paid users by plan
WITH tot AS (
    SELECT COUNT(user_id) AS total_count FROM subscribers
), 
b AS (
    SELECT subscription_plan, COUNT(user_id) AS cnt_by_plan
    FROM subscribers
    GROUP BY subscription_plan
)
SELECT b.subscription_plan, (CAST(b.cnt_by_plan AS FLOAT) / tot.total_count) * 100 AS percentage
FROM b, tot
ORDER BY percentage DESC;

-- 8: Revenue Analysis

-- Revenue by Subscription Plan
WITH user_months AS (
    SELECT 
        subscription_plan,
        CASE 
            WHEN subscription_plan = 'Basic' THEN 69
            WHEN subscription_plan = 'Premium' THEN 129
            ELSE 0
        END AS price,
        DATEDIFF(MONTH, subscription_date, COALESCE(plan_change_date, last_active_date, '2024-11-30')) AS months_subscribed
    FROM subscribers
)
SELECT subscription_plan, SUM(price * months_subscribed) AS total_revenue
FROM user_months
GROUP BY subscription_plan
ORDER BY total_revenue DESC;
