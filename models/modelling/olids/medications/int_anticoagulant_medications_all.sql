{{
    config(
        materialized='table',
        cluster_by=['person_id', 'order_date'])
}}

/*
All oral anticoagulant medication orders for thrombosis prevention and atrial fibrillation management.
Uses national DOAC and VKA lists, with named oral anticoagulant BNF chemicals for unmatched codes.
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
),

selected_orders AS (
    SELECT mo.*, lm.is_national_doac, lm.is_national_vka
    FROM {{ ref('stg_olids_medication_order') }} mo
    INNER JOIN national_membership lm ON mo.mapped_concept_code = lm.code
    WHERE mo.clinical_effective_date IS NOT NULL

    UNION ALL

    SELECT mo.*, lm.is_national_doac, lm.is_national_vka
    FROM {{ ref('stg_olids_medication_order') }} mo
    LEFT JOIN national_membership lm ON mo.mapped_concept_code = lm.code
    WHERE mo.clinical_effective_date IS NOT NULL
        AND mo.bnf_chapter = '02'
        AND left(mo.bnf_code, 9) IN (
            '0208020Z0', '0208020X0', '0208020Y0', '0208020AA',
            '0208020V0', '0208020H0', '0208020N0', '0208020S0')
        -- Keep the branches disjoint without restricting nationally listed orders to BNF 020802.
        AND lm.code IS NULL
)

SELECT
    person_id,
    id AS medication_order_id,
    medication_statement_id,
    clinical_effective_date AS order_date,
    medication_name AS order_medication_name,
    dose AS order_dose,
    quantity_value AS order_quantity_value,
    quantity_unit AS order_quantity_unit,
    duration_days AS order_duration_days,
    statement_medication_name,
    mapped_concept_code,
    mapped_concept_display,
    bnf_code,
    bnf_name,

    CASE WHEN is_national_doac THEN 'DOAC'
         WHEN is_national_vka THEN 'VKA'
         WHEN left(bnf_code, 9) IN ('0208020Z0', '0208020X0', '0208020Y0', '0208020AA') THEN 'DOAC'
         WHEN left(bnf_code, 9) IN ('0208020V0', '0208020H0', '0208020N0', '0208020S0') THEN 'VKA'
    END::varchar(19) AS anticoagulant_type,
    anticoagulant_type = 'DOAC' AS is_doac,
    anticoagulant_type = 'VKA' AS is_vka,

    -- Order recency flags (anticoagulants are typically long-term therapy)
    {{ medication_date_flags('order_date') }},
    coalesce(is_national_doac OR is_national_vka, false) AS is_in_national_anticoagulant_list,
    CASE WHEN is_national_doac THEN 'DOAC'
         WHEN is_national_vka THEN 'VKA' END AS anticoagulant_type_national

-- Retain unmatched packs such as rivaroxaban suspension and list omissions such as phenprocoumon.
FROM selected_orders
ORDER BY person_id, order_date DESC
