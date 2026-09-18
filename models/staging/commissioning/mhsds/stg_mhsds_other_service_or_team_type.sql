{{ config(materialized='table', tags=['mhsds']) }}

select * exclude (row_number)
from {{ ref('stg_mhsds_referral_service_team_history') }} as s
where service_or_team_id is not null
qualify row_number() over (
    partition by s.uniq_serv_req_id, service_or_team_id
    order by
        s.reporting_period_end_date desc
        , s.effective_from desc nulls last
        , s.uniq_submission_id desc
        , s.row_number desc
        , s.mhs102_uniq_id desc
) = 1
