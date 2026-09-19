# MHSDS analytical coverage review

Reviewed on 19 September 2026 against accepted evidence through July 2026.
All profiling uses non-identifying aggregate results.

## Structure and analyst questions

The reporting families now cover referrals, activity, inpatient care, clinical
evidence, circumstances, people and data quality. Currencies remain separate.
Shared selection and interpretation belong in modelling; analyst-facing facts
have explicit entity or period grains. These folders retain the existing
warehouse schemas and schedules.

The person summary is an entry point for current evidence and cohorts. Temporal
facts answer what was recorded during a particular period. Mixing those jobs in
one profile would obscure changing demographics, referral states and service
relationships.

The review's additions are implemented:

| Analyst question | Reporting provision |
|---|---|
| Who receives care? | Person/provider/period demographics with ethnicity, separate legacy gender and gender identity, source ages, residence and fixed-edition deprivation. |
| What demand and waiting evidence existed each month? | Referral-period access state, same-period team relationships and submitted RTT clocks. Attendance never uses later-period evidence. |
| Who is on the current recorded caseload? | Open referrals and person/provider counts in the dataset latest month. Older provider evidence remains separately available with its age. |
| What work is absent from contact totals? | Indirect activity, anonymous group sessions and drop-ins, plus identifiable group-therapy contacts as a subset of contacts. |
| Why are people remaining in hospital? | Discharge-readiness/reason periods, separate leave periods and commissioner assignments. Existing inferred occupancy is unchanged. |
| What needs and plans were recorded? | Accommodation, employment, disability, social circumstances, care-plan snapshots, agreements and presenting complaints. |
| How did recorded scores change? | Historical clustering responses, assessment response groups and descriptive paired numeric observations within the same concept and context. |
| What legal restrictions and restrictive interventions occurred? | CTO periods, recalls, restrictive incidents and intervention types. |
| What inpatient capacity is reported? | Ward available/closed bed days and same-submission recorded ward-stay midnights, with missingness and overlap flags. |

The semantic view exposes these entities without combining different grains into
a generic activity total. `fct_mhsds_contact_activity_monthly` now states its
contact-only scope. Shared contact models moved into `modelling/mental_health/activity`
and clinical transformations into `modelling/mental_health/clinical`.

## What profiling changed

- Historical clustering contained 133,518,587 accepted response rows. Source
  assessment/concept identity reduces these to 9,829,795 retained responses.
  Every retained response has a same-submission parent with matching person
  evidence. Changed national person IDs across versions remain flagged.
- All 1,524,789 care-plan agreements link to a same-submission plan with matching
  person evidence. Indirect activity also has no conflicting same-submission
  referral identities; a small number of parents are absent.
- Of 20,805,298 referral-period rows, 20,803,947 link to period demographics.
  Missing demographics preserve the referral rather than shrinking the population.
- Latest-provider open-referral evidence includes 71,593 referrals from periods
  more than two months behind the dataset. The current caseload therefore uses
  the dataset latest month, with older provider evidence in a separate model.
- July 2026 has 651 reported ward-periods; 347 contain available bed days.
  Capacity coverage is insufficient for a blanket provider utilisation claim.
  The commissioning extract can omit patients while capacity covers a whole ward.
- Four entirely empty reporting fields were removed: drop-in end time and
  receiving organisation, RTT pathway identifier, and the restrictive-type ward
  stay identifier. Their source interfaces retain the evidence.
- Employment needs both the general employment code list and the mental-health
  extension. Together they label 11,578,627 of 11,578,686 records. The remaining
  codes have no authoritative match and remain explicitly unmatched.
- Accommodation type contains legacy accommodation-status codes. The historical
  reference labels 4,393,609 more records, with the reference basis exposed.
  Missing and unmatched codes remain distinct.
- Presenting complaints now use the existing Read v2/CTV3 reference when declared.
  This adds 5,537 labels, giving 37,668 labelled records out of 47,703 retained
  complaints. All 15,563 records declaring Read v2 also match ICD-10; a small
  number declare a scheme outside the finding code list. Alternative labels
  expose possible source namespace errors without silently changing the scheme.
  Code overlap alone does not establish which interpretation is correct.

Earlier profiling also corrected contact team attribution. Explicit local team
pointers take precedence; v6 contacts without one use the same-submission primary
referral team. Source-derived identifiers alone do not prove a submitted pointer.
National person-ID changes do not automatically invalidate historical referral
attendance.

## Boundaries that remain

Eddie Davison owns the recorded-state and descriptive measure definitions.
The source supports open referral state and recorded attendance. It does not
make every open referral a clinically active treatment episode or establish all
national waiting-list eligibility rules.

Assessment groups are not confirmed completed questionnaires. Numeric response
validation uses the maintained published definitions, and score differences
remain specific to the concept. Clinical improvement and reliable change need
instrument-specific interpretation. Historical responses without a matching
definition remain visible and do not silently become scores.

Anonymous MHS301 sessions have no patient link. Identifiable group therapy appears
in MHS201, but those contacts have no shared session identifier. The patient view
cannot reconstruct definitive session membership by matching date or location.

Recorded stay midnights include leave and may contain overlapping intervals.
Their comparison with reported staffed capacity is descriptive, not live bed
availability or a validated physical occupancy rate. Discharge-readiness end
dates do not necessarily mean discharge.

Other source sections, including self-harm, assaults, police assistance and
digital interventions, still need their own source and analytical review. External
population denominators are also needed for population access rates. The
implemented models answer the agreed expansion; they do not claim complete
coverage of every MHSDS section.

The [domain guide](mhsds-domain-models.md) lists the models, definitions and joins.

## Validation

The downstream DEV build processed 136 models, 403 tests and two configured
snapshots. All MHSDS tests passed. The one failing check compares annual
segmentation with current demographics. Its existing monthly population spine
has 792 fewer current people and 1,432 people no longer in current demographics,
a net row-count difference of 640. Those population inputs are independent of
the MHSDS refactor; the mismatch remains for the segmentation refresh workflow.

The subsequent label fixes built 21 models and passed all 59 selected tests,
including complaint Read labels, employment reference coverage and semantic
entity-count reconciliation. Final complaint identity and ward overlap checks
built 13 models and passed 37 tests. The final person-evidence build passed all
eight tests across three models. Semantic breakdowns by period demographics
preserve referral, caseload, indirect-activity and care-plan totals. Profiling
returned aggregates only.
