{{
    config(
        materialized='table',
        tags=['LAS', 'AMB'],
          )
}}


/*
Purpose:
Staging model for the London Ambulance Service dataset.

This model prepares the Ambulance source data (DATA_LAKE.SDL.AMB source table),
for downstream modelling and reporting.

Grain:
One row per ambulance incident.

Key Features:
• Retains all records from the source table
• Includes only columns required for downstream modelling and reporting
• Standardises column names to ICB snake-case naming convention
• Converts dates and timestamps to the correct data types.
• Removes unused columns.

Inclusion Criteria:
• All records from MASTER_AMB_DATA.

Known Limitations:
• Some fields are awaiting confirmation from the legacy reporting model.
*/

SELECT
    -------------------------------------------------------------------------
    -- Data Lake Metadata
    -------------------------------------------------------------------------
      DLP_FLEXOR_FREEZE                           AS dlp_flexor_freeze
    , DLP_COMMISSIONER_CODE                       AS dlp_commissioner_code
    , DLP_FINANCIAL_MONTH                         AS dlp_financial_month
    , DLP_FINANCIAL_YEAR                          AS dlp_financial_year
    , DLP_BASELINE_FINANCIAL_MONTH                AS dlp_baseline_financial_month

    -------------------------------------------------------------------------
    -- Incident Identifiers
    -------------------------------------------------------------------------
    , INCIDENT_ID                                AS incident_id
    , CAD_NUMBER                                 AS cad_number

    -------------------------------------------------------------------------
    -- Dates and Times
    -------------------------------------------------------------------------
    , DATE_VALUE                                 AS date_value
    , CALL_TIME                                  AS call_time
    , CLOCK_START_TIME                           AS clock_start_time
    , ARRIVE_ON_SCENE_FIRST_VEHICLE              AS arrive_on_scene_first_vehicle
    , ARRIVE_ON_SCENE_FIRST_TRANSPORTING_VEHICLE AS arrive_on_scene_first_transporting_vehicle
    , CONVEYING_DATETIME                         AS conveying_datetime
    , PRE_TRIAGED_QUESTIONS_TIME                 AS pre_triaged_questions_time

    -------------------------------------------------------------------------
    -- Geography & Organisation
    -------------------------------------------------------------------------
    , LOCALITY                                   AS locality
    , ICB                                        AS icb
    , CROSS_BORDER_FLAG                          AS cross_border_flag
    , DV_LSOA                                    AS dv_lsoa
    , DV_PARTIAL_POST_CODE                       AS dv_partial_post_code
    , DV_PARTIAL_POST_CODE_DESTINATION_POSTCODE  AS dv_partial_post_code_destination_postcode
    , DV_RECIPIENT_CODE                          AS dv_recipient_code
    , NHS_SITECODE                               AS nhs_sitecode
    , GP_LOCATION                                AS gp_location

    -------------------------------------------------------------------------
    -- Patient Demographics
    -------------------------------------------------------------------------
    , CALL_AGE                                   AS call_age
    , CALL_GENDER                                AS call_gender
    , SK_PATIENT_ID_NHS_NUMBER                   AS sk_patient_id_nhs_number
    , CARE_HOME_LOCATION_FLAG                    AS care_home_location_flag

    -------------------------------------------------------------------------
    -- Clinical Information
    -------------------------------------------------------------------------
    , DETERMINANT_CODE                           AS determinant_code
    , CHIEF_COMPLAINT_CODE                       AS chief_complaint_code
    , AMPDS_CODE_VERSION                         AS ampds_code_version
    , INCIDENT_CODE                              AS incident_code
    , ILLNESS_CODE_1                             AS illness_code_1
    , ILLNESS_CODE_2                             AS illness_code_2
    , ILLNESS_INCIDENT_CODE_VERSION              AS illness_incident_code_version
    , DO_H_CATEGORY                              AS do_h_category
    , FULL_DOH_CATEGORY                          AS full_doh_category
    , SUB_CATEGORY                               AS sub_category
    , CALL_HRG_CODE                              AS call_hrg_code
    , INCIDENT_HRG_CODE                          AS incident_hrg_code
    , HRG_VERSION_NUMBER                         AS hrg_version_number
    , PRE_TRIAGED_QUESTIONS                      AS pre_triaged_questions
    , ADDITIONAL_H_T                             AS additional_h_t

    -------------------------------------------------------------------------
    -- Operational Information
    -------------------------------------------------------------------------
    , CALL_TYPE                                  AS call_type
    , DESTINATION_REFERRAL_OUTCOME               AS destination_referral_outcome
    , MODE_OF_TRANSPORT_FLAG                     AS mode_of_transport_flag
    , MODE_OF_TRANSPORT_FIRST_RESPONDER          AS mode_of_transport_first_responder
    , CONVEYING_CREW_TYPE                        AS conveying_crew_type
    , FIRST_RESPONDER_CREW_TYPE                  AS first_responder_crew_type
    , DEPARTMENT_TYPE_FLAG                       AS department_type_flag
    , PRE_ALERT_BLUE_CALL_FLAG                   AS pre_alert_blue_call_flag
    , H_T_TAXI_FLAG                              AS h_t_taxi_flag
    , BASELINE_SETTING_INCLUSIONS                AS baseline_setting_inclusions

    -------------------------------------------------------------------------
    -- Mental Health / Specialist Pathways
    -------------------------------------------------------------------------
    , MH_CALLSIGN_S_T                            AS mh_callsign_s_t
    , MH_CALLSIGN_S_T_BASE                       AS mh_callsign_s_t_base
    , MH_CALLSIGN_S_C                            AS mh_callsign_s_c
    , CALLSIGN_MHTA                              AS callsign_mhta
    , MH_S136                                    AS mh_s136
    , CALLSIGN_UCR                               AS callsign_ucr
    , GREEN_TIME_S_T                             AS green_time_s_t
    , H_T_CLINICALLY_CLOSED                      AS h_t_clinically_closed

    -------------------------------------------------------------------------
    -- Outcome
    -------------------------------------------------------------------------
    , OUTCOME_DISPOSITION                        AS outcome_disposition
    , OUTCOME_DISPOSITION_CODE                   AS outcome_disposition_code
    , CONVEYANCE_GROUP_REVISED                   AS conveyance_group_revised

FROM {{ ref('raw_sdl_wnl_amb') }}
