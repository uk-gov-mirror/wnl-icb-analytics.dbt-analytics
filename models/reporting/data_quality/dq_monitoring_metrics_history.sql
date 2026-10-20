{{
    config(
        materialized='incremental',
        unique_key=['measurement_date','table_id']
    )
}}

with measurements as (
    select
        current_date() as measurement_date,
        current_timestamp() as measured_at,
        'CSDS_CARE_CONTACT' as table_id,
        count(*) as row_count,
        max(refresh_date) as refresh_date,
        datediff(
            day,
            max(refresh_date),
            current_date()
        ) as days_since_refresh,
        'MONTHLY' as frequency_type
    from REPORTING.MAIN_DATA.CSDS_CARE_CONTACT

    union all

    select
        current_date() as measurement_date,
        current_timestamp() as measured_at,
        'SUS_IP' as table_id,
        count(*) as row_count,
        max(refresh_date) as refresh_date,
        datediff(
            day,
            max(refresh_date),
            current_date()
        ) as days_since_refresh,
        'DAILY' as frequency_type
    from REPORTING.MAIN_DATA.IP
)

select *
from measurements

{% if is_incremental() %}

where not exists (
    select 1
    from {{ this }} existing

    where existing.measurement_date = measurements.measurement_date
      and existing.table_id = measurements.table_id
)

{% endif %}
