select
    s.cyp104_unique_id as referral_to_treatment_period_id
    , s.cyp104_unique_id as source_row_id
    , s.person_id
    , b.sk_patient_id
    , s.unique_service_request_identifier as referral_source_record_id
    , s.waiting_time_measurement_type_community_care as waiting_time_measurement_type_code
    , measure_label.description as waiting_time_measurement_type_name
    , s.referral_to_treatment_period_start_date::date as rtt_start_date
    , s.referral_to_treatment_period_start_time::time as rtt_start_time
    , s.referral_to_treatment_period_end_date::date as rtt_end_date
    , s.referral_to_treatment_period_end_time::time as rtt_end_time
    , s.referral_to_treatment_period_status as rtt_status_code
    , status.rtt_period_status_description as rtt_status_name
    , status.rtt_period_status_category as rtt_status_category
    , s.derived_waiting_time as source_waiting_time_minutes
    , s.derived_waiting_time_night as source_waiting_time_overnight_days
    , case upper(trim(s.response_standard_met))
        when 'Y' then true
        when 'N' then false
    end as is_response_standard_met
    , iff(rtt_end_date >= rtt_start_date, datediff(day, rtt_start_date, rtt_end_date), null)
        as recorded_rtt_interval_days
    , rtt_start_date <= s.reporting_period_end_date::date
        and (rtt_end_date is null or rtt_end_date > s.reporting_period_end_date::date)
        as is_recorded_open_at_period_end
    , s.organisation_code_provider as provider_organisation_code
    , provider.organisation_name as provider_organisation_name
    , s.unique_submission_id as submission_id
    , s.reporting_period_start_date::date as reporting_period_start_date
    , s.reporting_period_end_date::date as reporting_period_end_date
    , s.effective_from as source_file_received_at
from {{ ref('stg_csds_referral_to_treatment_history') }} as s
left join {{ ref('stg_csds_bridging') }} as b on s.person_id = b.person_id
left join {{ ref('organisation') }} as provider
    on upper(trim(s.organisation_code_provider)) = provider.organisation_code
left join {{ ref('csds_referral_code_lookup') }} as measure_label
    on measure_label.code_set_name = 'waiting_time_measurement_type'
    and trim(s.waiting_time_measurement_type_community_care) = measure_label.code
left join {{ ref('stg_dictionary_dbo_rttperiodstatus') }} as status
    on trim(s.referral_to_treatment_period_status) = status.rtt_period_status_code
