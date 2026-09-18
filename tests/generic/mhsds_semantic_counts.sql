{% test mhsds_semantic_counts(model) %}

select 'people' as entity, s.person_count as semantic_count, d.row_count as domain_count
from semantic_view({{ model }} metrics people.person_count) as s
cross join (select count(*) as row_count from {{ ref('fct_mhsds_person_summary') }}) as d
where s.person_count <> d.row_count

union all

select 'referrals' as entity, s.referral_count as semantic_count, d.row_count as domain_count
from semantic_view({{ model }} metrics referrals.referral_count) as s
cross join (select count(*) as row_count from {{ ref('fct_mhsds_referral_summary') }}) as d
where s.referral_count <> d.row_count

union all

select 'contacts' as entity, s.contact_count as semantic_count, d.row_count as domain_count
from semantic_view({{ model }} metrics contacts.contact_count) as s
cross join (select count(*) as row_count from {{ ref('fct_mhsds_care_contact') }}) as d
where s.contact_count <> d.row_count

union all

select 'spells' as entity, s.recorded_spell_count as semantic_count, d.row_count as domain_count
from semantic_view({{ model }} metrics spells.recorded_spell_count) as s
cross join (select count(*) as row_count from {{ ref('fct_mhsds_hospital_provider_spell') }}) as d
where s.recorded_spell_count <> d.row_count

union all

select 'occupancy' as entity, s.occupancy_interval_count as semantic_count, d.row_count as domain_count
from semantic_view({{ model }} metrics occupancy.occupancy_interval_count) as s
cross join (select count(*) as row_count from {{ ref('fct_mhsds_inpatient_occupancy') }}) as d
where s.occupancy_interval_count <> d.row_count

union all

select 'diagnoses' as entity, s.diagnosis_record_count as semantic_count, d.row_count as domain_count
from semantic_view({{ model }} metrics diagnoses.diagnosis_record_count) as s
cross join (select count(*) as row_count from {{ ref('fct_mhsds_diagnosis') }}) as d
where s.diagnosis_record_count <> d.row_count

union all

select 'assessments' as entity, s.assessment_observation_count as semantic_count, d.row_count as domain_count
from semantic_view({{ model }} metrics assessments.assessment_observation_count) as s
cross join (select count(*) as row_count from {{ ref('fct_mhsds_assessment_observation') }}) as d
where s.assessment_observation_count <> d.row_count

union all

select 'legal_status' as entity, s.legal_status_period_count as semantic_count, d.row_count as domain_count
from semantic_view({{ model }} metrics legal_status.legal_status_period_count) as s
cross join (select count(*) as row_count from {{ ref('fct_mhsds_mental_health_act_period') }}) as d
where s.legal_status_period_count <> d.row_count

union all

select 'contacts_by_person_state' as entity, s.semantic_count, d.row_count as domain_count
from (
    select sum(contact_count) as semantic_count
    from semantic_view(
        {{ model }}
        metrics contacts.contact_count
        dimensions people.is_currently_detained
    )
) as s
cross join (select count(*) as row_count from {{ ref('fct_mhsds_care_contact') }}) as d
where s.semantic_count <> d.row_count

union all

select 'diagnoses_by_person_state' as entity, s.semantic_count, d.row_count as domain_count
from (
    select sum(diagnosis_record_count) as semantic_count
    from semantic_view(
        {{ model }}
        metrics diagnoses.diagnosis_record_count
        dimensions people.is_currently_detained
    )
) as s
cross join (select count(*) as row_count from {{ ref('fct_mhsds_diagnosis') }}) as d
where s.semantic_count <> d.row_count

{% endtest %}
