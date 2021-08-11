--- Email cadence experiment may/june 2021 summary stats for visit rate, purchase conversion rate and rpu

WITH 

control_users AS (
--- users who were only in the control group 
SELECT
  DISTINCT userid as user_id,
  'control' as variant
FROM holdout_summary_plus 
WHERE campaign = 'EMAILCADENCECTRL-2021'
AND userid NOT IN (SELECT DISTINCT userid FROM holdout_summary_plus WHERE campaign = 'EMAILCADENCETEST-2021')
--LIMIT 100
), 

test_users AS (
--- users who were only in the test group 
SELECT 
  DISTINCT userid as user_id,
  'test' as variant
FROM holdout_summary_plus 
WHERE campaign = 'EMAILCADENCETEST-2021'
AND userid NOT IN (SELECT DISTINCT userid FROM holdout_summary_plus WHERE campaign = 'EMAILCADENCECTRL-2021')
--LIMIT 100
),

control_user_summary AS( 
SELECT 
  cu.variant,
  cu.user_id,
  COALESCE(COUNT(DISTINCT session_id),0) AS num_visits,
  COALESCE(SUM(num_cart_added),0) AS num_cart_added,
  COALESCE(SUM(session_revenue),0) AS gmv
FROM control_users cu
LEFT JOIN (
            SELECT * 
            FROM session_conversion_funnel 
            WHERE 1=1 
              AND date >= '2021-05-02'
              AND date <= '2021-06-29'
          )scf
USING(user_id)
GROUP BY 1,2
),

control_summary AS (
SELECT 
  variant,
  COUNT(DISTINCT user_id) AS bucketed_users,
  COUNT(DISTINCT CASE WHEN num_visits > 0 THEN user_id END) AS users_with_visit,
  users_with_visit*1.00/bucketed_users as prop_visit,
  --COUNT(DISTINCT CASE WHEN num_cart_added > 0 THEN user_id END) AS users_with_cart_add,
  COUNT(DISTINCT CASE WHEN gmv > 0 THEN user_id END) AS users_with_purchase,
  users_with_purchase*1.00/bucketed_users as prop_purchase,
  AVG(gmv) AS rpu,
  STDDEV(gmv) AS rpu_std
FROM control_user_summary
GROUP BY 1
),

test_user_summary AS( 
SELECT 
  cu.variant,
  cu.user_id,
  COALESCE(COUNT(DISTINCT session_id),0) AS num_visits,
  COALESCE(SUM(num_cart_added),0) AS num_cart_added,
  COALESCE(SUM(session_revenue),0) AS gmv
FROM test_users cu
LEFT JOIN (
            SELECT * 
            FROM session_conversion_funnel 
            WHERE 1=1 
              AND date >= '2021-05-02'
              AND date <= '2021-06-29'
          )scf
USING(user_id)
GROUP BY 1,2
),

test_summary AS (
SELECT 
  variant,
  COUNT(DISTINCT user_id) AS bucketed_users,
  COUNT(DISTINCT CASE WHEN num_visits > 0 THEN user_id END) AS users_with_visit,
  users_with_visit*1.00/bucketed_users as prop_visit,
  --COUNT(DISTINCT CASE WHEN num_cart_added > 0 THEN user_id END) AS users_with_cart_add,
  COUNT(DISTINCT CASE WHEN gmv > 0 THEN user_id END) AS users_with_purchase,
  users_with_purchase*1.00/bucketed_users as prop_purchase,
  AVG(gmv) AS rpu,
  STDDEV(gmv) AS rpu_std
FROM test_user_summary
GROUP BY 1
)

SELECT
  variant,
  bucketed_users,
  users_with_visit,
  prop_visit,
  --users_with_cart_add,
  users_with_purchase,
  prop_purchase,
  rpu,
  rpu_std 
FROM control_summary
UNION
SELECT
  variant,
  bucketed_users,
  users_with_visit,
  prop_visit,
  --users_with_cart_add,
  users_with_purchase,
  prop_purchase,
  rpu,
  rpu_std 
FROM test_summary
