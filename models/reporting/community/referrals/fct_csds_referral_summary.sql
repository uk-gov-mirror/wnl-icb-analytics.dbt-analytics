-- Attended 5/6, did not attend 3/7, cancelled 2/4 (patient or provider).
with contacts as (
    select
        referral_id
        , nullif(ltrim(trim(coalesce(attendance_code, source_attendance_status_code)), '0'), '') as attendance
        , care_contact_date
        , clinical_contact_duration_minutes
        , source_row_id
        , is_referral_person_consistent
    from {{ ref('fct_csds_care_contact') }}
)

, contact_measures as (
    select
        referral_id
        , count(*) as n_contacts
        , count_if(attendance in ('5', '6')) as n_attended_contacts
        , count_if(attendance in ('3', '7')) as n_dna_contacts
        , count_if(attendance = '2') as n_patient_cancelled_contacts
        , count_if(attendance = '4') as n_provider_cancelled_contacts
        , count_if(attendance is null) as n_contacts_with_missing_attendance
        , count_if(is_referral_person_consistent = false) as n_contacts_with_different_referral_person
        , sum(iff(attendance in ('5', '6'), clinical_contact_duration_minutes, null)) as attended_contact_minutes
        , min(care_contact_date) as first_contact_date
        , max(care_contact_date) as latest_contact_date
        , min(iff(attendance in ('5', '6'), care_contact_date, null)) as first_attended_contact_date
        , max(iff(attendance in ('5', '6'), care_contact_date, null)) as latest_attended_contact_date
    from contacts
    group by referral_id
)

-- Activities in the same submission as each referral's latest contact rows.
, activity_measures as (
    select
        c.referral_id
        , count(*) as n_care_activities
        , count(distinct a.activity_type_code) as n_care_activity_types
    from contacts as c
    inner join {{ ref('fct_csds_care_activity') }} as a
        on c.source_row_id = a.contact_source_row_id
    group by c.referral_id
)

, team_measures as (
    select
        referral_id
        , count(*) as n_service_team_relationships
        , count(distinct service_type_code) as n_service_team_types
    from {{ ref('fct_csds_referral_service') }}
    group by referral_id
)

, rtt_measures as (
    select
        referral_source_record_id
        , count(distinct rtt_start_date) as n_rtt_clock_start_dates
        , count_if(is_response_standard_met = true) as n_rtt_records_response_standard_met
    from {{ ref('fct_csds_referral_to_treatment_period') }}
    group by referral_source_record_id
)

select
    r.*
    , d.as_of_date
    , p.is_recorded_open_at_period_end as is_recorded_open_at_latest_period
    , p.recorded_access_state as latest_recorded_access_state
    , coalesce(c.n_contacts, 0) as n_contacts
    , coalesce(c.n_attended_contacts, 0) as n_attended_contacts
    , coalesce(c.n_dna_contacts, 0) as n_dna_contacts
    , coalesce(c.n_patient_cancelled_contacts, 0) as n_patient_cancelled_contacts
    , coalesce(c.n_provider_cancelled_contacts, 0) as n_provider_cancelled_contacts
    , coalesce(c.n_contacts_with_missing_attendance, 0) as n_contacts_with_missing_attendance
    , coalesce(c.n_contacts_with_different_referral_person, 0) as n_contacts_with_different_referral_person
    , c.attended_contact_minutes
    , c.first_contact_date
    , c.latest_contact_date
    , c.first_attended_contact_date
    , c.latest_attended_contact_date
    , iff(c.first_attended_contact_date < r.referral_received_date, null,
        datediff(day, r.referral_received_date, c.first_attended_contact_date))
        as days_to_first_attended_contact
    , coalesce(c.first_attended_contact_date < r.referral_received_date, false)
        as has_pre_referral_attended_contact
    , coalesce(a.n_care_activities, 0) as n_care_activities
    , coalesce(a.n_care_activity_types, 0) as n_care_activity_types
    , coalesce(t.n_service_team_relationships, 0) as n_service_team_relationships
    , coalesce(t.n_service_team_types, 0) as n_service_team_types
    , coalesce(rtt.n_rtt_clock_start_dates, 0) as n_rtt_clock_start_dates
    , coalesce(rtt.n_rtt_records_response_standard_met, 0) as n_rtt_records_response_standard_met
from {{ ref('fct_csds_referral') }} as r
cross join {{ ref('int_csds_reporting_date') }} as d
left join {{ ref('fct_csds_referral_period') }} as p
    on r.source_row_id = p.source_row_id
    and r.submission_id = p.submission_id
left join contact_measures as c on r.source_record_id = c.referral_id
left join activity_measures as a on r.source_record_id = a.referral_id
left join team_measures as t on r.source_record_id = t.referral_id
left join rtt_measures as rtt on r.source_record_id = rtt.referral_source_record_id
