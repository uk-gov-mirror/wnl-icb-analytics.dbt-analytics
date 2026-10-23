{{ config(materialized='view') }}

select
    overall_status,
    count(*) as table_count
from {{ ref('dq_monitoring_current') }}
group by overall_status
