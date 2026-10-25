-- New code-list members must have a supported activity meaning.
select snomed_code, concept_name, classification_basis
from {{ ref('snomed_evidence_type') }}
where evidence_type is null
