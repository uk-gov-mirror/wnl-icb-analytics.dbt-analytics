{{ config(materialized='semantic_view', schema='SEMANTIC') }}

TABLES(
    people AS {{ ref('fct_mhsds_person_summary') }}
        PRIMARY KEY (person_id) COMMENT = 'One identifiable MHSDS person, current evidence summary',
    referrals AS {{ ref('fct_mhsds_referral_summary') }}
        PRIMARY KEY (source_record_id) COMMENT = 'One recorded referral with access measures',
    contacts AS {{ ref('fct_mhsds_care_contact') }}
        PRIMARY KEY (source_record_id) COMMENT = 'One latest referral/contact pair, all attendance states',
    spells AS {{ ref('fct_mhsds_hospital_provider_spell') }}
        PRIMARY KEY (source_record_id) COMMENT = 'One recorded provider spell, before occupancy inference',
    occupancy AS {{ ref('fct_mhsds_inpatient_occupancy') }}
        PRIMARY KEY (occupancy_interval_id) COMMENT = 'One retained inferred occupancy interval',
    diagnoses AS {{ ref('fct_mhsds_diagnosis') }}
        PRIMARY KEY (diagnosis_record_id) COMMENT = 'One retained diagnosis evidence item',
    assessments AS {{ ref('fct_mhsds_assessment_observation') }}
        PRIMARY KEY (assessment_observation_id) COMMENT = 'One accepted assessment question, dimension or score occurrence',
    legal_status AS {{ ref('fct_mhsds_mental_health_act_period') }}
        PRIMARY KEY (mental_health_act_period_id) COMMENT = 'One recorded legal-status period',
    submissions AS {{ ref('dq_mhsds_provider_submission') }}
        PRIMARY KEY (provider_organisation_code, reporting_period_end_date) COMMENT = 'One provider and accepted reporting period'
)

RELATIONSHIPS(
    referrals (person_id) REFERENCES people,
    contacts (person_id) REFERENCES people,
    spells (person_id) REFERENCES people,
    occupancy (person_id) REFERENCES people,
    diagnoses (person_id) REFERENCES people,
    assessments (person_id) REFERENCES people,
    legal_status (person_id) REFERENCES people
)

DIMENSIONS(
    people.person_id AS person_id COMMENT = 'MHSDS person key for aggregate cohort linkage only. Never return identifiers in final output.',
    people.sk_patient_id AS sk_patient_id COMMENT = 'Cross-system pseudonymised patient key. May be null. Aggregate each cohort before cross-view joins; never return identifiers.',
    people.as_of_date AS as_of_date COMMENT = 'Latest accepted dataset period, not the run date or evidence that all providers are current.',
    people.person_last_evidence_date AS last_evidence_reporting_period_end_date COMMENT = 'Latest period attached to retained person evidence.',
    people.is_current_inpatient AS is_current_inpatient COMMENT = 'Current inferred occupancy under the established recency/overlap rules.',
    people.is_currently_detained AS is_currently_detained COMMENT = 'Current detention under the documented open, expiry and submission-recency rule.',
    people.has_recorded_detention AS has_recorded_detention COMMENT = 'Any recorded detention evidence, not lifetime completeness.',
    people.is_looked_after_child AS is_looked_after_child COMMENT = 'Latest submitted indicator; null for unknown.',
    people.has_primary_diagnosis_evidence AS n_primary_diagnosis_records > 0 COMMENT = 'Recorded primary diagnosis evidence, not a clinically current diagnosis.',
    people.has_recent_attended_contact AS n_attended_contacts_12m > 0 COMMENT = 'Attended contact within the bounded 12-month window ending at as_of_date.',
    referrals.referrals_provider_code AS provider_organisation_code COMMENT = 'Provider code belonging to this entity.',
    referrals.referrals_provider_name AS provider_organisation_name COMMENT = 'Authoritative provider name where available.',
    contacts.contacts_provider_code AS provider_organisation_code COMMENT = 'Provider code belonging to this entity.',
    contacts.contacts_provider_name AS provider_organisation_name COMMENT = 'Authoritative provider name where available.',
    spells.spells_provider_code AS provider_organisation_code COMMENT = 'Provider code belonging to this entity.',
    spells.spells_provider_name AS provider_organisation_name COMMENT = 'Authoritative provider name where available.',
    occupancy.occupancy_provider_code AS provider_organisation_code COMMENT = 'Provider code belonging to this entity.',
    occupancy.occupancy_provider_name AS provider_organisation_name COMMENT = 'Authoritative provider name where available.',
    diagnoses.diagnoses_provider_code AS provider_organisation_code COMMENT = 'Provider code belonging to this entity.',
    diagnoses.diagnoses_provider_name AS provider_organisation_name COMMENT = 'Authoritative provider name where available.',
    assessments.assessments_provider_code AS provider_organisation_code COMMENT = 'Provider code belonging to this entity.',
    assessments.assessments_provider_name AS provider_organisation_name COMMENT = 'Authoritative provider name where available.',
    legal_status.legal_status_provider_code AS provider_organisation_code COMMENT = 'Provider code belonging to this entity.',
    legal_status.legal_status_provider_name AS provider_organisation_name COMMENT = 'Authoritative provider name where available.',
    submissions.submissions_provider_code AS provider_organisation_code COMMENT = 'Provider code belonging to this entity.',
    submissions.submissions_provider_name AS provider_organisation_name COMMENT = 'Authoritative provider name where available.',
    referrals.referral_received_date AS referral_received_date COMMENT = 'Recorded referral receipt date.',
    referrals.recorded_referral_status AS referral_status COMMENT = 'Open means no recorded rejection or discharge. It is not an active caseload definition.',
    referrals.referral_primary_team_type AS primary_service_or_team_type_description COMMENT = 'Recorded primary team type, not the currency-selected service type.',
    referrals.referral_reason AS primary_reason_for_referral_description COMMENT = 'Recorded reason label.',
    referrals.referral_priority AS clinical_response_priority_description COMMENT = 'Recorded priority label.',
    referrals.referral_age AS age_at_referral COMMENT = 'Source age at referral; source special values remain visible.',
    contacts.contact_date AS care_contact_date COMMENT = 'Recorded contact date; cancelled contacts retain their scheduled date.',
    contacts.contact_team_type AS service_or_team_type_description COMMENT = 'Team type recorded for the contact, not inherited from the referral.',
    contacts.contact_team_id AS service_or_team_id COMMENT = 'Recorded provider-qualified team identifier.',
    contacts.contact_attendance AS attendance_status_description COMMENT = 'Recorded attendance label.',
    contacts.is_attended AS is_attended COMMENT = 'Attendance 05 or 06; null when missing.',
    contacts.contact_medium AS consultation_mechanism_description COMMENT = 'Recorded delivery mechanism.',
    contacts.contact_age AS age_at_care_contact COMMENT = 'Source age at contact.',
    spells.recorded_admission_date AS admission_date COMMENT = 'Recorded spell admission date.',
    spells.recorded_discharge_date AS discharge_date COMMENT = 'Missing discharge does not establish current occupancy.',
    occupancy.occupancy_admission_date AS admission_date COMMENT = 'Admission date of the retained interval.',
    occupancy.occupancy_end_date AS occupancy_end_date COMMENT = 'Derived interval end; null when retained as open.',
    occupancy.occupancy_end_reason AS occupancy_end_reason COMMENT = 'Recorded discharge, inferred last submission or supersession, or open.',
    occupancy.occupancy_is_current AS is_current_inpatient COMMENT = 'Whether the interval remains open under the retained occupancy rules.',
    occupancy.occupancy_evidence_date AS occupancy_evidence_as_of_date COMMENT = 'Maximum staged spell reporting period used by occupancy rules.',
    diagnoses.diagnosis_role AS diagnosis_role COMMENT = 'Previous, provisional, primary or secondary recorded diagnosis.',
    diagnoses.diagnosis_code AS diagnosis_code COMMENT = 'Source code; interpret with its coding scheme.',
    diagnoses.diagnosis_description AS diagnosis_description COMMENT = 'Authoritative label if available.',
    diagnoses.diagnosis_scheme AS coding_scheme_description COMMENT = 'Source coding system.',
    diagnoses.diagnosis_recorded_at AS diagnosis_recorded_at COMMENT = 'Recorded time, or discussion time for previous diagnoses. Never a claim of clinical currency.',
    assessments.assessment_concept_code AS assessment_concept_code COMMENT = 'Assessment question or observable code. Distinguish concepts before interpreting scores.',
    assessments.assessment_concept_description AS assessment_concept_description COMMENT = 'Authoritative assessment concept label.',
    assessments.assessment_tool AS assessment_tool_name COMMENT = 'Tool label where identified.',
    assessments.assessment_recorded_at AS assessment_recorded_at COMMENT = 'Supported observation time, including inherited activity timing.',
    assessments.assessment_response_status AS assessment_response_status COMMENT = 'Existing response interpretation. Observations are not completed questionnaires or outcomes.',
    legal_status.legal_status_description AS legal_status_description COMMENT = 'Authoritative legal-status label.',
    legal_status.legal_status_start_date AS legal_status_start_date COMMENT = 'Recorded period start.',
    legal_status.is_detention_period AS is_detention_period COMMENT = 'Existing project code classification.',
    legal_status.is_current_detention_period AS is_current_detention_period COMMENT = 'Existing open, unexpired and recent-submission rule.',
    submissions.submission_period_end AS reporting_period_end_date COMMENT = 'Accepted reporting period, not clinical event date.',
    submissions.is_latest_provider_period AS is_latest_provider_period COMMENT = 'Select true for one current freshness row per provider.',
    submissions.provider_months_behind_dataset AS provider_months_behind_dataset COMMENT = 'Relative freshness only; not proof of an incomplete submission.'
)

METRICS(
    people.person_count AS COUNT(people.person_id) COMMENT = 'Identifiable people in all documented modelled MHSDS evidence, including clinical-only records.',
    people.current_inpatient_person_count AS COUNT_IF(people.is_current_inpatient) COMMENT = 'People with inferred current occupancy evidence.',
    people.currently_detained_person_count AS COUNT_IF(people.is_currently_detained) COMMENT = 'People meeting the unchanged detention-currentness rule.',
    referrals.referral_count AS COUNT(referrals.source_record_id) COMMENT = 'Recorded referrals, including those without person identity.',
    referrals.referral_person_count AS COUNT(DISTINCT referrals.person_id) COMMENT = 'Distinct identified people with selected referrals.',
    referrals.mean_days_to_first_attended_contact AS AVG(referrals.days_to_first_attended_contact) COMMENT = 'Mean over referrals with a valid recorded interval. Excludes unobserved waits; not target compliance.',
    referrals.referrals_with_observed_first_attendance AS COUNT(referrals.days_to_first_attended_contact) COMMENT = 'Denominator for the observed mean interval.',
    contacts.contact_count AS COUNT(contacts.source_record_id) COMMENT = 'All recorded contact attendance states.',
    contacts.attended_contact_count AS COUNT_IF(contacts.is_attended) COMMENT = 'Recorded attended contacts.',
    contacts.dna_contact_count AS COUNT_IF(contacts.is_dna) COMMENT = 'Recorded DNA contacts.',
    contacts.cancelled_contact_count AS COUNT_IF(contacts.is_cancelled) COMMENT = 'Recorded cancelled contacts.',
    contacts.contact_person_count AS COUNT(DISTINCT contacts.person_id) COMMENT = 'Distinct identified people with selected contacts, not a sum of monthly distinct counts.',
    spells.recorded_spell_count AS COUNT(spells.source_record_id) COMMENT = 'Recorded provider spells before occupancy inference.',
    occupancy.occupancy_interval_count AS COUNT(occupancy.occupancy_interval_id) COMMENT = 'Retained inferred intervals, not recorded provider spells.',
    occupancy.current_occupancy_count AS COUNT_IF(occupancy.is_current_inpatient) COMMENT = 'Retained intervals classified as open.',
    diagnoses.diagnosis_record_count AS COUNT(diagnoses.diagnosis_record_id) COMMENT = 'Retained diagnosis records, not distinct conditions or current diagnoses.',
    diagnoses.diagnosis_person_count AS COUNT(DISTINCT diagnoses.person_id) COMMENT = 'Identifiable people with selected diagnosis evidence.',
    assessments.assessment_observation_count AS COUNT(assessments.assessment_observation_id) COMMENT = 'Accepted question, dimension or score occurrences; not completed questionnaires.',
    assessments.scored_observation_count AS COUNT(assessments.assessment_score_numeric) COMMENT = 'Observations with an interpreted numeric score, not outcomes or improvement.',
    legal_status.legal_status_period_count AS COUNT(legal_status.mental_health_act_period_id) COMMENT = 'Recorded periods across all statuses.',
    submissions.accepted_submission_count AS SUM(submissions.n_accepted_submissions) COMMENT = 'Accepted files for selected provider periods.',
    submissions.submitted_referral_row_count AS SUM(submissions.n_referral_source_records) COMMENT = 'Submitted referral records, not new referrals in the period.',
    submissions.submitted_contact_row_count AS SUM(submissions.n_contact_source_records) COMMENT = 'Submitted contact records, not event-date activity.'
)

COMMENT = 'MHSDS recorded care and current evidence. Each metric retains its declared entity grain. General reporting is independent of currency classifications.'
AI_SQL_GENERATION 'Choose the entity matching the question. Recorded spells differ from inferred occupancy. Open referral status does not define active caseload; first attended contact intervals are descriptive, not national waiting standards. Diagnosis records are not current diagnoses, assessment observations are not completed questionnaires, and no improvement measure is defined. Use event dates for activity and submission periods for freshness. Person current-state dimensions describe the latest feed and must not be applied as historical state. Filtering on person attributes restricts analysis to identifiable people. For cross-entity cohorts, reduce each fact to the intended person or referral grain before joining. Never multiply contacts through staff or team relationships. Return aggregates only, never person or patient identifiers. Currency classification and costing are separate models.'
AI_QUESTION_CATEGORIZATION 'Use for MHSDS referral access, attendance and service activity, recorded admissions, inferred current occupancy, recorded diagnoses, assessment observations, legal-status periods, person summaries and submission freshness. Do not claim clinical outcomes, national waiting-time compliance, confirmed caseload or real-time bed occupancy.'
