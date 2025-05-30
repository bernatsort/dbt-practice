-- macros/load_control_utils.sql


{% macro get_control_params(table_name) %}
    {% set control_table = this.schema ~ '.int_load_control_master' %}

    {% set query %}
        SELECT load_mode, max_chg_dt, active_load_flg
        FROM {{ control_table }}
        WHERE table_nm = '{{ table_name }}'
    {% endset %}

    {% set results = run_query(query) %}

    {% if execute and results and results.rows | length > 0 %}
        {% set row = {} %}
        {% for i in range(results.columns | length) %}
            {% set _ = row.update({results.columns[i].name: results.rows[0][i]}) %}
        {% endfor %}
        {{ return(row) }}
    {% else %}
        {{ return({'load_mode': 'FULL', 'max_chg_dt': none, 'active_load_flg': 1}) }}
    {% endif %}
{% endmacro %}


{% macro truncate_if_full_mode(model) %}
    {% set control = get_control_params(model.name) %}

    {% if control.load_mode == 'FULL' %}
        {% set table_exists_query %}
            SELECT EXISTS (
                SELECT 1
                FROM information_schema.tables 
                WHERE table_schema = '{{ model.schema }}'
                  AND table_name = '{{ model.name }}'
            )
        {% endset %}

        {% set result = run_query(table_exists_query) %}
        {% if execute and result and result.rows[0][0] %}
            {{ log("Pre-hook: FULL mode -> truncating table " ~ model.schema ~ '.' ~ model.name, info=True) }}
            truncate table {{ model }};
        {% else %}
            {{ log("Pre-hook: table does not exist, skipping TRUNCATE for " ~ model.name, info=True) }}
        {% endif %}
    {% else %}
        {{ log("Pre-hook: not FULL mode, skipping TRUNCATE for " ~ model.name, info=True) }}
    {% endif %}
{% endmacro %}


{% macro abort_if_not_active(model) %}
    {% set control = get_control_params(model.name) %}

    {% if control.active_load_flg != 1 %}
        {{ exceptions.raise_compiler_error("Carga desactivada para el modelo: " ~ model.name) }}
    {% else %}
        {{ log("Carga activa para el modelo: " ~ model.name, info=True) }}
    {% endif %}
{% endmacro %}


{% macro mark_model_as_pending(model) %}
    {% set query %}
        UPDATE {{ model.schema }}.int_load_control_master
        SET load_status = 'PENDING',
            int_cre_ts = CURRENT_TIMESTAMP,
            int_cre_usr = CURRENT_USER
        WHERE table_nm = '{{ model.name }}'
    {% endset %}
    {% do run_query(query) %}
{% endmacro %}

{% macro mark_model_as_ok(model) %}
    {% set max_date_query %}
        SELECT MAX(int_tec_fr_dt) FROM {{ model.schema }}.{{ model.identifier }}
    {% endset %}

    {% set result = run_query(max_date_query) %}
    {% set max_chg_dt = none %}
    {% if execute and result and result.rows | length > 0 %}
        {% set max_chg_dt = result.rows[0][0] %}
    {% endif %}

    {% set query %}
        UPDATE {{ model.schema }}.int_load_control_master
        SET load_status = 'OK',
            last_load_ts = current_timestamp,
            int_cre_ts = current_timestamp,
            int_cre_usr = current_user,
            max_chg_dt = {% if max_chg_dt %}'{{ max_chg_dt }}'{% else %}NULL{% endif %}
        WHERE table_nm = '{{ model.name }}'
    {% endset %}

    {% do run_query(query) %}
{% endmacro %}

{% macro mark_model_as_ko(model) %}
    {% set query %}
        UPDATE {{ model.schema }}.int_load_control_master
        SET load_status = 'KO',
            last_error_ts = current_timestamp,
            int_cre_ts = current_timestamp,
            int_cre_usr = current_user
        WHERE table_nm = '{{ model.name }}'
    {% endset %}
    {% do run_query(query) %}
{% endmacro %}


{% macro update_load_status_from_results(results) %}
    {% if execute %}
        {% for res in results %}
            {% set model = {
                "name": res.node.name,
                "schema": res.node.schema,
                "identifier": res.node.identifier
            } %}
            {% if res.status == 'success' %}
                {{ mark_model_as_ok(model) }}
            {% elif res.status == 'error' %}
                {{ mark_model_as_ko(model) }}
            {% endif %}
        {% endfor %}
    {% endif %}
{% endmacro %}


-- inserción automática en int_load_control_master si no existe.
{% macro ensure_load_control_entry(model) %}
    {% set query_check %}
        SELECT COUNT(*) 
        FROM {{ model.schema }}.int_load_control_master
        WHERE table_nm = '{{ model.name }}'
    {% endset %}

    {% set result = run_query(query_check) %}
    {% if execute and result and result.rows[0][0] == 0 %}
        {{ log("No existe entrada en int_load_control_master para " ~ model.name ~ ". Creando...", info=True) }}

        {% set insert_query %}
            INSERT INTO {{ model.schema }}.int_load_control_master (
                table_nm,
                active_load_flg,
                load_status,
                load_mode,
                load_type_prc,
                orchestrator_nm,
                int_cre_ts,
                int_cre_usr
            )
            VALUES (
                '{{ model.name }}',
                1,
                'PENDING',
                'FULL',
                NULL,
                'dbt_pipeline',
                current_timestamp,
                current_user
            )
        {% endset %}

        {% do run_query(insert_query) %}
    {% else %}
        {{ log("Entrada ya existe en int_load_control_master para " ~ model.name ~ ". OK", info=True) }}
    {% endif %}
{% endmacro %}



