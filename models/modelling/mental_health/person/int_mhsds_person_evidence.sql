select
    person_id
    , 'referral' as evidence_type
    , count(*) as n_records
    , min(reporting_period_end_date) as first_reporting_period_end_date
    , max(reporting_period_end_date) as last_reporting_period_end_date
from {{ ref('fct_mhsds_referral') }}
where person_id is not null
group by person_id

union all

select
    person_id
    , 'contact' as evidence_type
    , count(*) as n_records
    , min(reporting_period_end_date) as first_reporting_period_end_date
    , max(reporting_period_end_date) as last_reporting_period_end_date
from {{ ref('fct_mhsds_care_contact') }}
where person_id is not null
group by person_id

union all

select
    person_id
    , 'activity' as evidence_type
    , count(*) as n_records
    , min(reporting_period_end_date) as first_reporting_period_end_date
    , max(reporting_period_end_date) as last_reporting_period_end_date
from {{ ref('fct_mhsds_care_activity') }}
where person_id is not null
group by person_id

union all

select
    person_id
    , 'clinical_item' as evidence_type
    , count(*) as n_records
    , min(last_reported_period_end_date) as first_reporting_period_end_date
    , max(last_reported_period_end_date) as last_reporting_period_end_date
from {{ ref('fct_mhsds_clinical_record') }}
where person_id is not null
group by person_id

union all

select
    person_id
    , 'hospital_spell' as evidence_type
    , count(*) as n_records
    , min(reporting_period_end_date) as first_reporting_period_end_date
    , max(reporting_period_end_date) as last_reporting_period_end_date
from {{ ref('fct_mhsds_hospital_provider_spell') }}
where person_id is not null
group by person_id

union all

select
    person_id
    , 'ward_stay' as evidence_type
    , count(*) as n_records
    , min(reporting_period_end_date) as first_reporting_period_end_date
    , max(reporting_period_end_date) as last_reporting_period_end_date
from {{ ref('fct_mhsds_ward_stay') }}
where person_id is not null
group by person_id

union all

select
    person_id
    , 'legal_status' as evidence_type
    , count(*) as n_records
    , min(last_submission_period_end_date) as first_reporting_period_end_date
    , max(last_submission_period_end_date) as last_reporting_period_end_date
from {{ ref('fct_mhsds_mental_health_act_period') }}
where person_id is not null
group by person_id

union all

select
    person_id
    , 'patient_indicator' as evidence_type
    , count(*) as n_records
    , min(reporting_period_end_date) as first_reporting_period_end_date
    , max(reporting_period_end_date) as last_reporting_period_end_date
from {{ ref('stg_mhsds_patientindicators') }}
where person_id is not null
group by person_id

union all

select
    person_id
    , 'patient_snapshot' as evidence_type
    , count(*) as n_records
    , min(reporting_period_end_date) as first_reporting_period_end_date
    , max(reporting_period_end_date) as last_reporting_period_end_date
from {{ ref('stg_mhsds_mpi_history') }}
where person_id is not null
group by person_id

union all

select
    person_id
    , 'activity_staff_link' as evidence_type
    , count(*) as n_records
    , min(reporting_period_end_date) as first_reporting_period_end_date
    , max(reporting_period_end_date) as last_reporting_period_end_date
from {{ ref('rel_mhsds_care_activity_staff') }}
where person_id is not null
group by person_id

union all

select
    person_id
    , 'referral_team_link' as evidence_type
    , count(*) as n_records
    , min(reporting_period_end_date) as first_reporting_period_end_date
    , max(reporting_period_end_date) as last_reporting_period_end_date
from {{ ref('stg_mhsds_referral_service_team_history') }}
where person_id is not null
group by person_id

union all

select
    person_id
    , 'indirect_activity' as evidence_type
    , count(*) as n_records
    , min(reporting_period_end_date) as first_reporting_period_end_date
    , max(reporting_period_end_date) as last_reporting_period_end_date
from {{ ref('stg_mhsds_indirectactivity') }}
where person_id is not null
group by person_id

union all

select
    person_id
    , 'referral_submission' as evidence_type
    , count(*) as n_records
    , min(reporting_period_end_date) as first_reporting_period_end_date
    , max(reporting_period_end_date) as last_reporting_period_end_date
from {{ ref('stg_mhsds_referral_history') }}
where person_id is not null
group by person_id

union all

select
    person_id
    , 'contact_submission' as evidence_type
    , count(*) as n_records
    , min(reporting_period_end_date) as first_reporting_period_end_date
    , max(reporting_period_end_date) as last_reporting_period_end_date
from {{ ref('stg_mhsds_carecontact') }}
where person_id is not null
group by person_id
