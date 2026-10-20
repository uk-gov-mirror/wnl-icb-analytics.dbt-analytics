{{ config(materialized='table') }}

select
    m.measured_at,
    m.table_id,
    m.row_count,
    m.refresh_date,
    m.days_since_refresh,
    m.frequency_type,

    c.warn_stale_days,
    c.critical_stale_days,

    case
        when m.days_since_refresh > c.critical_stale_days
            then 'RED'
        when m.days_since_refresh > c.warn_stale_days
            then 'AMBER'
        else 'GREEN'
    end as status,

    case
        when m.days_since_refresh > c.critical_stale_days
            then 'Refresh overdue - critical threshold exceeded'
        when m.days_since_refresh > c.warn_stale_days
            then 'Refresh overdue - warning threshold exceeded'
        else 'Refresh within expected threshold'
    end as status_reason

from {{ ref('dq_monitoring_metrics') }} m
inner join {{ ref('dq_monitoring_config') }} c
    on m.table_id = c.table_id

where c.is_active = true
