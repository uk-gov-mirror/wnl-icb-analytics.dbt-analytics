{{ config(materialized='table') }}

-- =====================================================
-- CSDS Care Contacts
-- Monthly snapshot refreshed from CSDS submissions.
-- =====================================================

select

    -- Identity
    'CSDS_CARE_CONTACT'        as table_id,
    'REPORTING'                as database_name,
    'MAIN_DATA'                as schema_name,
    'CSDS_CARE_CONTACT'        as table_name,

    -- Monitoring
    true                       as is_active,
    'REFRESH_DATE'             as refresh_column,
    'MONTHLY'                  as frequency_type,

    -- Freshness thresholds
    40                         as warn_stale_days,
    60                         as critical_stale_days,

    -- Volume thresholds
    10                         as warn_row_change_pct,
    25                         as critical_row_change_pct,

    -- Classification
    'CSDS'                     as business_area,
    'MONTHLY_SNAPSHOT'         as object_type,

    -- Metadata
    'Legacy monthly CSDS table' as notes

union all

-- =====================================================
-- SUS Unified Inpatient (APC)
-- Dynamic table refreshed daily (~05:00).
-- =====================================================

select

    -- Identity
    'SUS_IP'                   as table_id,
    'REPORTING'                as database_name,
    'MAIN_DATA'                as schema_name,
    'IP'                       as table_name,

    -- Monitoring
    true                       as is_active,
    'REFRESH_DATE'             as refresh_column,
    'DAILY'                    as frequency_type,

    -- Freshness thresholds
    2                          as warn_stale_days,
    5                          as critical_stale_days,

    -- Volume thresholds
    10                         as warn_row_change_pct,
    25                         as critical_row_change_pct,

    -- Classification
    'SUS'                      as business_area,
    'DAILY_OPERATIONAL'        as object_type,

    -- Metadata
    'Daily dynamic inpatient table' as notes
    