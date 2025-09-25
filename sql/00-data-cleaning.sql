```sql 
SELECT Id, SleepDay, 
COUNT(*) as times
FROM `bellabeat-analysis-472517.fitbit_data.sleep_day`
GROUP BY Id, SleepDay
HAVING COUNT(*) > 1;
´´´ 
