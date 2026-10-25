{% macro observation_reading_key(alias=none, clinical_date='clinical_effective_date', value='result_value', record_context=none) -%}
    {#- Keep value-free readings countable; unknown clinical days cannot prove a re-entry. -#}
    {%- set prefix = alias ~ '.' if alias else '' -%}
    ARRAY_CONSTRUCT(
        {{ prefix }}person_id,
        {{ prefix }}concept_code,
        {{ prefix }}{{ clinical_date }}::DATE,
        {% if value is none %}NULL{% else %}{{ prefix }}{{ value }}{% endif %},
        IFF({{ prefix }}{{ clinical_date }} IS NULL
            OR {{ prefix }}{{ clinical_date }}::DATE IN ('1900-01-01'::DATE, '1899-12-31'::DATE),
            {{ prefix }}id::VARCHAR, NULL)
        {% if record_context is not none %}, {{ prefix }}{{ record_context }}{% endif %}
    )
{%- endmacro %}
