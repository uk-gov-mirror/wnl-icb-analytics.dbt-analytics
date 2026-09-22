{{ config(materialized='table') }}

-- Team and GP practice context for each latest referral/contact pair. Team
-- type comes from the contact's own submission; practice from the person's
-- registration on the contact date.
with contact as (
    select
        unique_service_request_identifier
        , unique_care_contact_identifier
        , cyp201_unique_id
        , unique_submission_id
        , person_id
        , care_contact_date
        , care_professional_team_local_identifier
        , unique_care_professional_team_local_identifier
    from {{ ref('stg_csds_care_contact') }}
)

-- CYP102 is keyed by referral and local team. The few repeated keys within one
-- submission carry identical content.
, submission_team as (
    select
        unique_submission_id
        , unique_service_request_identifier
        , care_professional_team_local_identifier
        , service_or_team_type_referred_to_community_care as service_or_team_type_code
    from {{ ref('stg_csds_service_type_history') }}
    qualify row_number() over (
        partition by unique_submission_id, unique_service_request_identifier,
            care_professional_team_local_identifier
        order by cyp102_unique_id desc
    ) = 1
)

-- The referral's team type in the same submission, only when all its teams agree.
, submission_referral_type as (
    select
        unique_submission_id
        , unique_service_request_identifier
        , min(service_or_team_type_code) as service_or_team_type_code
    from submission_team
    group by unique_submission_id, unique_service_request_identifier
    having count(distinct service_or_team_type_code) = 1
)

, team as (
    select
        c.unique_service_request_identifier
        , c.unique_care_contact_identifier
        , case
            when t.service_or_team_type_code is not null then 'contact_team'
            when r.service_or_team_type_code is not null and c.care_professional_team_local_identifier is null
                then 'referral_team_contact_team_missing'
            when r.service_or_team_type_code is not null then 'referral_team_contact_team_unmatched'
            else 'unresolved'
        end as service_or_team_type_basis
        , coalesce(t.service_or_team_type_code, r.service_or_team_type_code) as service_or_team_type_code
    from contact as c
    left join submission_team as t
        on c.unique_submission_id = t.unique_submission_id
        and c.unique_service_request_identifier = t.unique_service_request_identifier
        and c.care_professional_team_local_identifier = t.care_professional_team_local_identifier
    left join submission_referral_type as r
        on c.unique_submission_id = r.unique_submission_id
        and c.unique_service_request_identifier = r.unique_service_request_identifier
)

-- Several providers can report the same registration period; the newest report wins.
, practice_at_contact as (
    select
        c.unique_service_request_identifier
        , c.unique_care_contact_identifier
        , gp.general_medical_practice_code_patient_registration as practice_code
    from contact as c
    inner join {{ ref('stg_csds_gp_registration') }} as gp
        on c.person_id = gp.person_id
        and c.care_contact_date >= gp.start_date_gmp_patient_registration
        and (
            gp.end_date_gmp_patient_registration is null
            or c.care_contact_date < gp.end_date_gmp_patient_registration
        )
    qualify row_number() over (
        partition by c.unique_service_request_identifier, c.unique_care_contact_identifier
        order by gp.start_date_gmp_patient_registration desc nulls last, gp.reporting_period_end_date desc nulls last,
            gp.effective_from desc nulls last, gp.unique_submission_id desc, gp.cyp002_unique_id desc
    ) = 1
)

, latest_gp_registration as (
    select
        person_id
        , general_medical_practice_code_patient_registration as practice_code
    from {{ ref('stg_csds_gp_registration') }}
    qualify row_number() over (
        partition by person_id
        order by start_date_gmp_patient_registration desc nulls last, reporting_period_end_date desc nulls last,
            effective_from desc nulls last, unique_submission_id desc, cyp002_unique_id desc
    ) = 1
)

select
    {{ dbt_utils.generate_surrogate_key(['c.unique_service_request_identifier', 'c.unique_care_contact_identifier']) }}
        as care_contact_source_record_id
    , c.unique_service_request_identifier
    , c.unique_care_contact_identifier
    , c.cyp201_unique_id
    , c.unique_submission_id
    , c.care_professional_team_local_identifier as service_or_team_local_id
    , c.unique_care_professional_team_local_identifier as service_or_team_id
    , t.service_or_team_type_code
    , t.service_or_team_type_basis
    , coalesce(at_contact.practice_code, latest.practice_code) as practice_code
    , case
        when at_contact.practice_code is not null then 'at_contact'
        when latest.practice_code is not null then 'latest_known'
    end as practice_attribution
from contact as c
inner join team as t
    on c.unique_service_request_identifier = t.unique_service_request_identifier
    and c.unique_care_contact_identifier = t.unique_care_contact_identifier
left join practice_at_contact as at_contact
    on c.unique_service_request_identifier = at_contact.unique_service_request_identifier
    and c.unique_care_contact_identifier = at_contact.unique_care_contact_identifier
left join latest_gp_registration as latest
    on c.person_id = latest.person_id
