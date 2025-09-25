-- Remove duplicates from sleep_day
SELECT COUNT(DISTINCT Id) AS user_count
FROM `fitbit_data.sleep_day`;

 ---Check for dataset sample
SELECT MIN(ActivityDate) AS start_date, MAX(ActivityDate) AS end_date
FROM `fitbit_data.daily_activity`;

--Deleted the timestamp on each date from sleep_day
SELECT
  Id,
  DATE(PARSE_DATETIME('%m/%d/%Y %I:%M:%S %p', SleepDay)) AS SleepDate,
  TotalMinutesAsleep,
  TotalTimeInBed
FROM `fitbit_data.sleep_day`
LIMIT 10;

--Create table with cleaned data
CREATE OR REPLACE TABLE `fitbit_data.sleep_day_clean` AS
SELECT DISTINCT
  Id,
  DATE(PARSE_DATETIME('%m/%d/%Y %I:%M:%S %p', SleepDay)) AS SleepDate,
  TotalSleepRecords,
  TotalMinutesAsleep,
  TotalTimeInBed
FROM `fitbit_data.sleep_day`;

--Check for duplicates from daily_activity
SELECT Id, 
  ActivityDate, 
  TotalSteps,
  COUNT(*) AS dupes
FROM `fitbit_data.daily_activity` 
GROUP BY Id, ActivityDate, TotalSteps
HAVING COUNT (*) >1

--Create table with cleaned data daily_activity, drop columns LoggedActivities and SedentaryActivity
CREATE OR REPLACE TABLE fitbit_data.daily_activity_clean AS
SELECT Id, 
ActivityDate,
TotalSteps,
TotalDistance, 
TrackerDistance,
VeryActiveDistance, 
ModeratelyActiveDistance, 
LightActiveDistance, 
VeryActiveMinutes, 
FairlyActiveMinutes,
LightlyActiveMinutes, 
SedentaryMinutes, 
Calories
 FROM `fitbit_data.daily_activity`;

--Check for duplicates from hourly_steps
SELECT Id, 
  ActivityDate, 
  TotalSteps,
  COUNT(*) AS dupes
FROM `fitbit_data.hourly_steps` 
GROUP BY Id, ActivityDate, TotalSteps
HAVING COUNT (*) >1

--Change date format 
SELECT Id, 
  DATE(PARSE_DATETIME('%m/%d/%Y %I:%M:%S %p', ActivityHour)) AS ActivityDate,
  TIME(PARSE_DATETIME('%m/%d/%Y %I:%M:%S %p', ActivityHour)) AS ActivityTime,
  StepTotal
FROM `fitbit_data.hourly_steps`

--Create table with cleaned data
CREATE OR REPLACE TABLE fitbit_data.hourly_steps_clean AS
SELECT Id, 
  DATE(PARSE_DATETIME('%m/%d/%Y %I:%M:%S %p', ActivityHour)) AS ActivityDate,
  TIME(PARSE_DATETIME('%m/%d/%Y %I:%M:%S %p', ActivityHour)) AS ActivityTime,
  StepTotal
FROM `fitbit_data.hourly_steps`

--Calculate average hourly steps 
SELECT Id,
ROUND(AVG(StepTotal), 2) AS StepsAVG
FROM `fitbit_data.hourly_steps_clean`
GROUP BY Id;

--Number of users that take more tan 10.000 steps 
SELECT 
  COUNT(DISTINCT Id) AS total_users,
  SUM(CASE WHEN StepTotal >= 10000 THEN 1 ELSE 0 END) AS active_users
FROM `fitbit_data.hourly_steps_clean`;

--Activity minutes by category: sedentary, lightly active, fairly active, very active
SELECT DISTINCT Id,
  SUM(SedentaryMinutes) AS sedentary_mins,
  SUM(LightlyActiveMinutes) AS lightly_active_mins,
  SUM(FairlyActiveMinutes) AS fairly_active_mins, 
  SUM(VeryActiveMinutes) AS very_active_mins
FROM `fitbit_data.daily_activity_clean`
GROUP BY Id;

--Activity percentage by user and category
Select 
  DISTINCT Id,
  ROUND(SUM(SedentaryMinutes)*100.0 / SUM(SedentaryMinutes + LightlyActiveMinutes + FairlyActiveMinutes + VeryActiveMinutes),2) AS sedentary_pct,
  ROUND(SUM(LightlyActiveMinutes)*100.0 / SUM(SedentaryMinutes + LightlyActiveMinutes + FairlyActiveMinutes + VeryActiveMinutes),2) AS lightly_active_pct,
  ROUND(SUM(FairlyActiveMinutes)*100.0 / SUM(SedentaryMinutes + LightlyActiveMinutes + FairlyActiveMinutes + VeryActiveMinutes),2) AS fairly_active_pct,
  ROUND(SUM(VeryActiveMinutes)*100.0 / SUM(SedentaryMinutes + LightlyActiveMinutes + FairlyActiveMinutes + VeryActiveMinutes),2) AS very_active_pct
FROM `fitbit_data.daily_activity_clean` 
GROUP BY Id;

--Average steps and calories
SELECT 
  Id,
  AVG(TotalSteps) AS avg_steps,
  AVG(Calories) AS avg_calories
FROM `fitbit_data.daily_activity_clean`
GROUP BY Id;

--Hour of the day preferred by users to walk
SELECT
  EXTRACT(HOUR FROM ActivityTime) AS hour_of_day,
  AVG(StepTotal) AS avg_steps
FROM `bellabeat-analysis-472517.fitbit_data.hourly_steps_clean`
GROUP BY hour_of_day
ORDER BY avg_steps DESC
LIMIT 1;

--What day of the week do users walk the most? 
WITH daily_totals AS (
  SELECT
    Id,
    DATE(ActivityDate) AS activity_date,
    SUM(StepTotal) AS steps_per_day
  FROM `fitbit_data.hourly_steps_clean`
  GROUP BY Id, activity_date
)
SELECT
  EXTRACT(DAYOFWEEK FROM activity_date) AS day_num,
  FORMAT_DATE('%A', activity_date) AS day_name,
  ROUND(AVG(steps_per_day), 0) AS avg_steps
FROM daily_totals
GROUP BY day_num, day_name
ORDER BY day_num;

--Average sleep hours 
SELECT  Id, 
AVG(TotalMinutesAsleep) / 60 AS hours_asleep
FROM `fitbit_data.sleep_day_clean_exact` 
GROUP BY Id; 

--Sleep efficiency percentage 
SELECT Id, 
  AVG(TotalMinutesAsleep)/60 AS avg_sleep_time_hour,
  AVG(TotalTimeInBed)/60 AS avg_time_bed_hour,
  AVG(TotalTimeInBed - TotalMinutesAsleep) AS wasted_bed_time_min, 
  ROUND(SUM(TotalMinutesAsleep) * 100 / SUM(TotalTimeInBed),2) AS sleep_efficiency
FROM `fitbit_data.sleep_day_clean_exact`
GROUP BY Id;
--Total calories and minutes slept
SELECT
  daily.Id, 
  SUM(TotalMinutesAsleep) AS total_sleep_min,
  SUM(TotalTimeInBed) AS total_time_inbed_min,
  SUM(Calories) AS calories
FROM `fitbit_data.daily_activity_clean` AS daily
INNER JOIN `fitbit_data.sleep_day_clean_exact` AS sleep
ON daily.Id = sleep.Id AND daily.ActivityDate = sleep.SleepDate
GROUP BY daily.Id; 
