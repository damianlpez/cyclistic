-- Creation of the database and table.
CREATE SCHEMA IF NOT EXISTS cyclistic;

USE cyclistic;

CREATE TABLE cyclistic_2023 (
    ride_id VARCHAR(50),
    rideable_type VARCHAR(20),
    started_at DATETIME,
    ended_at DATETIME,
    start_station_name VARCHAR(100),
    start_station_id VARCHAR(50),
    end_station_name VARCHAR(100),
    end_station_id VARCHAR(50),
    start_lat VARCHAR(255),
    start_lng VARCHAR(255),
    end_lat VARCHAR(255),
    end_lng VARCHAR(255),
    member_casual VARCHAR(50)
);

-- Data from the 12 CSV files is imported into the database.
SHOW VARIABLES LIKE "local_infile";

SET GLOBAL local_infile=1; -- Enablement of data loading from a local file.

LOAD DATA INFILE "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\202301-divvy-tripdata.csv"
INTO TABLE cyclistic_2023 
FIELDS TERMINATED BY "," 
IGNORE 1 ROWS

-- Verification of the table structure.
DESCRIBE cyclistic_2023; 

-- Check that the number of records in the combined table matches the sum of the individual tables: 5,718,902 records.
SELECT COUNT(*)
FROM cyclistic_2023;

-- Verification of the number of columns.
SELECT COUNT(*) AS num_columns
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'cyclistic' AND TABLE_NAME = 'cyclistic_2023';

-- Creation of an index to speed up query execution.
CREATE INDEX index_ride_id ON cyclistic_2023 (ride_id);

-- Identification of duplicate values in the ride_id column.
SELECT ride_id, COUNT(*) AS duplicates
FROM cyclistic_2023
GROUP BY ride_id
HAVING COUNT(*) > 1
ORDER BY duplicates DESC, ride_id;

-- Removal of 46 rows with duplicate values in the ride_id column.
DELETE FROM cyclistic_2023
WHERE ride_id IN (
    SELECT ride_id
    FROM (
        SELECT ride_id
        FROM cyclistic_2023
        GROUP BY ride_id
        HAVING COUNT(*) > 1
    ) AS duplicates
);

-- Identification of blank or null records in the ride_id column. None found.
SELECT *
FROM cyclistic_2023
WHERE ride_id = '' OR ride_id IS NULL;

-- Verification of bike types in the rideable_type column.
SELECT DISTINCT rideable_type
FROM cyclistic_2023;

-- The query returns three bike types: electric_bike, classic_bike, and docked_bike. Since docked_bike is a subtype of classic_bike, it has been consolidated, leaving only two bike types, which affects 78,270 records.
UPDATE cyclistic_2023
SET rideable_type = 'classic_bike'
WHERE rideable_type = 'docked_bike';

-- Identification of blank or null values in the rideable_type column. None found.
SELECT *
FROM cyclistic_2023
WHERE rideable_type = '' OR rideable_type IS NULL;

-- Identification of rows where started_at is later than ended_at, which is erroneous.
SELECT *
FROM cyclistic_2023
WHERE started_at > ended_at;

-- Removal of 272 rows where started_at is greater than ended_at.
DELETE FROM cyclistic_2023
WHERE started_at > ended_at;

-- Identification of outliers in the started_at and ended_at columns. Outliers are defined as trips shorter than one minute or longer than one day.
SELECT *
FROM cyclistic_2023
WHERE TIMESTAMPDIFF(SECOND, started_at, ended_at) < 60 
OR TIMESTAMPDIFF(SECOND, started_at, ended_at) > 86400; -- 86400 seconds equals 24 hours.

-- Removal of 155,727 rows with outliers.
DELETE FROM cyclistic_2023
WHERE TIMESTAMPDIFF(SECOND, started_at, ended_at) < 60 
OR TIMESTAMPDIFF(SECOND, started_At, ended_at) > 86400;

-- Creation of the ride_length column from the started_at and ended_at columns.
ALTER TABLE cyclistic_2023
ADD ride_length TIME;

-- Calculation of the ride duration in HH:MM format.
UPDATE cyclistic_2023
SET ride_length = TIMEDIFF(ended_at, started_at);

-- Verification of the ride_length column.
SELECT started_at, ended_at, ride_length
FROM cyclistic_2023
LIMIT 20

-- Identification of blank or null records in the ride_length column. None found.
SELECT *
FROM cyclistic_2023
WHERE ride_length = '' OR ride_length IS NULL;

-- Creation of the day_of_week column from the started_at column.
ALTER TABLE cyclistic_2023
ADD day_of_week VARCHAR(20);

-- Identification of the day of the week for each ride.
UPDATE cyclistic_2023
SET day_of_week = DAYNAME(started_at);

-- Verification of the results of the previous query.
SELECT started_at, day_of_week
FROM cyclistic_2023
LIMIT 10;

-- Confirmation that there are only two options in the member_casual column.
SELECT DISTINCT member_casual
FROM cyclistic_2023;

-- Removal of special characters in the member_casual column.
UPDATE cyclistic_2023
SET member_casual = REPLACE(member_casual, '\r', '');

-- Identification of records with two or more extra spaces between words in the start_station_name and end_station_name columns.
SELECT *
FROM cyclistic_2023
WHERE start_station_name REGEXP '[[:space:]]{2,}' OR end_station_name REGEXP '[[:space:]]{2,}';

-- Removal of extra spaces in 8 records from the start_station_name and end_station_name columns.
UPDATE cyclistic_2023
SET start_station_name = REPLACE(start_station_name, '  ', ' '),
    end_station_name = REPLACE(end_station_name, '  ', ' ')
WHERE start_station_name LIKE '%  %' OR end_station_name LIKE '%  %';

-- Verification of blank or null values in the start_station_name column for classic bikes. Classic bikes must start at a designated station, unlike electric bikes, where this is not required.
FROM cyclistic_2023
WHERE (start_station_name IS NULL OR start_station_name = '') 
AND rideable_type = 'classic_bike';

-- Removal of 876 rows with blank or null values in the start_station_name column for classic bikes.
DELETE FROM cyclistic_2023
WHERE (start_station_name IS NULL OR start_station_name = '') 
AND rideable_type = 'classic_bike';
