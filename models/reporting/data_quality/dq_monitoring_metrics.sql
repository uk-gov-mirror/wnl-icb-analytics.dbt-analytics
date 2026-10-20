{{ config(materialized='table') }}

select
    current_timestamp() as measured_at,
    'CSDS_CARE_CONTACT' as table_id,
    count(*) as row_count,
    max(refresh_date) as refresh_date,
    datediff(day, max(refresh_date), current_date()) as days_since_refresh,
    'MONTHLY' as frequency_type
from REPORTING.MAIN_DATA.CSDS_CARE_CONTACT

union all

select
    current_timestamp() as measured_at,
    'SUS_IP' as table_id,
    count(*) as row_count,
    max(refresh_date) as refresh_date,
    datediff(day, max(refresh_date), current_date()) as days_since_refresh,
    'DAILY' as frequency_type
from REPORTING.MAIN_DATA.IP
