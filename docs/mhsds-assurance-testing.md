# MHSDS assurance and testing

Use this guide to check whether the MHSDS layer supports an analytical question
and to record the evidence before using its results. Start with the
[analyst overview](mhsds-domain-overview.md) to choose a table and the
[reporting guide](mhsds-domain-models.md) for its definitions.

Document reviewed: 22 September 2026. The results below are historical evidence
from the September implementation, not a fresh validation of today's data.
Analyst acceptance remains to be recorded.

## What has been checked

[PR #1218](https://github.com/wnl-icb-analytics/dbt-analytics/pull/1218), merged
19 September 2026, records the builds, aggregate comparisons, source-guidance
checks and corrections made during development. The broad DEV build processed
136 models, 403 tests and two snapshots. All MHSDS tests passed, but a separate
segmentation row-count test failed. Subsequent focused builds checked the later
MHSDS corrections; their selections and results are recorded in the PR.

The [production deployment](https://github.com/wnl-icb-analytics/dbt-analytics/actions/runs/35445420585)
also failed on that segmentation comparison after
materialising models. A failed deployment does not roll back tables already
built. [PR #1219](https://github.com/wnl-icb-analytics/dbt-analytics/pull/1219),
merged 21 September, removed the invalid comparison between historical
segmentation and current demographics. Do not describe the original deployment
as an entirely successful run.

Selected evidence from #1218 is below. These counts describe its data snapshot;
they are not fixed targets for later submissions.

| Check | Recorded result | What it establishes |
|---|---|---|
| Existing activity and costing | Contact identity/counts, occupancy and detention comparisons retained existing behaviour; total cost difference was zero. | The refactor preserved those established calculations. It does not independently validate their clinical meaning. |
| Person population | Final person-evidence build: three models and eight tests passed. | The summary follows the broader modelled-evidence population, rather than only referrals, contacts and inpatient records. |
| RTT evidence | Accepted raw, staging and reporting each retained 819,599 rows, with 535,804 starts and 194,123 ends. | The start/end imbalance was present in the source. Missing pathway identifiers prevent a certified distinct-clock count. |
| Assessment interpretation | All 24,443,224 observations retained; published historical definitions labelled 2,702,663 previously unmatched observations. | Better tool grouping preserved responses. Defined unknown responses do not become numeric scores. |
| Ward capacity | All 63,452 ward/submission records retained. In July 2026, 347 of 651 ward-periods reported available bed days. | Staging did not discard reported capacity. Coverage does not support a blanket provider utilisation claim. |
| Weekly hours | All 11,578,686 employment observations retained; all 9,837,186 populated hours codes labelled. | Hours are categories with descriptions, not quantities to sum or average. |
| Care-plan update time | All 6,812,996 records retained; 5,805,562 populated times matched the source time of day, with zero mismatches. | The correction preserved times, including midnight, instead of exposing their 1970 timestamp anchor as a date. |
| Semantic view and descriptions | Entity-count reconciliation passed; 144 checked table/view descriptions matched warehouse metadata. | Selected semantic measures and published comments agreed with the domain models at validation time. |

This guide replaces the assurance material removed from the
[September domain review](https://github.com/wnl-icb-analytics/dbt-analytics/blob/b56cb2047f035006c821afc341d9c2ae69ddc8f4/docs/mhsds-domain-review.md)
and [earlier clinical-method review](https://github.com/wnl-icb-analytics/dbt-analytics/blob/b56cb2047f035006c821afc341d9c2ae69ddc8f4/docs/mhsds-clinical-method-review.md).
Use those as historical evidence, not as current model instructions. The latest
full CodeRabbit review of #1218 was skipped because it exceeded the file limit;
automated review is not evidence of complete independent assurance.

## Check the automated coverage

Model YAML contains grain and field tests. The following checks protect specific
rules beyond those keys. Read the linked SQL when deciding whether a rule covers
the question being tested.

| Assurance question | Existing checks |
|---|---|
| Are all identifiable people with modelled evidence represented? | [Person-summary population and measures](../tests/mhsds_person_summary_rules.sql) |
| Does current caseload use the dataset's latest month, and do historical states exclude later attendance evidence? | [Caseload reconciliation](../tests/mhsds_current_caseload_reconciles.sql), [period evidence dates](../tests/mhsds_referral_period_evidence_dates.sql) |
| Do retained diagnoses account for their source rows, and do clinical components reconcile? | [Diagnosis source reconciliation](../tests/mhsds_diagnosis_source_reconciliation.sql), [clinical-item reconciliation](../tests/mhsds_clinical_records_reconcile.sql), [clinical identity](../tests/mhsds_clinical_record_identity.sql) |
| Are assessment responses interpreted and paired consistently? | [Response semantics](../tests/mhsds_assessment_response_semantics.sql), [signed ranges](../tests/mhsds_assessment_signed_ranges.sql), [pair context](../tests/mhsds_assessment_pair_context.sql) |
| Do contact context and inpatient fields follow the implemented specification rules? | [Contact context](../tests/mhsds_contact_context_rules.sql), [inpatient fields](../tests/mhsds_inpatient_uses_specification_defined_fields.sql) |
| Are known code and date problems guarded? | [Employment reference coverage](../tests/mhsds_employment_reference_coverage.sql), [complaint Read labels](../tests/mhsds_complaint_declared_read_labels.sql), [selected sentinel-date checks](../tests/mhsds_reporting_dates_exclude_source_sentinels.sql) |
| Do semantic measures match the reporting tables? | [Semantic count reconciliation](../tests/generic/mhsds_semantic_counts.sql), attached to `sem_mhsds` |

Passing tests do not establish provider completeness, clinical correctness or
fitness for every report. The date test covers named fields, and the semantic
test covers named measures and breakdowns. Neither checks every possible query.

## Run a focused engineering check

Record the Git commit, target, run date and selected nodes. Inspect the selection
before building. For example, after a person-summary change:

```powershell
dbt ls --target dev --select fct_mhsds_person_summary+
dbt compile --target dev --select fct_mhsds_person_summary+
dbt build --target dev --select fct_mhsds_person_summary+
```

Use the tracked DEV target and existing shared `DEV__` layers. Check whether
unselected upstream tables need a refresh or the established deferral workflow.
Record test results, warnings and skipped nodes separately; a successful compile
does not establish that the data tests passed.

Compare high-level counts before and after the change at the intended grain.
Check accepted-source coverage, retained revisions, missing parent/person links,
unmatched labels, dates and provider reporting coverage. Explain differences
rather than assuming that agreement with an older model proves correctness.
For semantic changes, compare direct SQL and semantic results using the same
population, period and grouping, including unknown categories.

## Test the questions analysts will ask

Agree a reporting period and provider scope before each comparison. Record the
query, expected interpretation, result and any unresolved limitation. These
checks are a plan for analyst testing, not claims that testing is complete.

| Question to test | Evidence needed for acceptance |
|---|---|
| Who is on the current recorded caseload? | Referral and distinct-person totals reconcile to the latest dataset month. Stale provider evidence is visible separately. Open referrals are not labelled clinically active treatment. |
| What was known at an earlier month end? | Period facts and period demographics are used; later attendance and current person attributes do not alter the historical answer. |
| How much care took place? | Contacts, attended contacts, care activities and indirect work remain distinct. Staff and team joins do not multiply the parent count. |
| Who attended group care? | Identifiable group-therapy contacts reconcile to their subset of contacts. Anonymous sessions have no inferred people or invented session membership. |
| What diagnoses, complaints and outcomes are recorded? | Submitted schemes, unmatched labels and missing links remain visible. Responses, assessment groups and score changes are distinguished; numeric change is not called clinical improvement. |
| How much inpatient care and capacity are recorded? | The query distinguishes recorded stays, inferred occupancy and reported capacity. Missing beds are not zero; monthly averages are not summed across months or described as live vacancies. |
| What restrictions applied? | Detention, community treatment orders, recalls and restrictive interventions retain their different meanings and dates. |
| Can the semantic view answer the same question? | Direct SQL and semantic totals agree for the chosen filters and breakdowns. Descriptions help the analyst choose the correct grain without reconstructing source submissions. |

Use provider/month coverage alongside counts. An absent record can reflect a
missing submission or unrecorded evidence. Equal totals can still conceal wrong
membership, so use aggregate missing/extra-key checks where population identity
matters. For comparisons of providers or demographic groups, assess recording
coverage and the denominator before interpreting differences.

## Record the assurance decision

For each tested question, retain the following in the assurance issue or PR:

- Commit, environment, run date, reporting period and provider scope.
- Models, test selection and reproducible query or query reference.
- Expected result, observed aggregate result and pass/fail/not-tested status.
- Known limitations, unresolved findings and their effect on the proposed use.
- Reviewer, review date and the specific analytical use accepted.

Keep patient-level inspection in an approved Snowflake session. Repository files,
GitHub text and agent-visible outputs must contain only non-identifying
aggregates or synthetic examples, including when a test fails.

The delivered scope is recorded in [epic #1028](https://github.com/wnl-icb-analytics/dbt-analytics/issues/1028).
Further domain expansion is deferred. Self-harm, assaults, police assistance,
digital interventions and the deferred referral/attendee detail are not covered
by an assurance decision for the current reporting layer. Reassess the relevant
checks when sources, definitions or model logic change.
