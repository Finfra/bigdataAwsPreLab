-- AWS Athena 최적화 쿼리 모음
-- FMS 센서 데이터 분석을 위한 SQL 쿼리

-- 1. 파티션 테이블 생성
CREATE EXTERNAL TABLE IF NOT EXISTS bigdata_catalog.fms_sensor_data (
    device_id string,
    temperature double,
    humidity double,
    pressure double,
    timestamp timestamp,
    temperature_fahrenheit double,
    anomaly_flag boolean
)
PARTITIONED BY (
    year int,
    month int,
    day int,
    hour int
)
STORED AS PARQUET
LOCATION 's3://bigdata-analytics-bucket/processed-data/'
TBLPROPERTIES (
    'projection.enabled'='true',
    'projection.year.type'='integer',
    'projection.year.range'='2024,2025',
    'projection.month.type'='integer',
    'projection.month.range'='1,12',
    'projection.day.type'='integer',
    'projection.day.range'='1,31',
    'projection.hour.type'='integer',
    'projection.hour.range'='0,23',
    'storage.location.template'='s3://bigdata-analytics-bucket/processed-data/year=${year}/month=${month}/day=${day}/hour=${hour}/'
);

-- 2. 실시간 대시보드용 최근 24시간 데이터
WITH recent_data AS (
    SELECT 
        device_id,
        temperature,
        humidity,
        pressure,
        timestamp,
        anomaly_flag,
        ROW_NUMBER() OVER (PARTITION BY device_id ORDER BY timestamp DESC) as rn
    FROM bigdata_catalog.fms_sensor_data
    WHERE year = YEAR(CURRENT_DATE)
      AND month = MONTH(CURRENT_DATE)
      AND day >= DAY(CURRENT_DATE - INTERVAL '1' DAY)
)
SELECT 
    device_id,
    COUNT(*) as total_records,
    AVG(temperature) as avg_temperature,
    MIN(temperature) as min_temperature,
    MAX(temperature) as max_temperature,
    AVG(humidity) as avg_humidity,
    SUM(CASE WHEN anomaly_flag THEN 1 ELSE 0 END) as anomaly_count,
    MAX(timestamp) as last_update
FROM recent_data
WHERE rn <= 1440  -- 최근 24시간 (분당 1개 레코드 가정)
GROUP BY device_id
ORDER BY anomaly_count DESC, avg_temperature DESC;

-- 3. 시간별 온도 트렌드 분석
SELECT 
    HOUR(timestamp) as hour_of_day,
    AVG(temperature) as avg_temperature,
    STDDEV(temperature) as temp_stddev,
    COUNT(*) as data_points,
    SUM(CASE WHEN anomaly_flag THEN 1 ELSE 0 END) as anomaly_count
FROM bigdata_catalog.fms_sensor_data
WHERE year = YEAR(CURRENT_DATE)
  AND month = MONTH(CURRENT_DATE)
  AND day >= DAY(CURRENT_DATE - INTERVAL '7' DAY)  -- 최근 7일
GROUP BY HOUR(timestamp)
ORDER BY hour_of_day;

-- 4. 장비별 성능 분석 (상위 20개 장비)
WITH device_stats AS (
    SELECT 
        device_id,
        COUNT(*) as total_readings,
        AVG(temperature) as avg_temp,
        AVG(humidity) as avg_humidity,
        AVG(pressure) as avg_pressure,
        SUM(CASE WHEN anomaly_flag THEN 1 ELSE 0 END) as anomaly_count,
        (SUM(CASE WHEN anomaly_flag THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) as anomaly_rate
    FROM bigdata_catalog.fms_sensor_data
    WHERE year = YEAR(CURRENT_DATE)
      AND month = MONTH(CURRENT_DATE)
      AND day >= DAY(CURRENT_DATE - INTERVAL '30' DAY)  -- 최근 30일
    GROUP BY device_id
)
SELECT 
    device_id,
    total_readings,
    ROUND(avg_temp, 2) as avg_temperature,
    ROUND(avg_humidity, 2) as avg_humidity,
    ROUND(avg_pressure, 2) as avg_pressure,
    anomaly_count,
    ROUND(anomaly_rate, 2) as anomaly_percentage
FROM device_stats
WHERE total_readings >= 1000  -- 충분한 데이터가 있는 장비만
ORDER BY anomaly_rate DESC, total_readings DESC
LIMIT 20;

-- 5. 이상값 패턴 분석
WITH anomaly_analysis AS (
    SELECT 
        device_id,
        DATE(timestamp) as date,
        HOUR(timestamp) as hour,
        temperature,
        humidity,
        pressure,
        LAG(temperature) OVER (PARTITION BY device_id ORDER BY timestamp) as prev_temp,
        LEAD(temperature) OVER (PARTITION BY device_id ORDER BY timestamp) as next_temp
    FROM bigdata_catalog.fms_sensor_data
    WHERE anomaly_flag = true
      AND year = YEAR(CURRENT_DATE)
      AND month = MONTH(CURRENT_DATE)
      AND day >= DAY(CURRENT_DATE - INTERVAL '7' DAY)
)
SELECT 
    device_id,
    date,
    hour,
    COUNT(*) as anomaly_count,
    AVG(temperature) as avg_anomaly_temp,
    AVG(ABS(temperature - prev_temp)) as avg_temp_change,
    MIN(temperature) as min_temp,
    MAX(temperature) as max_temp
FROM anomaly_analysis
WHERE prev_temp IS NOT NULL
GROUP BY device_id, date, hour
HAVING COUNT(*) >= 3  -- 3개 이상의 이상값이 발생한 시간대
ORDER BY date DESC, hour DESC, anomaly_count DESC;

-- 6. 월별 집계 리포트
SELECT 
    year,
    month,
    COUNT(DISTINCT device_id) as active_devices,
    COUNT(*) as total_readings,
    AVG(temperature) as avg_temperature,
    PERCENTILE_APPROX(temperature, 0.5) as median_temperature,
    PERCENTILE_APPROX(temperature, 0.95) as p95_temperature,
    AVG(humidity) as avg_humidity,
    AVG(pressure) as avg_pressure,
    SUM(CASE WHEN anomaly_flag THEN 1 ELSE 0 END) as total_anomalies,
    (SUM(CASE WHEN anomaly_flag THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) as anomaly_rate
FROM bigdata_catalog.fms_sensor_data
WHERE year >= YEAR(CURRENT_DATE - INTERVAL '1' YEAR)
GROUP BY year, month
ORDER BY year DESC, month DESC;

-- 7. 성능 최적화된 집계 쿼리 (프리 계산)
CREATE TABLE bigdata_catalog.fms_hourly_summary
WITH (
    format = 'PARQUET',
    partitioned_by = ARRAY['year', 'month', 'day'],
    external_location = 's3://bigdata-analytics-bucket/curated-data/hourly-summary/'
) AS
SELECT 
    device_id,
    HOUR(timestamp) as hour,
    COUNT(*) as record_count,
    AVG(temperature) as avg_temperature,
    MIN(temperature) as min_temperature,
    MAX(temperature) as max_temperature,
    STDDEV(temperature) as temp_stddev,
    AVG(humidity) as avg_humidity,
    AVG(pressure) as avg_pressure,
    SUM(CASE WHEN anomaly_flag THEN 1 ELSE 0 END) as anomaly_count,
    YEAR(timestamp) as year,
    MONTH(timestamp) as month,
    DAY(timestamp) as day
FROM bigdata_catalog.fms_sensor_data
WHERE year = YEAR(CURRENT_DATE)
  AND month = MONTH(CURRENT_DATE)
  AND day = DAY(CURRENT_DATE)
GROUP BY 
    device_id,
    HOUR(timestamp),
    YEAR(timestamp),
    MONTH(timestamp),
    DAY(timestamp);

-- 8. 비용 최적화를 위한 파티션 정리
-- (오래된 파티션 삭제 - 1년 이상 된 데이터)
-- 주의: 실제 운영에서는 신중하게 사용
/*
ALTER TABLE bigdata_catalog.fms_sensor_data 
DROP PARTITION (
    year < YEAR(CURRENT_DATE - INTERVAL '1' YEAR)
);
*/

-- 9. 쿼리 성능 모니터링
SELECT 
    query_id,
    query,
    state,
    total_execution_time_in_millis,
    data_scanned_in_bytes,
    data_scanned_in_bytes / 1024.0 / 1024.0 / 1024.0 as data_scanned_gb,
    query_queue_time_in_millis,
    query_planning_time_in_millis,
    service_processing_time_in_millis
FROM information_schema.query_history
WHERE creation_time >= CURRENT_TIMESTAMP - INTERVAL '1' DAY
  AND query LIKE '%fms_sensor_data%'
ORDER BY total_execution_time_in_millis DESC
LIMIT 10;

-- 10. 실시간 알림용 쿼리 (Lambda에서 사용)
-- 최근 5분간 이상값이 5개 이상인 장비 찾기
WITH recent_anomalies AS (
    SELECT 
        device_id,
        COUNT(*) as anomaly_count,
        AVG(temperature) as avg_anomaly_temp,
        MAX(timestamp) as last_anomaly_time
    FROM bigdata_catalog.fms_sensor_data
    WHERE timestamp >= CURRENT_TIMESTAMP - INTERVAL '5' MINUTE
      AND anomaly_flag = true
    GROUP BY device_id
)
SELECT 
    device_id,
    anomaly_count,
    ROUND(avg_anomaly_temp, 2) as avg_temperature,
    last_anomaly_time,
    'HIGH_ANOMALY_RATE' as alert_type
FROM recent_anomalies
WHERE anomaly_count >= 5
ORDER BY anomaly_count DESC;
