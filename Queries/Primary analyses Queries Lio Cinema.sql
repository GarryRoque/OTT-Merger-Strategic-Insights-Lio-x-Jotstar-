select top 20 *
from subscribers;

--1: Subcribers
--Total number of subscribers for Jotstar
select count(user_id)
from subscribers;

--subscribers by months
select count(user_id),format(subscription_date,'yyyy-MM')
from subscribers
group by format(subscription_date,'yyyy-MM')
order by format(subscription_date,'yyyy-MM');


----Growth rate by months
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
        ( (total_users - LAG(total_users) OVER (ORDER BY month_year)) * 100.0 
        / NULLIF(LAG(total_users) OVER (ORDER BY month_year), 0) ), 2
    ) AS growth_rate
FROM MonthlyUsers
ORDER BY month_year;

--2: Content Library

select top 20 *
from contents
where content_type='Sports'

--Count by content Type
select count(*), content_type
from contents
group by content_type
order by count(*) desc;

--Count by content Type, Genre
select count(*) as count, content_type,genre
from contents
group by content_type,genre
order by content_type,count(*) desc,genre desc;

--Count by Language
select count(*), language
from contents
group by language
order by count(*) desc;


--3: User demographics

select top 20 *
from subscribers;

-- Age group distribution
select count(*), age_group
from subscribers
group by age_group
order by count(*) desc;

--Categorize by City Tier
select count(*), city_tier
from subscribers
group by city_tier
order by count(*) desc;

--Analyse subcription plans
select count(*), subscription_plan
from subscribers
group by subscription_plan
order by count(*) desc;

--4: Active vs Inactive users
SELECT 
    COUNT(CASE WHEN last_active_date IS NOT NULL 
                AND last_active_date >= DATEADD(DAY, -60, GETDATE()) 
               THEN user_id END) AS active_users,
    COUNT(CASE WHEN last_active_date IS NULL 
                OR last_active_date < DATEADD(DAY, -60, GETDATE()) 
               THEN user_id END) AS inactive_users
FROM subscribers;

--Active vs Inactive Users by Month
select format(subscription_date,'yyyy-MM') as Year_month,count(user_id) as total_count,
		COUNT(CASE WHEN last_active_date IS NOT NULL 
			AND last_active_date >= DATEADD(DAY, -30, subscription_date) 
			THEN user_id END) AS active_users,
		COUNT(CASE WHEN last_active_date IS NULL 
			OR last_active_date < DATEADD(DAY, -30, subscription_date) 
			THEN user_id END) AS inactive_users
from subscribers
group by format(subscription_date,'yyyy-MM')
order by format(subscription_date,'yyyy-MM');

--Active vs Inactive Users by age-group
select age_group,count(user_id) as total_count,
		COUNT(CASE WHEN last_active_date IS NOT NULL 
			AND last_active_date >= DATEADD(DAY, -30, subscription_date) 
			THEN user_id END) AS active_users,
		COUNT(CASE WHEN last_active_date IS NULL 
			OR last_active_date < DATEADD(DAY, -30, subscription_date) 
			THEN user_id END) AS inactive_users
from subscribers
group by age_group
order by age_group;

--Active vs Inactive Users by subcription plan
select subscription_plan,count(user_id) as total_count,
		COUNT(CASE WHEN last_active_date IS NOT NULL 
			AND last_active_date >= DATEADD(DAY, -30, subscription_date) 
			THEN user_id END) AS active_users,
		COUNT(CASE WHEN last_active_date IS NULL 
			OR last_active_date < DATEADD(DAY, -30, subscription_date) 
			THEN user_id END) AS inactive_users
from subscribers
group by subscription_plan
order by subscription_plan;

--5: Content Consumption

Select *
from content_consumption;

--Average watch time

select avg(total_watch_time_mins)/60 as Avg_watch_time_in_hrs
from content_consumption;

--Average watch time by device type
select device_type, avg(total_watch_time_mins)/60 as Avg_watch_time_in_hrs
from content_consumption
group by device_type
order by avg(total_watch_time_mins)/60 desc;

--Average watch time by age_group
select s.age_group, avg(c.total_watch_time_mins)/60 as Avg_watch_time_in_hrs
from content_consumption c
inner join subscribers s on s.user_id=c.user_id
group by s.age_group
order by avg(c.total_watch_time_mins)/60 desc;

--Average watch time by city tier
select s.city_tier, avg(c.total_watch_time_mins)/60 as Avg_watch_time_in_hrs
from content_consumption c
inner join subscribers s on s.user_id=c.user_id
group by s.city_tier
order by avg(c.total_watch_time_mins)/60 desc;

--Average watch time by city tier and age group
select s.city_tier,s.age_group,avg(c.total_watch_time_mins)/60 as Avg_watch_time_in_hrs
from content_consumption c
inner join subscribers s on s.user_id=c.user_id
group by s.city_tier,s.age_group
order by s.city_tier asc,avg(c.total_watch_time_mins)/60 desc ,s.age_group;


--7: Upgrade Patterns

select top 20 *
from subscribers;

--Plan transition by city upgrade or downgrade
select count(*), city_tier,subscription_plan,new_subscription_plan
from subscribers
group by city_tier,subscription_plan,new_subscription_plan
order by city_tier,subscription_plan,new_subscription_plan;

--Query for Downgrade Trends
WITH plan_changes AS (
    SELECT 
        user_id,
        subscription_plan AS old_plan,
        new_subscription_plan AS new_plan,
        plan_change_date,
        -- Categorizing downgrade cases
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
    -- Downgrade rate calculation
    COUNT(user_id) * 100.0 / (SELECT COUNT(*) FROM subscribers) AS downgrade_rate
FROM plan_changes
WHERE downgrade_type IS NOT NULL
GROUP BY downgrade_type
ORDER BY  total_downgrades DESC;

--8: Upgrade patterns by city

WITH plan_changes AS (
    SELECT 
        user_id,
        city_tier,
        subscription_plan AS old_plan,
        new_subscription_plan AS new_plan,
        plan_change_date,
        -- Categorizing upgrade cases
        CASE 
            WHEN subscription_plan = 'Free' AND new_subscription_plan = 'Premium' THEN 'Free to Premium'
            WHEN subscription_plan = 'Free' AND new_subscription_plan = 'Basic' THEN 'Free to Basic'
            WHEN subscription_plan = 'Basic' AND new_subscription_plan = 'Premium' THEN 'Basic to Premium'
            ELSE NULL 
        END AS upgrade_type
    FROM subscribers
    WHERE plan_change_date IS NOT NULL
)
SELECT 
    city_tier,
    upgrade_type,
    COUNT(user_id) AS total_upgrades,
    -- Upgrade rate calculation
    COUNT(user_id) * 100.0 / (SELECT COUNT(*) FROM subscribers) AS upgrade_rate
FROM plan_changes
WHERE upgrade_type IS NOT NULL
GROUP BY city_tier, upgrade_type
ORDER BY city_tier, total_upgrades DESC;



--9: Paid Distribution
--Analyze proportion of paid users by plan
WITH tot AS (
    SELECT COUNT(user_id) AS total_count
    FROM subscribers
), 
b AS (
    SELECT 
        subscription_plan,
        COUNT(user_id) AS cnt_by_plan
    FROM subscribers
    --WHERE subscription_plan <> 'Free'
    GROUP BY subscription_plan
)
SELECT 
    b.subscription_plan,
    (CAST(b.cnt_by_plan AS FLOAT) / tot.total_count) * 100 AS percentage
FROM b,tot
ORDER BY percentage DESC;


--Analyze proportion of paid users in Tier 1, 2, and 3 cities
select count(*), city_tier,subscription_plan
from subscribers
group by city_tier,subscription_plan
having subscription_plan <>'Free'
order by count(*) desc,city_tier,subscription_plan;

-- Identify where premium users are most concentrated
select count(*), city_tier
from subscribers
group by city_tier,subscription_plan
having subscription_plan ='Premium'
order by count(*) desc,city_tier;



--10: 
--Revenue by Subscription plan
WITH user_months AS (
    SELECT 
        s.subscription_plan,
        -- Assign price based on the subscription plan
        CASE 
            WHEN s.subscription_plan = 'Basic' THEN 69
            WHEN s.subscription_plan = 'Premium' THEN 129
            --WHEN s.subscription_plan = 'Basic' THEN 69
            ELSE 0
        END AS price,
        -- Calculate months subscribed
        DATEDIFF(MONTH, s.subscription_date, 
                 COALESCE(s.plan_change_date, s.last_active_date, '2024-11-30')) AS months_subscribed
    FROM subscribers s
)
SELECT subscription_plan,
    SUM(price * months_subscribed) AS total_revenue
FROM user_months
group by subscription_plan
ORDER BY total_revenue DESC;

--Revenue by User,Subscription plan
WITH user_months AS (
    SELECT 
        s.user_id,
        s.subscription_plan,
        -- Assign price based on the subscription plan
        CASE 
            WHEN s.subscription_plan = 'Basic' THEN 69
            WHEN s.subscription_plan = 'Premium' THEN 129
            --WHEN s.subscription_plan = 'Basic' THEN 69
            ELSE 0
        END AS price,
        -- Calculate months subscribed
        DATEDIFF(MONTH, s.subscription_date, 
                 COALESCE(s.plan_change_date, s.last_active_date, '2024-11-30')) AS months_subscribed
    FROM subscribers s
)
SELECT user_id,subscription_plan,price,months_subscribed,
    SUM(price * months_subscribed) AS total_revenue
FROM user_months
group by user_id,subscription_plan,price,months_subscribed
ORDER BY total_revenue DESC;

