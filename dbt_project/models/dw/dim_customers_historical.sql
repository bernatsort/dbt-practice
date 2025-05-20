-- models/dw/dim_customers_historical.sql

/*
Incremental Filter Logic – Snapshot-Based SCD2 Strategy in dbt 

This block enables incremental processing of only the new or changed rows 
coming from the snapshot table. 
It avoids reprocessing the full history on every run and focuses solely on the 
delta based on snapshot metadata.
*/

{{ config(
    materialized='incremental',
    unique_key='dim_cdc_key',
    incremental_strategy='merge',
    on_schema_change='ignore'
) }}

-- Define a query that retrieves the maximum int_tec_fr_dt from the current target table 
-- ({{ this }} refers to the model itself)
-- This represents the most recent version we already have processed
{%- set query -%}
select max(int_tec_fr_dt) as max_int_tec_fr_dt 
from {{this}}
{%- endset -%}


{# 
    If this is an incremental run, get the latest int_tec_fr_dt date from the already-built table, 
    so I can filter new snapshot rows that came in after it.

    {% if is_incremental() %}
        dbt evaluates this at runtime.
        It returns True only when the model is being built incrementally (not on full-refresh).
        If you are doing a full refresh, the block inside will be skipped.

    query is a Jinja variable we defined earlier.
    run_query() executes that SQL at runtime, inside dbt, and returns the result as a Jinja-friendly object — like a table in memory.

    {% if execute %}
        Prevents this block from running during compilation.
        dbt compiles models before executing, and execute only returns True during the actual execution.
        This protects your model from failing when dbt is just compiling SQL.

    {% set max_date = results.columns[0][0] %}
    results.columns[0][0] means:
        First column of the result
        First row
    So it extracts the value from the result of:
        SELECT max(int_tec_fr_dt) FROM {{ this }}
    and stores it in a variable max_date.

    If this is an incremental run (not full-refresh), execute the query and assign the result to a variable called max_date.
    run_query() returns a table-like object. The first column, first row is accessed via results.columns[0][0].
    Note: "execute" ensures that the SQL runs only during dbt execution, not during compilation.


    ####### Block with comments (jinja cannot handle comments) #######
    {% if is_incremental() %} -- Only run logic during incremental build
        {% set results = run_query(query) %} -- Run a SQL query against your target table
        {% if execute %} -- Prevent errors during compilation
            {% set max_date = results.columns[0][0] %} -- Extract first value (your max_date) from result
        {% endif %}
    {% endif %}

#}

{% if is_incremental() %}
    {% set results = run_query(query) %}
    {% if execute %}
        {% set max_date = results.columns[0][0] %}
    {% endif %}
{% endif %}


with source as (
    select
        customer_id,
        first_name,
        last_name,
        email,
        dim_cdc_key,
        int_tec_to_dt, -- dbt_valid_from
        int_tec_fr_dt, -- dbt_valid_to
        case
            when int_tec_to_dt::date=to_date('9999-12-31', 'YYYY-MM-DD') then 1
            else 0         
        end as curr_flg,

        case
            when del_flg::boolean = true then 1
            else 0
        end as del_flg 
    from {{ ref('customers_snapshot') }}
    {# 
    Apply a WHERE clause during incremental builds to include only the snapshot rows that are:
     (A) New: int_tec_fr_dt > max_date
        - These are new snapshot entries created after the last processed one.

     (B) Closed out: int_tec_to_dt > max_date AND int_tec_to_dt != '9999-12-31'
        - These are rows that were open during the last snapshot, but have since 
          been updated and closed. This is necessary to preserve full SCD2 logic.

    -- The snapshot table grows over time, and we want to avoid reprocessing old rows
    {% if is_incremental() %}
        -- Filtering on int_tec_fr_dt (i.e., dbt_valid_from) ensures we're only considering newer versions of records
        where int_tec_fr_dt > '{{max_date}}'
            -- still active but updated records (Which means we also pick up rows that are now closed out (i.e., updated/expired).)
            or (int_tec_to_dt > '{{max_date}}' and int_tec_to_dt::date!=to_date('9999-12-31','yyyy-mm-dd'))
    {% endif %}
    #}

    {% if is_incremental() %}
        where int_tec_fr_dt > '{{max_date}}'
            or (int_tec_to_dt > '{{max_date}}' and int_tec_to_dt::date!=to_date('9999-12-31','yyyy-mm-dd'))
    {% endif %}
)

select * from source

