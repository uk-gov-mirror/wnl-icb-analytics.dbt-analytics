{{ config(materialized='semantic_view', schema='SEMANTIC') }}

TABLES(
    people AS {{ ref('fct_csds_person_summary') }}
        PRIMARY KEY (person_id) COMMENT = 'Summary of the CSDS evidence for each identifiable person. Each row is one CSDS person ID found in any modelled evidence. Demographics come from the newest period record across providers. as_of_date is the latest accepted dataset period; providers can be older. National ID changes can split one person across rows.',
    referrals AS {{ ref('fct_csds_referral_summary') }}
        PRIMARY KEY (source_record_id) COMMENT = 'Care and access measures for each latest recorded community referral, with its state at its own latest reported period. Contact, activity, team and clock measures are aggregated before joining. Time to first attendance is recorded evidence, not a national waiting-time measure.',
    contacts AS {{ ref('fct_csds_care_contact') }}
        PRIMARY KEY (source_record_id) COMMENT = 'Latest referral/contact pairs in all attendance states, including cancellations and non-attendance. Team type is the delivering team from the contact''s own submission; read service_or_team_type_basis before comparing teams across providers.',
    activities AS {{ ref('fct_csds_care_activity') }}
        PRIMARY KEY (source_record_id) COMMENT = 'Accepted care activity occurrences within contacts, one per submission and activity identifier. Repeated monthly submissions remain separate. Activities are detail of contacts, not separate encounters.',
    clinical AS {{ ref('fct_csds_clinical_record') }}
        PRIMARY KEY (source_record_id) COMMENT = 'Retained clinical items: coded immunisations, referral and activity assessment responses, and procedures, findings and observations recorded on activities. Assessment rows are responses, not completed questionnaires.',
    referral_periods AS {{ ref('fct_csds_referral_period') }}
        PRIMARY KEY (referral_period_id) COMMENT = 'Referral state in each accepted submission. A referral is open at period end when received, not discharged, and at least one of its teams is still open. Select one reporting period for a snapshot count. Community referrals such as health visiting legitimately stay open for years.',
    caseload_referrals AS {{ ref('fct_csds_current_caseload_referral') }}
        PRIMARY KEY (referral_period_id) COMMENT = 'Open referrals in the dataset''s latest accepted month, including those awaiting a first attended contact. Providers whose latest submission is older are excluded, which does not mean discharge. Recorded caseload, not confirmed active treatment.',
    caseload_people AS {{ ref('fct_csds_current_caseload_person') }}
        PRIMARY KEY (caseload_person_provider_id) COMMENT = 'People with at least one open referral in the dataset''s latest month, one row per person and provider. Count distinct person_id across providers.',
    rtt AS {{ ref('fct_csds_referral_to_treatment_period') }}
        PRIMARY KEY (referral_to_treatment_period_id) COMMENT = 'Accepted referral-to-treatment and response clock records. The same clock repeats each month it is reported, so row counts are submitted evidence, not distinct clocks. The response-standard flag underpins the two-hour urgent community response measure; the view does not decide target compliance.',
    teams AS {{ ref('fct_csds_referral_service') }}
        PRIMARY KEY (source_record_id) COMMENT = 'Latest service or team relationship for each referral and local team. A referral can have several teams, each with its own closure or rejection.',
    demographics AS {{ ref('dim_csds_person_provider_period') }}
        PRIMARY KEY (person_provider_period_id) COMMENT = 'Demographics and residence reported for a person by a provider in a reporting period. Use for historical breakdowns through the declared relationships from referral periods and caseload. Differences between providers stay separate.',
    submissions AS {{ ref('dq_csds_provider_submission') }}
        PRIMARY KEY (provider_organisation_code, reporting_period_end_date) COMMENT = 'Submission dates and record counts for each provider and accepted reporting period. Check provider freshness before comparing activity or caseload. Several providers stopped submitting CSDS years ago.'
)

RELATIONSHIPS(
    referrals (person_id) REFERENCES people,
    contacts (person_id) REFERENCES people,
    activities (person_id) REFERENCES people,
    clinical (person_id) REFERENCES people,
    referral_periods (person_id) REFERENCES people,
    referral_periods (person_provider_period_id) REFERENCES demographics,
    caseload_referrals (person_id) REFERENCES people,
    caseload_referrals (person_provider_period_id) REFERENCES demographics,
    caseload_people (person_id) REFERENCES people,
    caseload_people (person_provider_period_id) REFERENCES demographics,
    rtt (person_id) REFERENCES people,
    teams (person_id) REFERENCES people
)

DIMENSIONS(
    people.person_id AS person_id COMMENT = 'CSDS person identifier for linking aggregate cohorts. Never return person identifiers in query results.',
    people.as_of_date AS as_of_date COMMENT = 'Latest accepted dataset reporting-period end, the observation date for current person measures. Not the run date.',
    people.person_gender AS person_stated_gender_name COMMENT = 'Latest reported person stated gender description.',
    people.person_ethnicity_group AS ethnicity_2001_broad_group COMMENT = 'Broad 2001 ethnic group from the latest patient record; null when unknown or unmatched.',
    people.person_residence_local_authority AS residence_local_authority_name COMMENT = 'Local authority of residence from the latest patient record. Describes current evidence, not residence at earlier care.',
    people.person_imd_2025_decile AS residence_imd_2025_decile COMMENT = 'IMD 2025 decile of the latest reported residence; 1 is most deprived.',
    people.is_on_current_caseload AS is_on_current_caseload COMMENT = 'True when the person has an open referral in the dataset latest month.',
    people.is_looked_after_child AS is_looked_after_child COMMENT = 'Latest reported looked-after-child indicator: Y true, N false, otherwise null. Null must not be treated as no.',
    referrals.referrals_provider_code AS provider_organisation_code COMMENT = 'Code of the provider reporting these referrals.',
    referrals.referrals_provider_name AS provider_organisation_name COMMENT = 'Name of the provider reporting these referrals.',
    referrals.referral_received_date AS referral_received_date COMMENT = 'Recorded referral received date. Use for intake trends.',
    referrals.referral_reason AS primary_reason_for_referral_name COMMENT = 'Primary reason for referral description; null when unmatched.',
    referrals.referral_priority AS priority_type_name COMMENT = 'Referral priority description.',
    referrals.referral_source AS source_of_referral_name COMMENT = 'Source of referral description.',
    referrals.referral_latest_access_state AS latest_recorded_access_state COMMENT = 'Access state at the referral''s own latest reported period: discharged, all teams closed or rejected, attended contact recorded, or no attended contact recorded.',
    referrals.is_referral_open_at_latest_period AS is_recorded_open_at_latest_period COMMENT = 'Open at the referral''s own latest reported period. Referrals from providers that stopped submitting stay open here; use caseload tables for current state.',
    contacts.contacts_provider_code AS provider_organisation_code COMMENT = 'Code of the provider reporting these contacts.',
    contacts.contacts_provider_name AS provider_organisation_name COMMENT = 'Name of the provider reporting these contacts.',
    contacts.contact_date AS care_contact_date COMMENT = 'Recorded contact date; the scheduled date for cancellations and non-attendance. Use for activity trends.',
    contacts.contact_attendance AS attendance_name COMMENT = 'Attendance description from the attended-or-did-not-attend field.',
    contacts.contact_mechanism AS consultation_mechanism_name COMMENT = 'Consultation mechanism, such as face to face, telephone or video.',
    contacts.contact_location_type AS activity_location_type_name COMMENT = 'Type of location where the contact took place.',
    contacts.contact_team_type AS service_or_team_type_name COMMENT = 'Delivering service or team type. Read with contact_team_type_basis.',
    contacts.contact_team_type_basis AS service_or_team_type_basis COMMENT = 'contact_team when the contact''s own team was found in its submission; referral_team_* when the referral''s single team type was used; unresolved otherwise.',
    contacts.is_attended AS is_attended COMMENT = 'Attendance code 5 or 6.',
    activities.activity_type AS activity_type_name COMMENT = 'Community care activity type description.',
    activities.activity_contact_date AS care_contact_date COMMENT = 'Date of the contact the activity belongs to; activities have no separate date.',
    clinical.clinical_record_type AS clinical_record_type COMMENT = 'immunisation, referral_assessment, activity_assessment, procedure, finding or observation.',
    clinical.clinical_code_system AS clinical_code_system COMMENT = 'Coding system of the submitted clinical code.',
    clinical.clinical_date AS clinical_date COMMENT = 'Recorded or inherited date of the clinical item; read clinical_time_basis in the source fact for how it was derived.',
    clinical.clinical_label_status AS clinical_label_status COMMENT = 'Whether the submitted code found a label. Reference availability is not clinical validity.',
    referral_periods.referral_period_end_date AS reporting_period_end_date COMMENT = 'Reporting period the state is evaluated at. Filter to one period for a snapshot.',
    referral_periods.referral_period_provider_code AS provider_organisation_code COMMENT = 'Provider reporting the referral in this period.',
    referral_periods.referral_period_access_state AS recorded_access_state COMMENT = 'Access state at period end.',
    referral_periods.referral_period_team_type AS service_or_team_type_name COMMENT = 'Team type when all the referral''s teams in that submission share one; null otherwise.',
    referral_periods.is_referral_open_at_period_end AS is_recorded_open_at_period_end COMMENT = 'Open at period end: received, not discharged, and at least one team still open.',
    caseload_referrals.caseload_provider_code AS provider_organisation_code COMMENT = 'Provider reporting the open referral.',
    caseload_referrals.caseload_team_type AS service_or_team_type_name COMMENT = 'Team type when all the referral''s teams share one; null otherwise.',
    caseload_referrals.caseload_contact_state AS recorded_caseload_contact_state COMMENT = 'Whether attendance was evidenced in the latest period, only earlier, or not at all.',
    caseload_people.caseload_people_provider_code AS provider_organisation_code COMMENT = 'Provider of the person''s open referrals.',
    rtt.rtt_measurement_type AS waiting_time_measurement_type_name COMMENT = 'Community-care waiting time measurement type description.',
    rtt.rtt_status AS rtt_status_name COMMENT = 'Referral-to-treatment period status description.',
    rtt.rtt_period_end_date AS reporting_period_end_date COMMENT = 'Reporting period carrying the clock record.',
    rtt.rtt_provider_code AS provider_organisation_code COMMENT = 'Provider reporting the clock.',
    teams.team_type AS service_type_name COMMENT = 'Service or team type of the relationship.',
    teams.team_provider_code AS provider_organisation_code COMMENT = 'Provider reporting the relationship.',
    demographics.demographics_gender AS person_stated_gender_name COMMENT = 'Person stated gender reported in that provider period.',
    demographics.demographics_ethnicity_group AS ethnicity_2001_broad_group COMMENT = 'Broad 2001 ethnic group reported in that provider period.',
    demographics.demographics_residence_local_authority AS residence_local_authority_name COMMENT = 'Local authority of residence reported in that provider period.',
    demographics.demographics_imd_2025_decile AS residence_imd_2025_decile COMMENT = 'IMD 2025 decile of the residence reported in that period; 1 is most deprived.',
    demographics.demographics_age AS source_age_at_period_end COMMENT = 'Source-derived age in years at the period end.',
    submissions.submission_provider_code AS provider_organisation_code COMMENT = 'Provider organisation code.',
    submissions.submission_provider_name AS provider_organisation_name COMMENT = 'Provider organisation name.',
    submissions.submission_period_end_date AS reporting_period_end_date COMMENT = 'Accepted reporting period.',
    submissions.is_latest_provider_period AS is_latest_provider_period COMMENT = 'True on each provider''s latest accepted period.',
    submissions.provider_months_behind_dataset AS provider_months_behind_dataset COMMENT = 'Months between the provider''s latest period and the dataset''s latest period.'
)

METRICS(
    people.person_count AS COUNT(people.person_id) COMMENT = 'Identifiable CSDS person IDs in all modelled evidence. One individual can have several national IDs over time.',
    people.current_caseload_person_count AS COUNT_IF(people.is_on_current_caseload) COMMENT = 'People with an open referral in the dataset latest month, counted once across providers.',
    referrals.referral_count AS COUNT(referrals.source_record_id) COMMENT = 'Latest recorded referrals, including those without a person ID. Use referral_periods for historical state.',
    referrals.referral_person_count AS COUNT(DISTINCT referrals.person_id) COMMENT = 'Distinct person IDs across the selected referrals. Do not add distinct counts across groups.',
    referrals.mean_days_to_first_attended_contact AS AVG(referrals.days_to_first_attended_contact) COMMENT = 'Average days from receipt to first attended contact among referrals with a valid observed interval. Not the average wait of everyone referred.',
    referrals.referrals_with_observed_first_attendance AS COUNT(referrals.days_to_first_attended_contact) COMMENT = 'Referrals with a valid receipt-to-first-attendance interval, the denominator of the mean.',
    contacts.contact_count AS COUNT(contacts.source_record_id) COMMENT = 'Latest referral/contact pairs in all attendance states. Use attended_contact_count for delivered care.',
    contacts.attended_contact_count AS COUNT_IF(contacts.is_attended) COMMENT = 'Contacts with attendance code 5 or 6.',
    contacts.dna_contact_count AS COUNT_IF(contacts.is_dna) COMMENT = 'Contacts with code 3 (did not attend) or 7 (arrived late, not seen).',
    contacts.cancelled_contact_count AS COUNT_IF(contacts.is_cancelled) COMMENT = 'Contacts cancelled by the patient (2) or provider (4). Their date is the scheduled date.',
    contacts.contact_person_count AS COUNT(DISTINCT contacts.person_id) COMMENT = 'Distinct person IDs in the selected contacts. Do not add monthly or team-level distinct counts.',
    activities.care_activity_count AS COUNT(activities.source_record_id) COMMENT = 'Accepted activity occurrences; repeated monthly submissions of one activity count separately.',
    clinical.clinical_record_count AS COUNT(clinical.source_record_id) COMMENT = 'Retained clinical items. Filter clinical_record_type; assessment rows are responses, not questionnaires.',
    referral_periods.referral_period_count AS COUNT(referral_periods.referral_period_id) COMMENT = 'Referral/submission snapshots. The same referral appears each month; select one period for a snapshot.',
    referral_periods.open_referral_period_count AS COUNT_IF(referral_periods.is_recorded_open_at_period_end) COMMENT = 'Referral snapshots open at their period end. Select one reporting period.',
    caseload_referrals.current_caseload_referral_count AS COUNT(caseload_referrals.referral_period_id) COMMENT = 'Open referrals in the dataset latest month, including those without attendance or person ID.',
    caseload_referrals.current_caseload_without_attendance_count AS COUNT_IF(caseload_referrals.is_open_without_recorded_attendance) COMMENT = 'Open referrals in the latest month with no attended contact evidenced. Evidence of waiting, not waiting-list eligibility.',
    caseload_people.current_caseload_person_provider_count AS COUNT(caseload_people.caseload_person_provider_id) COMMENT = 'Person/provider combinations with an open referral in the latest month. A person at two providers counts twice.',
    caseload_people.caseload_distinct_person_count AS COUNT(DISTINCT caseload_people.person_id) COMMENT = 'Distinct people with an open referral in the latest month across the selected providers.',
    rtt.rtt_evidence_count AS COUNT(rtt.referral_to_treatment_period_id) COMMENT = 'Accepted clock records, including repeated monthly evidence of one clock. Not distinct clocks.',
    rtt.response_standard_assessed_count AS COUNT(rtt.is_response_standard_met) COMMENT = 'Clock records where the source assessed the response standard.',
    rtt.response_standard_met_count AS COUNT_IF(rtt.is_response_standard_met) COMMENT = 'Clock records flagged as meeting the response standard. Divide by response_standard_assessed_count within one period; repeated records are counted each month.',
    teams.service_team_relationship_count AS COUNT(teams.source_record_id) COMMENT = 'Latest referral/team relationships. A referral can have several.',
    demographics.person_provider_period_count AS COUNT(demographics.person_provider_period_id) COMMENT = 'Person/provider/period snapshots; not a distinct-person headcount.',
    submissions.accepted_submission_count AS SUM(submissions.n_accepted_submissions) COMMENT = 'Accepted files across the selected provider periods.',
    submissions.submitted_contact_row_count AS SUM(submissions.n_contact_source_records) COMMENT = 'Contact source rows across selected submissions, before latest-version selection. Reporting month is not contact month.'
)

COMMENT = 'CSDS community services referrals, contacts, activities, clinical records, recorded caseload and provider submission freshness. Choose the entity matching the question; each has its own row meaning and date basis. Measures describe this extract, not all lifetime care or live operational state. Currency costing is outside this view.'
AI_SQL_GENERATION 'Return non-identifying aggregates only; never select person or patient identifiers. For current recorded caseload use caseload_referrals or caseload_people, which hold only the dataset latest month. For historical open referrals use referral_periods and filter one reporting period. Use contact_date for contact activity and is_attended for delivered care. For period demographics use only the declared relationships from referral_periods, caseload_referrals or caseload_people to demographics; people dimensions describe current evidence. Filtering on people attributes restricts results to identifiable people. Aggregate each fact to the intended person or referral grain before combining facts; joining several contacts to several clinical records multiplies rows. Check submissions for provider freshness before comparing providers, because several stopped submitting years ago. RTT rows repeat monthly; for the two-hour response standard divide response_standard_met_count by response_standard_assessed_count within one reporting period. Open referrals and RTT records do not establish national waiting-list eligibility or target compliance. Assessment rows are responses, not completed questionnaires.'
AI_QUESTION_CATEGORIZATION 'Use this view for aggregate questions about CSDS community referrals and first recorded attendance, monthly recorded caseload, contacts by attendance, team type and location, care activities, immunisations and assessments, response-time clocks and provider submission freshness. Cost questions need the separate currency models. The view cannot establish live caseload, national waiting-time compliance or clinical outcomes.'
