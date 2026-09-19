# MHSDS analytical coverage review

Reviewed on 19 September 2026 against the refactored models and accepted source
data through July 2026. Counts below are submitted rows, not distinct events or
people. They demonstrate available evidence, not completeness or validity.

## Judgement

Keep the reporting families: referrals, activity, inpatient, clinical, person,
quality and currencies. They give analysts recognisable subjects and explicit
grains. Modelling should continue to own shared interpretation, such as accepted
contact context, occupancy inference and clinical-item identity. Reporting can
read staging directly when the source already represents the required entity.
Moving every source-shaped fact into modelling would add indirection without
changing what analysts can answer.

The domain is useful but incomplete. Of 71 raw MHSDS models, 23 have a staging
consumer. This is an inventory, not a coverage percentage: the remainder includes
retired sections as well as populated sections with substantial analytical value.

## What works now

- Referral facts and summaries answer recorded demand, referral reasons,
  rejection/discharge, contact volumes and descriptive first-attendance waits.
- Contacts and activities distinguish attendance from the work recorded within
  a contact. Team attribution uses the contact's submission, with explicit
  provenance. Staff relationships retain their separate many-to-many grain.
- Recorded spells and wards support admissions and movements. Inferred
  occupancy is separate, with its existing recency and overlap rules visible.
- Diagnosis, assessment and legal-status facts retain evidence without claiming
  current clinical diagnoses, completed questionnaires or treatment outcomes.
- The person summary includes all modelled evidence families and does not require
  a cross-system bridge. Currency classifications remain separate.

The current summaries are reasonable analyst entry points. They should not
become substitutes for temporal facts or containers for every available field.

## Recommended next additions

| Priority and analyst question | Addition and grain | Evidence and remaining decision |
|---|---|---|
| 1. Who receives care, and who is missing it? | A person/provider/reporting-period demographic dimension, with labelled age, ethnicity, sex/gender fields and residence/deprivation context. Extend the existing MPI staging interface. | MPI already supplies these fields, but staging retains little demographic context. Keep conflicting provider submissions visible and define selection within a period. Do not require cross-system bridging or apply today's demographics to historical care. Population access rates also need an external denominator. |
| 2. What demand and waiting population did each service have each month? | A referral-period fact over accepted referral history and same-period team relationships. | The history is now available. Latest referrals alone cannot reconstruct previous monthly state. Define recorded open referrals separately from agreed active caseload and waiting-list populations; interpret MHS104 RTT clocks before publishing target compliance. July has 5,466 MHS104 rows. |
| 3. What work is absent from contact reporting? | An indirect-activity fact at the accepted activity occurrence grain, with duration, procedure, professional and same-submission team context. Separate group-session and drop-in facts. | July has 20,083 indirect-activity rows, 8,356 group-session rows and 5,765 drop-in rows. Indirect activity currently contributes only source-row counts to summaries. Establish event identity before deduplication, and distinguish session counts from participant contacts. |
| 4. Why are people remaining in hospital? | Discharge-readiness periods linked to recorded spells; leave periods as separate facts. Derive a period summary only after agreeing occupied-day and delayed-day rules. | July has 632 MHS518 readiness rows and 2,826 MHS510 leave rows. Existing inferred occupancy does not establish physical bed use or days delayed after readiness. Preserve the agreed occupancy rules while adding the underlying evidence. |
| 5. What needs, circumstances and care plans were recorded? | Dated circumstance, disability and care-plan facts, plus presenting-complaint evidence kept distinct from diagnoses. | July includes 117,134 accommodation rows, 159,556 employment rows, 34,427 disability rows, 126,007 care-plan-type rows and 44,764 presenting-complaint rows. These are repeated submitted evidence, not new events. Keep effective periods and unknown states visible instead of adding undated flags to the person summary. |
| 6. Did measured outcomes change? | Instrument-specific assessment instances and paired observations, retaining items, completeness and assessor context. | The current assessment fact provides responses and interpretable scores, not completed instruments. Older MHS802 clustering assessments contain 133.5 million accepted historical rows outside this family, with none in July. Establish their distinct observations before integration. Define completion, pairing, timing and score direction per instrument with an accountable clinical owner. |
| 7. What restrictions and safety events occurred? | Separate community-treatment-order periods, recall events, restrictive-intervention incidents and intervention types. | July has 1,232 CTO rows and 1,324 restrictive-intervention incident rows. An incident can have several intervention types. Legal-status periods alone do not cover this subject; shared incident/period identities and labels come before rates. |

Priorities 1 and 2 would most improve general analysis. Indirect activity is the
next practical extension. Discharge readiness is the strongest focused inpatient
addition. These recommendations are not implemented models or agreed clinical
measure definitions.

Commissioner analysis also needs period context: July has 2,804 MHS512 spell
commissioner-assignment rows. A single source-derived commissioner on the latest
spell cannot describe every change of responsibility during an admission.

## Structure to retain and tighten

Keep new temporal entities alongside their existing families. A small
`circumstances` family is justified when those models exist. Do not create an
empty folder hierarchy or another broad mental-health profile.

Within modelling, move shared contact context and latest-contact selection into
an `activity` folder, and clinical-item/diagnosis transformations into `clinical`
when those families next change. Keep shared organisation and reporting-date
helpers at the domain root. These are navigation improvements, not warehouse
schema changes or prerequisites for correct results.

`fct_mhsds_service_activity_monthly` currently measures contacts only. If indirect
activity or group reporting is added, rename it to
`fct_mhsds_contact_activity_monthly` and provide separately named activity
measures. Never add counts with different grains into a generic activity total.

Extend the semantic view after each new entity has tested keys and agreed
measures. Provider-period demographic relationships need temporal keys;
joining historical facts to the current person summary is insufficient.
Outcome, waiting-list and caseload measures need their own definitions, not
optimistic names over existing counts.

## What the profiling changes

The missing contact team type was partly our modelling omission. V6 primary
referral-team fallback addresses it without replacing explicit contact teams.
Person-ID differences across submissions require visible temporal context, not
automatic reassignment or exclusion. Person counts remain distinct recorded
MHSDS IDs; changing IDs can split one individual's history.

Missing durations, unmatched parents and bridge gaps remain visible. Most
unmatched assessment responses are outside the published numeric ranges. They
must not silently become scores. Unclassified legal-status evidence in this
profile has missing codes or the source sentinel; no additional detention rule
is justified by that finding.

The [domain guide](mhsds-domain-models.md) describes the implemented interfaces.
The [MHSDS v6 guidance](https://digital.nhs.uk/binaries/content/assets/website-assets/data-and-information/datasets/mhsds/tools-and-guidance/mhsdsv6.0_userguidance_v6.0.4.pdf)
describes the source sections and expected assessment values. Source presence
does not by itself settle analytical populations or clinical measure definitions.
