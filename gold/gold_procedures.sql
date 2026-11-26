
CREATE OR ALTER PROCEDURE dbo.usp_load_dimensions
AS
BEGIN

    -- DimDate ----------------------------------------------------------
    DROP TABLE IF EXISTS dbo.DimDate;

    CREATE TABLE dbo.DimDate AS
    SELECT
        CONVERT(int, CONVERT(char(8), rate_date, 112))      AS date_key,   -- yyyymmdd
        rate_date                                           AS [date],
        YEAR(rate_date)                                     AS [year],
        MONTH(rate_date)                                    AS [month],
        CONVERT(varchar(20), DATENAME(month, rate_date))    AS month_name,
        CONVERT(varchar(20), DATENAME(weekday, rate_date))  AS day_of_week,
        CASE DATENAME(weekday, rate_date)
            WHEN 'Monday'    THEN 1
            WHEN 'Tuesday'   THEN 2
            WHEN 'Wednesday' THEN 3
            WHEN 'Thursday'  THEN 4
            WHEN 'Friday'    THEN 5
            WHEN 'Saturday'  THEN 6
            WHEN 'Sunday'    THEN 7
        END                                                 AS day_of_week_num,
        CASE
            WHEN DATENAME(weekday, rate_date) IN ('Saturday', 'Sunday') THEN 1
            ELSE 0
        END                                                 AS is_weekend,
        usd_per_eur,
        is_filled                                           AS fx_is_filled
    FROM lh_silver.dbo.fx_usd_eur_daily;

    -- DimZone ----------------------------------------------------------
    DROP TABLE IF EXISTS dbo.DimZone;

    CREATE TABLE dbo.DimZone AS
    SELECT
        location_id     AS zone_key,
        borough,
        [zone],
        service_zone,
        CASE
            WHEN service_zone IN ('EWR', 'Airports') THEN 1
            ELSE 0
        END             AS is_airport
    FROM lh_silver.dbo.taxi_zones;

    -- DimStation -------------------------------------------------------
    DROP TABLE IF EXISTS dbo.DimStation;

    CREATE TABLE dbo.DimStation AS
    SELECT
        s.location_id   AS station_key,
        s.location_name,
        s.latitude,
        s.longitude,
        s.is_monitor,
        f.borough,
        f.in_nyc
    FROM (
        SELECT DISTINCT location_id, location_name, latitude, longitude, is_monitor
        FROM lh_silver.dbo.air_quality_daily
    ) AS s
    JOIN lh_silver.dbo.aq_location_ref AS f
        ON f.location_id = s.location_id;

    -- DimGDP -----------------------------------------------------------
    DROP TABLE IF EXISTS dbo.DimGDP;

    CREATE TABLE dbo.DimGDP AS
    SELECT
        [year]          AS gdp_key,
        country_code,
        gdp_usd,
        gdp_usd_trillion
    FROM lh_silver.dbo.gdp_yearly;

END;
GO


   --------2. FACTS: FactTaxiHourly, FactAirQualityDaily

CREATE OR ALTER PROCEDURE dbo.usp_load_facts
AS
BEGIN

    -- FactTaxiHourly ---------------------------------------------------
    DROP TABLE IF EXISTS dbo.FactTaxiHourly;

    CREATE TABLE dbo.FactTaxiHourly AS
    SELECT
        CONVERT(int, CONVERT(char(8), pickup_date, 112))                        AS date_key,
        pu_location_id                                                          AS zone_key,
        pickup_hour,
        COUNT(*)                                                                AS trip_count,
        SUM(CASE WHEN is_refund = 1 THEN 1 ELSE 0 END)                          AS refund_count,
        SUM(total_amount)                                                       AS revenue_usd,
        SUM(CASE WHEN is_refund = 0 THEN trip_distance ELSE 0 END)              AS total_distance_mi,
        SUM(CASE WHEN is_zero_duration = 0 THEN trip_duration_min ELSE 0 END)   AS total_duration_min,
        SUM(CASE WHEN is_zero_duration = 0 THEN 1 ELSE 0 END)                   AS duration_trip_count
    FROM lh_silver.dbo.taxi_trips
    GROUP BY
        CONVERT(int, CONVERT(char(8), pickup_date, 112)),
        pu_location_id,
        pickup_hour;

    -- FactAirQualityDaily ----------------------------------------------
    DROP TABLE IF EXISTS dbo.FactAirQualityDaily;

    CREATE TABLE dbo.FactAirQualityDaily AS
    SELECT
        CONVERT(int, CONVERT(char(8), measure_date, 112))   AS date_key,
        location_id                                         AS station_key,
        sensor_id,
        [parameter],
        units,
        avg_value,
        coverage_pct,
        is_low_coverage
    FROM lh_silver.dbo.air_quality_daily;

END;

EXEC dbo.usp_load_dimensions;
EXEC dbo.usp_load_facts;

