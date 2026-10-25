{{ config(tags=['reconciliation']) }}

-- Every mapped product in the agreed chapters must be available to the count.
select bnf.snomed_code
from {{ ref('stg_reference_bnf_latest') }} bnf
left join {{ ref('int_polypharmacy_medications_list') }} scope
    on bnf.snomed_code = scope.snomed_code
where bnf.snomed_code is not null
    and length(bnf.bnf_code) >= 9
    and left(bnf.bnf_code, 2) in ('01', '02', '03', '04', '06', '07', '08', '09', '10')
    and scope.snomed_code is null
