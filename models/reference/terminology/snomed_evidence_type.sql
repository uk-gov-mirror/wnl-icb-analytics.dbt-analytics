with codes as (
    select code as snomed_code, min(code_description) as code_description
    from {{ ref('stg_reference_combined_codesets') }}
    where upper(cluster_id) in (
        'DM_DIET_REVIEW_COD', 'NUTRIASS_COD',
        'NHSD_PRIMARY_CARE_DOMAIN_REFSETS/DIETITIAN_COD',
        'SMI_LONGER_LIVES_MEDICINES_REVIEW', 'SMI_LONGER_LIVES_WEIGHT_MANAGEMENT',
        'EXERCISEINT_COD', 'WTMGINT_COD', 'WTMGINTDEC_COD',
        'SMI_LONGER_LIVES_DENTAL', 'ORALHEALTHREV_COD', 'ORALHEALTHINT_COD', 'ECOG_COD'
    )
    group by code
), context as (
    select r.source_id::varchar as snomed_code,
        max(iff(r.type_id = 408730004, r.destination_id::varchar, null)) as procedure_context,
        count(distinct iff(r.type_id = 408730004, r.destination_id, null)) as procedure_context_count,
        boolor_agg(r.type_id = 408732007 and r.destination_id <> 410604004) as other_subject,
        boolor_agg(r.type_id = 408731000 and r.destination_id not in (410511007, 410512000, 410513005)) as non_actual_time
    from {{ ref('stg_nhsd_snomed_sct_relationship') }} as r
    inner join codes on r.source_id::varchar = codes.snomed_code
    where r.active and r.characteristic_type_id = 900000000000011006
        and r.type_id in (408730004, 408731000, 408732007)
    group by r.source_id
), terms as (
    select codes.snomed_code,
        coalesce(c.fully_specified_name, codes.code_description) as concept_name,
        lower(coalesce(c.fully_specified_name, codes.code_description)) as wording,
        regexp_substr(c.fully_specified_name, '\\(([^()]*)\\)$', 1, 1, 'e', 1) as semantic_tag,
        context.procedure_context, context.procedure_context_count,
        coalesce(context.other_subject, false) as other_subject,
        coalesce(context.non_actual_time, false) as non_actual_time
    from codes
    left join {{ ref('snomed_concept') }} as c using (snomed_code)
    left join context using (snomed_code)
), classified as (
    select *, wording like '%offered%' as is_offer,
        case
            when other_subject or non_actual_time or procedure_context_count > 1 then null
            when procedure_context not in ('443390004', '385644000', '385658003', '385652002') then null
            when regexp_like(wording, '.*(not done|not performed|cancelled|canceled|not indicated|contraindicat).*') then null
            when procedure_context = '443390004' or regexp_like(wording, '.*(declined|refused).*') then 'declined'
            when regexp_like(wording, '.*(invitation|invited|labeling amended|labelling amended|synchronization|synchronisation).*') then 'administrative'
            when regexp_like(wording, '.*(offered|requested|awaited|planned|referral|referred|refer to).*')
                or procedure_context in ('385644000') then 'requested_or_referred'
            when regexp_like(wording, '.*(advi[cs]|education|educated|counsel|recommendation|discuss|leaflet|written information|signpost|health promotion).*') then 'advised'
            when procedure_context in ('385658003', '385652002') then 'completed'
            when regexp_like(wording, '.*(seen by|seen in|has seen|completed| done|commenced| started).*') then 'completed'
            when semantic_tag in ('procedure', 'regime/therapy') then 'completed'
            when semantic_tag in ('finding', 'observable entity', 'disorder') then 'finding'
            -- Historical UK descriptions can omit the semantic tag.
            when semantic_tag is null and wording like '%diabetic dietary review%' then 'completed'
        end as evidence_type
    from terms
)
select snomed_code, concept_name, semantic_tag, evidence_type, is_offer,
    case
        when evidence_type is null then 'Requires review: missing, conflicting or unsupported context'
        when procedure_context = '443390004' then 'SNOMED procedure context: declined'
        when evidence_type in ('administrative', 'requested_or_referred', 'advised') then 'SNOMED context and activity wording'
        when evidence_type = 'finding' then 'SNOMED semantic tag: finding or observable'
        when procedure_context in ('385658003', '385652002') then 'SNOMED procedure context: done or started'
        when semantic_tag in ('procedure', 'regime/therapy') then 'SNOMED default procedure context: completed'
        else 'Explicit attendance or completion wording'
    end as classification_basis
from classified
