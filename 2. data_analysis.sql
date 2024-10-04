-- Calculation of basic descriptive statistics to understand the data distribution and its characteristics

-- Total number of trips made = 5,561,981
SELECT COUNT(ride_id) AS total_trips FROM cyclistic_2023;

-- Average = '00:15:29'
SELECT SEC_TO_TIME(AVG(TIME_TO_SEC(ride_length))) AS average
FROM cyclistic_2023;

-- Median = '00:09:47'
SELECT ride_length AS median
FROM (
    SELECT 
        ride_length,
        @rownum := @rownum + 1 AS 'row_number',
        @total_rows := @rownum
    FROM 
        cyclistic_2023
    CROSS JOIN 
        (SELECT @rownum := 0) r
    ORDER BY 
        ride_length
) AS data_sorted,
(SELECT @total_rows) AS total_rows
WHERE 
    data_sorted.row_number IN (FLOOR((@total_rows+1)/2), FLOOR((@total_rows+2)/2));

-- Standard deviation = '00:31:09'. There is a notable dispersion in trip durations, indicating that durations can vary quite a bit from each other.
SELECT SEC_TO_TIME(STDDEV(TIME_TO_SEC(ride_length))) AS standard_deviation
FROM cyclistic_2023;

-- The minimum is '00:01:00' and the maximum is '23:59:52', which verifies the outlier cleaning previously performed.
SELECT 'min' AS calculation, SEC_TO_TIME(MIN(TIME_TO_SEC(ride_length))) AS duration
FROM cyclistic_2023
UNION
SELECT 'max' AS calculation, SEC_TO_TIME(MAX(TIME_TO_SEC(ride_length))) AS duration
FROM cyclistic_2023;
 
-- User segmentation to explore how certain characteristics or behaviors differ between them

-- Number and percentage of trips by bike type and user type
SELECT
  rideable_type,
  member_casual,
  COUNT(*) AS trips,
  COUNT(*) * 100 / (SELECT COUNT(*) FROM cyclistic_2023) AS percentage
FROM cyclistic_2023
GROUP BY rideable_type, member_casual
ORDER BY member_casual;

-- Average trip duration by user type
SELECT member_casual, 
       SEC_TO_TIME(ROUND(AVG(TIME_TO_SEC(ride_length)))) AS trip_average_duration
FROM cyclistic_2023
GROUP BY member_casual;

-- Most popular starting stations by user type
SELECT member_casual, start_station_name, start_lat, start_lng, COUNT(*) AS trips
FROM cyclistic_2023
GROUP BY member_casual, start_station_name, start_lat, start_lng
ORDER BY trips DESC;

-- Top ten starting stations for members
SELECT member_casual, start_station_name, start_lat, start_lng, COUNT(*) AS trips
FROM cyclistic_2023
WHERE member_casual = 'member'
GROUP BY member_casual, start_station_name, start_lat, start_lng
ORDER BY trips DESC
LIMIT 11;

-- Top ten starting stations for casual users
SELECT member_casual, start_station_name, start_lat, start_lng, COUNT(*) AS trips
FROM cyclistic_2023
WHERE member_casual = 'casual'
GROUP BY member_casual, start_station_name, start_lat, start_lng
ORDER BY trips DESC
LIMIT 11;

-- Most popular routes by user type combining start and end stations
SELECT member_casual, CONCAT(start_station_name, ' to ', end_station_name) AS route, COUNT(*) AS trips
FROM cyclistic_2023
GROUP BY route, member_casual
ORDER BY trips DESC;

-- Temporal trend analysis to understand how usage patterns vary over time

-- Number of trips throughout the day by user type
SELECT HOUR(started_at) AS start_hour, 
       SUM(CASE WHEN member_casual = 'member' THEN 1 ELSE 0 END) AS member_trips,
       SUM(CASE WHEN member_casual = 'casual' THEN 1 ELSE 0 END) AS casual_trips
FROM cyclistic_2023
GROUP BY HOUR(started_at)
ORDER BY start_hour;

-- Average trip duration throughout the day by user type
SELECT HOUR(started_at) AS start_hour,
       SEC_TO_TIME(ROUND(AVG(CASE WHEN member_casual = 'member' THEN TIME_TO_SEC(ride_length) ELSE NULL END))) AS member_avg_duration,
       SEC_TO_TIME(ROUND(AVG(CASE WHEN member_casual = 'casual' THEN TIME_TO_SEC(ride_length) ELSE NULL END))) AS casual_avg_duration
FROM cyclistic_2023
GROUP BY HOUR(started_at)
ORDER BY start_hour;

-- Number of trips per day of the week by user type
SELECT day_of_week,
       SUM(CASE WHEN member_casual = 'member' THEN 1 ELSE 0 END) AS member_trips,
       SUM(CASE WHEN member_casual = 'casual' THEN 1 ELSE 0 END) AS casual_trips
FROM cyclistic_2023
GROUP BY day_of_week
ORDER BY FIELD(day_of_week, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday');

-- Average trip duration by day of the week and user type
SELECT
    day_of_week,
    SEC_TO_TIME(ROUND(AVG(CASE WHEN member_casual = 'member' THEN TIME_TO_SEC(ride_length) END))) AS member_avg_duration,
    SEC_TO_TIME(ROUND(AVG(CASE WHEN member_casual = 'casual' THEN TIME_TO_SEC(ride_length) END))) AS casual_avg_duration
FROM cyclistic_2023
GROUP BY day_of_week
ORDER BY FIELD(day_of_week, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday');

-- Number of trips per month by user type
SELECT
    DATE_FORMAT(started_at, '%Y-%m') AS start_month,
    SUM(CASE WHEN member_casual = 'member' THEN 1 ELSE 0 END) AS member_trips,
    SUM(CASE WHEN member_casual = 'casual' THEN 1 ELSE 0 END) AS casual_trips
FROM cyclistic_2023
GROUP BY DATE_FORMAT(started_at, '%Y-%m');

-- Average trip duration by month and user type
SELECT
    DATE_FORMAT(started_at, '%Y-%m') AS start_month,
    SEC_TO_TIME(ROUND(AVG(CASE WHEN member_casual = 'member' THEN TIME_TO_SEC(ride_length) END))) AS member_avg_duration,
    SEC_TO_TIME(ROUND(AVG(CASE WHEN member_casual = 'casual' THEN TIME_TO_SEC(ride_length) END))) AS casual_avg_duration
FROM cyclistic_2023
GROUP BY DATE_FORMAT(started_at, '%Y-%m')
ORDER BY DATE_FORMAT(started_at, '%Y-%m');
