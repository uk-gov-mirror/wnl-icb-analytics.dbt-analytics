{{ config(materialized='table') }}

select
    'CSDS_CARE_CONTACT' as table_id,
    'REPORTING' as database_name,
    'MAIN_DATA' as schema_name,
    'CSDS_CARE_CONTACT' as table_name,
    true as is_active,
    'REFRESH_DATE' as refresh_column,
    'MONTHLY' as frequency_type,
    cast(40 as number(5,0)) as warn_stale_days,
    cast(60 as number(5,0)) as critical_stale_days,
    cast(10 as number(5,2)) as warn_row_change_pct,
    cast(25 as number(5,2)) as critical_row_change_pct,

    'CSDS' as business_area,
    'MONTHLY_SNAPSHOT' as object_type,
    'Legacy monthly CSDS table' as notes

union all

select
    'SUS_IP',
    'REPORTING',
    'MAIN_DATA',
    'IP',
    true,
    'REFRESH_DATE',
    'DAILY',
    2,
    5,
    10,
    25,
    'SUS',
    'DAILY_OPERATIONAL',    
    'Daily dynamic inpatient table'
