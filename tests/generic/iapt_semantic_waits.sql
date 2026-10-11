{% test iapt_semantic_waits(model) %}

-- NHS England waits use supplied referral dates; local chain waits contribute once under the original provider.
{% for chain in [false, true] %}
{% set metric_prefix = 'pathway_' if chain else '' %}
{% set date_field = 'pathway_first_treatment_date' if chain else 'first_treatment_date' %}
{% set month_dimension = 'pathway_first_treatment_month' if chain else 'referral_first_treatment_month' %}
select '{{ 'pathway' if chain else 'nhse' }}' as measure_population, count(*) as failing_provider_month_count
from (
    select
        provider_organisation_code
        , date_trunc('month', {{ date_field }}) as first_treatment_month
        , count(datediff(day, referral_received_date, {{ date_field }})) as first_treatment_count
        , count_if(datediff(day, referral_received_date, {{ date_field }}) <= 42) as within_6_weeks_count
        , count_if(datediff(day, referral_received_date, {{ date_field }}) <= 126) as within_18_weeks_count
        , median(datediff(day, referral_received_date, {{ date_field }})) as median_days
    from {{ ref('fct_iapt_referral_summary') }}
    where {{ 'referral_id = original_referral_id' if chain else 'is_nhse_use_pathway' }}
    group by provider_organisation_code, date_trunc('month', {{ date_field }})
) as e
full outer join (
    select *
    from semantic_view(
        {{ model }}
        metrics referrals.{{ metric_prefix }}first_treatment_count,
            referrals.{{ metric_prefix }}first_treatment_within_6_weeks_count,
            referrals.{{ metric_prefix }}first_treatment_within_18_weeks_count,
            referrals.{{ metric_prefix }}median_days_to_first_treatment
        dimensions referrals.referrals_provider_code, referrals.{{ month_dimension }}
            {% if not chain %}, referrals.referrals_is_nhse_use_pathway{% endif %}
    )
    {% if not chain %}where referrals_is_nhse_use_pathway{% endif %}
) as a
    on e.provider_organisation_code is not distinct from a.referrals_provider_code
    and e.first_treatment_month is not distinct from a.{{ month_dimension }}
where coalesce(e.first_treatment_count, 0) <> coalesce(a.{{ metric_prefix }}first_treatment_count, 0)
    or coalesce(e.within_6_weeks_count, 0) <> coalesce(a.{{ metric_prefix }}first_treatment_within_6_weeks_count, 0)
    or coalesce(e.within_18_weeks_count, 0) <> coalesce(a.{{ metric_prefix }}first_treatment_within_18_weeks_count, 0)
    or e.median_days is distinct from a.{{ metric_prefix }}median_days_to_first_treatment
having count(*) > 0
{% if not loop.last %}union all{% endif %}
{% endfor %}

{% endtest %}
