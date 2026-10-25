{% macro observation_reading_key(alias=none, clinical_date='clinical_effective_date', value='result_value') -%}
    {#- ARRAY_CONSTRUCT keeps null results, unlike multi-column COUNT(DISTINCT). -#}
    {%- set prefix = alias ~ '.' if alias else '' -%}
    ARRAY_CONSTRUCT({{ prefix }}person_id, {{ prefix }}concept_code, {{ prefix }}{{ clinical_date }}::DATE, {{ prefix }}{{ value }})
{%- endmacro %}
