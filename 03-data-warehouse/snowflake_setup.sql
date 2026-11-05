-- ============================================================
-- Snowflake setup for the NYC taxi data (Module 3)
-- Run everything with: Ctrl+A, then Ctrl+Enter (or Run All)
-- ============================================================

USE ROLE ACCOUNTADMIN;

-- 1. Confirm the account works
SELECT CURRENT_VERSION();

-- 2. Shrink the warehouse so it burns as few credits as possible
ALTER WAREHOUSE COMPUTE_WH SET
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

-- 3. Safety cap: notify at 80% of 20 credits, suspend the warehouse at 100%
CREATE OR REPLACE RESOURCE MONITOR zoomcamp_monitor
    WITH CREDIT_QUOTA = 20
    TRIGGERS ON 80 PERCENT DO NOTIFY
             ON 100 PERCENT DO SUSPEND;

ALTER WAREHOUSE COMPUTE_WH SET RESOURCE_MONITOR = zoomcamp_monitor;

-- 4. Database and schema (raw = landing zone before any transformation)
CREATE DATABASE IF NOT EXISTS ny_taxi;
CREATE SCHEMA IF NOT EXISTS ny_taxi.raw;

USE WAREHOUSE COMPUTE_WH;
USE SCHEMA ny_taxi.raw;

-- 5. How Snowflake should read the CSV files
CREATE OR REPLACE FILE FORMAT ny_taxi.raw.taxi_csv_format
    TYPE = 'CSV'
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    COMPRESSION = 'AUTO';

-- 6. Stage: a holding area inside Snowflake where files wait to be loaded
CREATE OR REPLACE STAGE ny_taxi.raw.taxi_stage
    FILE_FORMAT = ny_taxi.raw.taxi_csv_format;

-- 7. Destination table (column names differ from the CSV headers)
CREATE OR REPLACE TABLE ny_taxi.raw.yellow_taxi_2021_01 (
    vendor_id             NUMBER,
    pickup_datetime       TIMESTAMP_NTZ,
    dropoff_datetime      TIMESTAMP_NTZ,
    passenger_count       NUMBER,
    trip_distance         FLOAT,
    ratecode_id           NUMBER,
    store_and_fwd_flag    VARCHAR,
    pu_location_id        NUMBER,
    do_location_id        NUMBER,
    payment_type          NUMBER,
    fare_amount           FLOAT,
    extra                 FLOAT,
    mta_tax               FLOAT,
    tip_amount            FLOAT,
    tolls_amount          FLOAT,
    improvement_surcharge FLOAT,
    total_amount          FLOAT,
    congestion_surcharge  FLOAT
);

-- 8. Verify the setup
SHOW STAGES IN SCHEMA ny_taxi.raw;
SELECT COUNT(*) FROM ny_taxi.raw.yellow_taxi_2021_01;  -- 0 until data is loaded