{% test iapt_semantic_waits(model) %}

-- Repeated chain dates must contribute only once, under the original referral's provider.
with expected as (
    select
        provider_organisation_code
        , date_trunc('month', pathway_first_treatment_date) as first_treatment_month
        , count(days_referral_to_first_treatment) as first_treatment_count
        , count_if(is_first_treatment_within_6_weeks) as within_6_weeks_count
        , count_if(is_first_treatment_within_18_weeks) as within_18_weeks_count
        , median(days_referral_to_first_treatment) as median_days
    from {{ ref('fct_iapt_referral_summary') }}
    where referral_id = original_referral_id
    group by provider_organisation_code, date_trunc('month', pathway_first_treatment_date)
)

, actual as (
    select *
    from semantic_view(
        {{ model }}
        metrics referrals.first_treatment_count,
            referrals.first_treatment_within_6_weeks_count,
            referrals.first_treatment_within_18_weeks_count,
            referrals.median_days_to_first_treatment
        dimensions referrals.referrals_provider_code, referrals.referral_first_treatment_month
    )
)

select count(*) as failing_provider_month_count
from expected as e
full outer join actual as a
    on e.provider_organisation_code is not distinct from a.referrals_provider_code
    and e.first_treatment_month is not distinct from a.referral_first_treatment_month
where coalesce(e.first_treatment_count, 0) <> coalesce(a.first_treatment_count, 0)
    or coalesce(e.within_6_weeks_count, 0) <> coalesce(a.first_treatment_within_6_weeks_count, 0)
    or coalesce(e.within_18_weeks_count, 0) <> coalesce(a.first_treatment_within_18_weeks_count, 0)
    or e.median_days is distinct from a.median_days_to_first_treatment
having count(*) > 0

{% endtest %}
