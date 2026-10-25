{{ config(materialized='table', cluster_by=['person_id', 'reading_date']) }}

-- Local NDA-consistent control rule. Values can come from different readings,
-- but never from different dates or measurement contexts.
WITH reading_rows AS (
    SELECT
        person_id,
        effective_date::DATE AS reading_date,
        bp_context_group,
        COALESCE(parent_observation_id::VARCHAR, 'NOPARENT:' || bp_context_group) AS reading_id,
        id::VARCHAR AS observation_id,
        date_recorded,
        result_value,
        is_systolic_row,
        is_diastolic_row,
        CASE bp_context
            WHEN 'ABPM_DAY' THEN 1
            WHEN 'ABPM_24H' THEN 3
            ELSE 2
        END AS monitoring_priority
    FROM {{ ref('int_blood_pressure_observations_base') }}
    WHERE effective_date::DATE <= CURRENT_DATE()
        -- NG136 monitoring uses waking-hours averages, not interval extremes.
        AND bp_context NOT IN ('ABPM_NIGHT', 'ABPM_MIN_MAX')
),

complete_readings AS (
    SELECT
        person_id,
        reading_date,
        bp_context_group,
        reading_id,
        monitoring_priority,
        CASE WHEN STARTSWITH(reading_id, 'NOPARENT:') THEN COALESCE(
            MIN(IFF(is_systolic_row AND result_value BETWEEN 40 AND 350, result_value, NULL)),
            MAX(IFF(is_systolic_row, result_value, NULL)))
        ELSE MAX(IFF(is_systolic_row, result_value, NULL)) END AS systolic_value,
        CASE WHEN STARTSWITH(reading_id, 'NOPARENT:') THEN COALESCE(
            MIN(IFF(is_diastolic_row AND result_value BETWEEN 20 AND 200, result_value, NULL)),
            MAX(IFF(is_diastolic_row, result_value, NULL)))
        ELSE MAX(IFF(is_diastolic_row, result_value, NULL)) END AS diastolic_value,
        MAX(date_recorded) AS date_recorded,
        MAX(observation_id) AS observation_id
    FROM reading_rows
    GROUP BY person_id, reading_date, bp_context_group, reading_id, monitoring_priority
    HAVING systolic_value IS NOT NULL AND diastolic_value IS NOT NULL
),

assessed AS (
    SELECT *,
        systolic_value BETWEEN 40 AND 350
            AND diastolic_value BETWEEN 20 AND 200
            AND systolic_value > diastolic_value AS is_valid_bp
    FROM complete_readings
),

preferred_monitoring AS (
    SELECT *
    FROM assessed
    QUALIFY DENSE_RANK() OVER (
        PARTITION BY person_id, reading_date, bp_context_group
        ORDER BY is_valid_bp DESC, monitoring_priority
    ) = 1
),

daily_minima AS (
    SELECT *,
        MIN(systolic_value) OVER (
            PARTITION BY person_id, reading_date, bp_context_group
        ) AS daily_min_systolic,
        MIN(diastolic_value) OVER (
            PARTITION BY person_id, reading_date, bp_context_group
        ) AS daily_min_diastolic
    FROM preferred_monitoring
)

SELECT
    person_id,
    reading_date,
    bp_context_group,
    IFF(is_valid_bp, daily_min_systolic, systolic_value) AS systolic_value,
    IFF(is_valid_bp, daily_min_diastolic, diastolic_value) AS diastolic_value,
    is_valid_bp,
    bp_context_group = 'HOME' AS is_home_bp_event,
    bp_context_group = 'ABPM' AS is_abpm_bp_event,
    IFF(bp_context_group = 'CLINIC', 'CLINIC', 'HBPM_ABPM') AS applied_measurement_context,
    date_recorded,
    observation_id
FROM daily_minima
-- Metadata identifies the latest contributing reading, not a fabricated pair.
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY person_id, reading_date, bp_context_group
    ORDER BY date_recorded DESC NULLS LAST, observation_id DESC, reading_id DESC
) = 1
