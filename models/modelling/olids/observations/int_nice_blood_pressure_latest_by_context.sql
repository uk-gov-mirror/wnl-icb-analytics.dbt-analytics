{{ config(materialized='table', cluster_by=['person_id']) }}

{{ calculate_nice_blood_pressure_latest_by_context('current') }}
