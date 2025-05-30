-- models/dw/dim_customers_historical_load_control.sql

{{ config(
    materialized='incremental',
    unique_key='dim_cdc_key',
    incremental_strategy='merge',
    on_schema_change='ignore',
     pre_hook=[
        "{{ ensure_load_control_entry(this) }}",
        "{{ mark_model_as_pending(this) }}",
        "{{ abort_if_not_active(this) }}",
        "{{ truncate_if_full_mode(this) }}"
    ]

) }}

{% set control = get_control_params(this.identifier) %}

{% set max_date = none %}

{% if is_incremental() and control.load_mode == 'DELTA' %}
    {% set query %}
        SELECT max(int_tec_fr_dt) FROM {{ this }}
    {% endset %}
    {% set results = run_query(query) %}
    {% if execute and results and results.rows | length > 0 %}
        {% set max_date = results.rows[0][0] %}
        {{ log("Max date for incremental load: " ~ max_date, info=True) }}
    {% endif %}
{% endif %}


with source as (

    select
        customer_id,
        first_name,
        last_name,
        email,
        dim_cdc_key,
        int_tec_to_dt,
        int_tec_fr_dt,
        case
            when int_tec_to_dt::date = to_date('9999-12-31', 'YYYY-MM-DD') then 1
            else 0
        end as curr_flg,
        case
            when del_flg::boolean = true then 1
            else 0
        end as del_flg
    from {{ ref('customers_snapshot') }}

    {% if is_incremental() and control.load_mode == 'DELTA' and max_date %}
    where int_tec_fr_dt > '{{ max_date }}'
       or (int_tec_to_dt > '{{ max_date }}' and int_tec_to_dt::date != to_date('9999-12-31', 'YYYY-MM-DD'))
    {% endif %}
)

select * from source

