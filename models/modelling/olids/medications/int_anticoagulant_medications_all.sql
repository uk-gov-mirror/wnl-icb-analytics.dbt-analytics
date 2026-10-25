{{
    config(
        materialized='table',
        cluster_by=['person_id', 'order_date'])
}}

/*
All oral anticoagulant medication orders for thrombosis prevention and atrial fibrillation management.
Uses national DOAC and VKA lists, with named oral anticoagulant BNF exceptions for list gaps.
Includes ALL persons (active, inactive, deceased) following intermediate layer principles.
*/

WITH national_membership AS (
    SELECT code,
        BOOLOR_AGG(cluster_id = 'NHS_DRUG_REFSETS/DIRECTORANTICOAGDRUG_COD') AS is_national_doac,
        BOOLOR_AGG(cluster_id = 'NHS_DRUG_REFSETS/VITKANTAGDRUG_COD') AS is_national_vka
    FROM {{ ref('stg_reference_combined_codesets') }}
    WHERE source = 'OPENCODELISTS'
        AND cluster_id IN ('NHS_DRUG_REFSETS/DIRECTORANTICOAGDRUG_COD',
            'NHS_DRUG_REFSETS/VITKANTAGDRUG_COD')
    GROUP BY code
)

SELECT
    person_id,
    medication_order_id,
    medication_statement_id,
    order_date,
    order_medication_name,
    order_dose,
    order_quantity_value,
    order_quantity_unit,
    order_duration_days,
    statement_medication_name,
    mapped_concept_code,
    mapped_concept_display,
    bnf_code,
    bnf_name,

    CASE WHEN lm.is_national_doac THEN 'DOAC'
         WHEN lm.is_national_vka THEN 'VKA' END::varchar(19) AS anticoagulant_type,
    coalesce(lm.is_national_doac, false) AS is_doac,
    coalesce(lm.is_national_vka, false) AS is_vka,

    -- Order recency flags (anticoagulants are typically long-term therapy)
    {{ medication_date_flags('order_date') }},
    coalesce(lm.is_national_doac OR lm.is_national_vka, false) AS is_in_national_anticoagulant_list,
    CASE WHEN lm.is_national_doac THEN 'DOAC'
         WHEN lm.is_national_vka THEN 'VKA' END AS anticoagulant_type_national

FROM (
    SELECT person_id, id AS medication_order_id, medication_statement_id,
        clinical_effective_date AS order_date, medication_name AS order_medication_name,
        dose AS order_dose, quantity_value AS order_quantity_value,
        quantity_unit AS order_quantity_unit, duration_days AS order_duration_days,
        statement_medication_name, mapped_concept_code, mapped_concept_display, bnf_code, bnf_name
    FROM {{ ref('stg_olids_medication_order') }}
    WHERE clinical_effective_date IS NOT NULL
) base_orders
LEFT JOIN national_membership lm ON base_orders.mapped_concept_code = lm.code
WHERE coalesce(lm.is_national_doac OR lm.is_national_vka, false)
    -- Keep genuine oral anticoagulants when national product lists are incomplete.
    -- Rivaroxaban suspension and phenprocoumon currently have recorded list gaps.
    OR left(base_orders.bnf_code, 9) IN (
        '0208020Z0', '0208020X0', '0208020Y0', '0208020AA',
        '0208020V0', '0208020H0', '0208020N0', '0208020S0')
ORDER BY person_id, order_date DESC
