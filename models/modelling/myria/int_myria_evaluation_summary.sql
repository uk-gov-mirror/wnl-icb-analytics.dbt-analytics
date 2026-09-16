{{
    config(
        materialized='table',
        tags=['myria_eval'])
}}

/*aggregates the patient-level data into annualised cohort-level cost and activity metrics, grouped by:
myria_status = cohort/group (e.g. treatment vs control),activity_status = pre vs post intervention 
So each row = one cohort × pre/post period
*/

select
    myria_status,
    activity_status,
    count(*) as patients,
    -- IP NON-ELECTIVE EMERGENCY STATS------------------------------------------------
    --ENCOUNTERS
    avg(ip_nel_emergency_encounters * annualisation_factor) as avg_ip_nel_emergency_encounters,
    stddev(ip_nel_emergency_encounters * annualisation_factor) as stddev_ip_nel_emergency_encounters,
    stddev(ip_nel_emergency_encounters * annualisation_factor) / sqrt(count(*)) as se_ip_nel_emergency_encounters,
    --COST
    avg(ip_nel_emergency_cost * annualisation_factor) as avg_ip_nel_emergency_cost,
    stddev(ip_nel_emergency_cost * annualisation_factor) as stddev_ip_nel_emergency_cost,
    stddev(ip_nel_emergency_cost * annualisation_factor) / sqrt(count(*)) as se_ip_nel_emergency_cost,
    --DURATION
    avg(ip_nel_emergency_duration * annualisation_factor) as avg_ip_nel_emergency_duration,
    stddev(ip_nel_emergency_duration * annualisation_factor) as stddev_ip_nel_emergency_duration,
    stddev(ip_nel_emergency_duration * annualisation_factor) / sqrt(count(*)) as se_ip_nel_emergency_duration,
    -- IP ELECTIVE STATS-----------------------------------------------
    --ENCOUNTERS
    avg(ip_elective_encounters * annualisation_factor) as avg_ip_elective_encounters,
    stddev(ip_elective_encounters * annualisation_factor) as stddev_ip_elective_encounters,
    stddev(ip_elective_encounters * annualisation_factor) / sqrt(count(*)) as se_ip_elective_encounters,
    --COST
    avg(ip_elective_cost * annualisation_factor) as avg_ip_elective_cost,
    stddev(ip_elective_cost * annualisation_factor) as stddev_ip_elective_cost,
    stddev(ip_elective_cost * annualisation_factor) / sqrt(count(*)) as se_ip_elective_cost,
    --DURATION
    avg(ip_elective_duration * annualisation_factor) as avg_ip_elective_duration,
    stddev(ip_elective_duration * annualisation_factor) as stddev_ip_elective_duration,
    stddev(ip_elective_duration * annualisation_factor) / sqrt(count(*)) as se_ip_elective_duration,
    -- A&E STATS-----------------------------------------------
    --ENCOUNTERS
    avg(ae_encounters * annualisation_factor) as avg_ae_encounters,
    stddev(ae_encounters * annualisation_factor) as stddev_ae_encounters,
    stddev(ae_encounters * annualisation_factor) / sqrt(count(*)) as se_ae_encounters,
    --COST
    avg(ae_cost * annualisation_factor) as avg_ae_cost,
    stddev(ae_cost * annualisation_factor) as stddev_ae_cost,
    stddev(ae_cost * annualisation_factor) / sqrt(count(*)) as se_ae_cost,
    -- OUTPATIENT STATS-----------------------------------------------
    --ENCOUNTERS
    avg(op_encounters * annualisation_factor) as avg_op_encounters,
    stddev(op_encounters * annualisation_factor) as stddev_op_encounters,
    stddev(op_encounters * annualisation_factor) / sqrt(count(*)) as se_op_encounters,
    --COST
    avg(op_cost * annualisation_factor) as avg_op_cost,
    stddev(op_cost * annualisation_factor) as stddev_op_cost,
    stddev(op_cost * annualisation_factor) / sqrt(count(*)) as se_op_cost,
    -- GP STATS-----------------------------------------------
    --ENCOUNTERS
    avg(gp_encounters * annualisation_factor) as avg_gp_encounters,
    stddev(gp_encounters * annualisation_factor) as stddev_gp_encounters,
    stddev(gp_encounters * annualisation_factor) / sqrt(count(*)) as se_gp_encounters,
    --COST
    avg(gp_cost * annualisation_factor) as avg_gp_cost,
    stddev(gp_cost * annualisation_factor) as stddev_gp_cost,
    stddev(gp_cost * annualisation_factor) / sqrt(count(*)) as se_gp_cost,
    -- MORTALITY STATS-----------------------------------------------
    sum(death_flag) as patient_deaths,
    avg(death_flag) / max(n_years) as annualised_death_rate
from {{ ref("int_myria_evaluation") }} as m 
where n_days <> 0
group by 1, 2
order by 1, 2

