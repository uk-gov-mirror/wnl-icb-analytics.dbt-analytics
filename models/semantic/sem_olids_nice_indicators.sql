{{
    config(
        materialized='semantic_view',
        schema='SEMANTIC'
    )
}}

{#
    Grain: one row per person per NICE indicator on the reporting date.

    Cross-indicator status view over fct_person_nice_indicator_status.
    A person can appear in more than one indicator, so filter or group by
    indicator_id before calculating a rate or comparing populations.
    Every row is already in the denominator; is_in_denominator is always
    TRUE and is not exposed as a dimension or filter.
    Denominators are before personalised care adjustments.
    Secondary-use opt-out filtering is a consumer concern; this view
    does not join opt-out models.
#}

TABLES(
    indicators AS {{ ref('fct_person_nice_indicator_status') }}
        PRIMARY KEY (person_id, indicator_id)
        COMMENT = 'Shared NICE indicator denominator and numerator status. One row per person per indicator on the reporting date; personalised care adjustments are not applied.',

    demographics AS {{ ref('dim_person_demographics') }}
        PRIMARY KEY (person_id)
        COMMENT = 'Current demographics, registration, geography and deprivation'
)

RELATIONSHIPS(
    indicators (person_id) REFERENCES demographics
)

FACTS(
    demographics.esp_weight AS esp_weight COMMENT = 'ESP 2013 weight for the persons age band out of 100,000',
    demographics.esp_proportion AS esp_proportion COMMENT = 'ESP 2013 weight as a proportion'
)

DIMENSIONS(
    -- Indicator and person grain
    indicators.person_id AS person_id COMMENT = 'Pseudonymised person key for aggregate-only linkage to other sem_olids_* views. Never return person_id in final results.',
    demographics.sk_patient_id AS sk_patient_id COMMENT = 'Representative pseudonymised patient key for aggregate-only linkage to non-OLIDS semantic views. Never return sk_patient_id in final results.',
    indicators.indicator_id AS indicator_id WITH SYNONYMS = ('NICE indicator', 'measure') COMMENT = 'NICE indicator identifier. Filter or group by this before using indicator metrics because a person can appear in more than one indicator.',
    indicators.indicator_name AS indicator_name COMMENT = 'Published NICE indicator name',
    indicators.reporting_date AS reporting_date WITH SYNONYMS = ('as at date', 'measure date') COMMENT = 'Date on which age and the measurement period were assessed',
    indicators.measurement_period_start AS measurement_period_start COMMENT = 'Inclusive start of the indicator measurement period; the length depends on the indicator',
    indicators.age AS age COMMENT = 'Age in years on the reporting date; null when no birth date is recorded',

    -- Shared status contract. is_in_denominator is always TRUE on these
    -- rows, so it is not a dimension or filter.
    indicators.is_in_numerator AS is_in_numerator COMMENT = 'Person meets the indicator on the reporting date',
    indicators.indicator_status AS indicator_status WITH SYNONYMS = ('achievement status', 'care gap reason') COMMENT = 'ACHIEVED when in the numerator; otherwise a documented reason token from the source status contract',

    -- Demographics
    demographics.gender AS gender COMMENT = 'Patient gender',
    demographics.age_band_5y AS age_band_5y COMMENT = '5-year age band',
    demographics.age_band_10y AS age_band_10y COMMENT = '10-year age band',
    demographics.age_band_nhs AS age_band_nhs COMMENT = 'NHS standard age band',
    demographics.age_band_esp AS age_band_esp COMMENT = 'ESP 2013 age band',
    demographics.ethnicity_category AS ethnicity_category COMMENT = 'Ethnicity category',
    demographics.ethnicity_subcategory AS ethnicity_subcategory COMMENT = 'Ethnicity subcategory',
    demographics.main_language AS main_language COMMENT = 'Main spoken language',
    demographics.interpreter_needed AS interpreter_needed COMMENT = 'Whether an interpreter is required',
    demographics.is_active AS is_active COMMENT = 'Currently registered; filter TRUE for current-population reporting',
    demographics.is_deceased AS is_deceased COMMENT = 'Deceased status',

    -- Organisation and geography
    demographics.registered_practice_code AS practice_code WITH SYNONYMS = ('practice code', 'ODS code', 'GP practice') COMMENT = 'ODS code of the registered GP practice',
    demographics.registered_practice_name AS practice_name COMMENT = 'Registered GP practice name',
    demographics.registered_pcn_code AS pcn_code COMMENT = 'Registered PCN code',
    demographics.registered_pcn_name AS pcn_name WITH SYNONYMS = ('PCN', 'primary care network') COMMENT = 'Registered PCN name',
    demographics.registered_pcn_name_with_borough AS pcn_name_with_borough COMMENT = 'Registered PCN name with borough prefix',
    demographics.borough_registered AS borough_registered COMMENT = 'Registration borough',
    demographics.sub_icb_code AS sub_icb_code COMMENT = 'Sub-ICB ODS code of the registered practice',
    demographics.sub_icb_name AS sub_icb_name COMMENT = 'Sub-ICB name of the registered practice',
    demographics.neighbourhood_registered AS neighbourhood_registered COMMENT = 'Registration neighbourhood',
    demographics.borough_resident AS borough_resident COMMENT = 'Residence borough',
    demographics.neighbourhood_resident AS neighbourhood_resident COMMENT = 'Residence neighbourhood',
    demographics.ward_name AS ward_name COMMENT = 'Electoral ward name',
    demographics.imd_decile_25 AS imd_decile_25 COMMENT = 'IMD 2025 decile, where 1 is most deprived',
    demographics.imd_quintile_25 AS imd_quintile_25 COMMENT = 'IMD 2025 quintile'
)

METRICS(
    indicators.denominator_count AS COUNT(DISTINCT indicators.person_id) COMMENT = 'People on the selected indicator rows. Every row is already an eligible denominator person; this does not filter is_in_denominator.',
    indicators.numerator_count AS COUNT(DISTINCT CASE WHEN indicators.is_in_numerator THEN indicators.person_id END) COMMENT = 'People achieving the selected indicator',
    indicators.care_gap_count AS COUNT(DISTINCT CASE WHEN NOT indicators.is_in_numerator THEN indicators.person_id END) COMMENT = 'People not achieving the selected indicator before personalised care adjustments',
    indicators.achievement_rate AS COUNT(DISTINCT CASE WHEN indicators.is_in_numerator THEN indicators.person_id END) / NULLIF(COUNT(DISTINCT indicators.person_id), 0) COMMENT = 'Unadjusted indicator achievement rate from 0 to 1'
)

COMMENT = 'OLIDS NICE Indicators Semantic View - shared achievement and care-gap status across NICE measures. Grain: one row per person per indicator on the reporting date. Every row is already in the denominator; do not filter is_in_denominator. Filter or group by indicator_id before rates because a person can appear in more than one indicator. Personalised care adjustments are not applied. Secondary-use consumers must apply National Data Opt-Out and Type 1 opt-out filtering themselves. Never return person_id or sk_patient_id.'
AI_SQL_GENERATION 'Filter indicator_id, or group by indicator_id, before using metrics because a person can appear in more than one indicator. Every row is already a denominator person; denominator_count is COUNT DISTINCT person_id after that selection, not a filter on is_in_denominator. Use AGG(achievement_rate), or AGG(numerator_count) / AGG(denominator_count), for the selected indicator. Group by indicator_status or is_in_numerator for achievement and care-gap reason breakdowns; do not invent status tokens. Filter is_active = TRUE for current-population reporting. Do not describe these as final QOF performance because personalised care adjustments are not applied. Secondary-use opt-out filtering is a consumer concern and is not applied in this view. Never return person_id or sk_patient_id in final results. Small-cell suppression is an application concern; do not return person-level rows. Example: SELECT indicator_id, borough_registered, AGG(denominator_count), AGG(numerator_count), AGG(achievement_rate) FROM SEM_OLIDS_NICE_INDICATORS WHERE is_active = TRUE GROUP BY indicator_id, borough_registered. LINKAGE: first filter to one indicator and reduce to one row per person before joining another semantic view on person_id; never return person_id in final results.'
AI_QUESTION_CATEGORIZATION 'Use this view for shared NICE indicator achievement, care-gap counts and inequalities by practice, PCN, geography, ethnicity or deprivation across the measures in fct_person_nice_indicator_status. For NICE IND239-246 blood pressure readings, thresholds and measurement context use sem_olids_bp_indicators. For diabetes care-process completion and triple targets use sem_olids_diabetes_care. For general latest BP values use sem_olids_observations.'
