{{
    config(
        materialized='incremental',
        unique_key=['measurement_date', 'table_id', 'provider_code']
    )
}}

/*
    Daily provider-level monitoring history.

    Captures provider presence and row volume for monitored CSDS tables.

    One row per:
        measurement_date
        table_id
        provider_code
*/

with measurements as (

    -- =====================================================
    -- CSDS Referral
    -- =====================================================

    select
        current_date()                      as measurement_date,
        current_timestamp()                 as measured_at,
        'CSDS_REFERRAL'                     as table_id,
        provider_code,
        provider_name,
        count(*)                            as row_count,
        max(refresh_date)                   as latest_refresh_date

    from REPORTING.MAIN_DATA.CSDS_REFERRAL

    where provider_code is not null

    group by
        provider_code,
        provider_name


    union all


    -- =====================================================
    -- CSDS Care Contact
    -- =====================================================

    select
        current_date()                      as measurement_date,
        current_timestamp()                 as measured_at,
        'CSDS_CARE_CONTACT'                 as table_id,
        provider_code,
        provider_name,
        count(*)                            as row_count,
        max(refresh_date)                   as latest_refresh_date

    from REPORTING.MAIN_DATA.CSDS_CARE_CONTACT

    where provider_code is not null

    group by
        provider_code,
        provider_name


    union all


    -- =====================================================
    -- CSDS Care Contact Activity
    -- =====================================================

    select
        current_date()                      as measurement_date,
        current_timestamp()                 as measured_at,
        'CSDS_CARE_CONTACT_ACTIVITY'        as table_id,
        provider_code,
        provider_name,
        count(*)                            as row_count,
        max(created_date)                   as latest_refresh_date

    from REPORTING.MAIN_DATA.CSDS_CARE_CONTACT_ACTIVITY

    where provider_code is not null

    group by
        provider_code,
        provider_name
)

select *
from measurements

{% if is_incremental() %}

where not exists (

    select 1

    from {{ this }} existing

    where existing.measurement_date = measurements.measurement_date
      and existing.table_id = measurements.table_id
      and existing.provider_code = measurements.provider_code

)

{% endif %}
