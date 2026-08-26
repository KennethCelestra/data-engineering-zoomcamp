-- Module 1: SQL Refresher
-- Queries run against the yellow_taxi_data and zones tables loaded via ingest_data.py

-- 1. Join taxi trips with zone lookup to get human-readable pickup/dropoff locations
--    instead of raw numeric LocationIDs.
SELECT
    tpep_pickup_datetime,
    tpep_dropoff_datetime,
    total_amount,
    CONCAT(zpu."Borough", ' / ', zpu."Zone") AS pickup_loc,
    CONCAT(zdo."Borough", ' / ', zdo."Zone") AS dropoff_loc
FROM
    yellow_taxi_data t
JOIN
    zones zpu ON t."PULocationID" = zpu."LocationID"
JOIN
    zones zdo ON t."DOLocationID" = zdo."LocationID"
LIMIT 10;


-- 2. Which pickup zones have the most trips overall?
--    Upper East Side North/South dominate, consistent with a dense residential
--    and commercial Manhattan area with heavy taxi usage.
SELECT
    zpu."Zone" AS pickup_zone,
    COUNT(1) AS trip_count
FROM
    yellow_taxi_data t
JOIN
    zones zpu ON t."PULocationID" = zpu."LocationID"
GROUP BY
    zpu."Zone"
ORDER BY
    trip_count DESC
LIMIT 10;


-- 3. Daily trip count and revenue trend for January 2021.
--    NOTE: without the WHERE clause, a handful of rows with corrupted
--    timestamps (e.g. 2008-12-31, 2009-01-01, 2020-12-31) pollute the results
--    with near-zero trip counts on dates outside the actual dataset's range.
--    Filtering to the expected date window removes this bad data.
SELECT
    CAST(tpep_pickup_datetime AS DATE) AS pickup_day,
    COUNT(1) AS trip_count,
    ROUND(SUM(total_amount)::numeric, 2) AS total_revenue
FROM
    yellow_taxi_data
WHERE
    tpep_pickup_datetime >= '2021-01-01'
    AND tpep_pickup_datetime < '2021-02-01'
GROUP BY
    CAST(tpep_pickup_datetime AS DATE)
ORDER BY
    pickup_day
LIMIT 10;