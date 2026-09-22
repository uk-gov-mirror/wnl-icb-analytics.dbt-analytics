-- The newest CYP001 record for each person, provider and reporting period. A
-- provider can submit two local patient records for one person in a month;
-- both are counted and conflicting demographics flagged.
with ranked as (
    select
        m.*
        , count(*) over (
            partition by person_id, organisation_code_provider, reporting_period_end_date
        ) as n_source_patient_records
        , count(distinct hash(ethnic_category, person_stated_gender_code, ic_age_of_patient_at_rp_end,
            lower_super_output_area_residence, lower_super_output_area_residence_2011, person_death_date)) over (
            partition by person_id, organisation_code_provider, reporting_period_end_date
        ) > 1 as has_conflicting_demographic_records
    from {{ ref('stg_csds_mpi_history') }} as m
    where person_id is not null
    qualify row_number() over (
        partition by person_id, organisation_code_provider, reporting_period_end_date
        order by effective_from desc nulls last, unique_submission_id desc, cyp001_unique_id desc
    ) = 1
)

, lsoa_to_lad as (
    select lsoa21_cd, lad26_nm
    from {{ ref('stg_reference_geo_lsoa21_sicbl26_icb26_nhser26_lad26') }}
)

-- Some providers put retired 2011 codes in the 2021 LSOA field. Bridge them to
-- 2021 to find the local authority, which is stable across LSOA splits.
, lsoa11_to_lad as (
    select b.old_lsoa_code as lsoa11_cd, min(l.lad26_nm) as lad26_nm
    from {{ ref('stg_ukhfd_old_lsoa_to_new_lsoa_map') }} as b
    inner join lsoa_to_lad as l on b.new_lsoa_code = l.lsoa21_cd
    group by b.old_lsoa_code
)

select
    {{ dbt_utils.generate_surrogate_key(['m.person_id', 'm.organisation_code_provider', 'm.reporting_period_end_date::date']) }}
        as person_provider_period_id
    , m.person_id
    , b.sk_patient_id
    , m.organisation_code_provider as provider_organisation_code
    , provider.organisation_name as provider_organisation_name
    , m.reporting_period_start_date::date as reporting_period_start_date
    , m.reporting_period_end_date::date as reporting_period_end_date
    , m.ic_age_of_patient_at_rp_end as source_age_at_period_end
    , m.person_stated_gender_code
    , gender.description as person_stated_gender_name
    , m.ethnic_category as ethnicity_2001_code
    , ethnic.ethnicity_2001_detailed_description as ethnicity_2001_description
    , ethnic.ethnicity_2001_broad_group
    , m.lower_super_output_area_residence as residence_lsoa_2021_code
    , m.lower_super_output_area_residence_2011 as residence_lsoa_2011_code
    , coalesce(lad.lad26_nm, lad_2011.lad26_nm) as residence_local_authority_name
    , case
        when lad.lad26_nm is not null then 'lsoa_2021'
        when lad_2011.lad26_nm is not null then 'lsoa_2011_in_2021_field'
    end as residence_local_authority_basis
    , m.local_authority_district_unitary_authority as submitted_residence_local_authority_code
    , imd19.imddecile as residence_imd_2019_decile
    , imd25.index_of_multiple_deprivation_decile as residence_imd_2025_decile
    , m.organisation_identifier_icb_of_residence as residence_icb_code
    , residence_icb.organisation_name as residence_icb_name
    , m.organisation_identifier_sub_icb_location_of_residence as residence_sub_icb_code
    , residence_sub_icb.organisation_name as residence_sub_icb_name
    , m.person_death_date::date as person_death_date
    , case upper(trim(m.looked_after_child_indicator)) when 'Y' then true when 'N' then false end
        as is_looked_after_child
    , case upper(trim(m.safeguarding_vulnerability_factors_indicator)) when 'Y' then true when 'N' then false end
        as has_safeguarding_vulnerability_factors
    , m.n_source_patient_records
    , m.has_conflicting_demographic_records
    , m.cyp001_unique_id as source_row_id
    , m.unique_submission_id as submission_id
    , m.effective_from as source_file_received_at
from ranked as m
left join {{ ref('stg_csds_bridging') }} as b on m.person_id = b.person_id
left join {{ ref('organisation') }} as provider
    on upper(trim(m.organisation_code_provider)) = provider.organisation_code
left join {{ ref('mhsds_domain_code_lookup') }} as gender
    on gender.code_set_name = 'person_stated_gender' and trim(m.person_stated_gender_code) = gender.code
left join {{ ref('nhs_ethnicity_2001') }} as ethnic on trim(m.ethnic_category) = ethnic.ethnicity_2001_code
left join lsoa_to_lad as lad on m.lower_super_output_area_residence = lad.lsoa21_cd
left join lsoa11_to_lad as lad_2011 on m.lower_super_output_area_residence = lad_2011.lsoa11_cd
left join {{ ref('stg_reference_imd2019') }} as imd19 on m.lower_super_output_area_residence_2011 = imd19.lsoacode
left join {{ ref('stg_reference_imd2025') }} as imd25 on m.lower_super_output_area_residence = imd25.lsoa_code_2021
left join {{ ref('organisation') }} as residence_icb
    on upper(trim(m.organisation_identifier_icb_of_residence)) = residence_icb.organisation_code
left join {{ ref('organisation') }} as residence_sub_icb
    on upper(trim(m.organisation_identifier_sub_icb_location_of_residence)) = residence_sub_icb.organisation_code
