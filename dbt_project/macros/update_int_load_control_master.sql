

{% macro update_int_load_control_master(results) %}
    {% if execute %}
    
        {{ log('Recording model run results in `int_load_control_master`.', info=True) }}

        {% for res in results %}
            {%-if res.node.schema in ('snapshot', 'dw_schema') and not res.node.name.startswith('ephemeral_')-%}
                {% set check_count %}
                    SELECT COUNT(*) AS record_count
                    FROM {{ res.node.database }}.{{ res.node.schema }}.int_load_control_
                        {%-if res.node.name.startswith('ctm')-%}
                            cmt
                        {%-elif res.node.name.startswith('qm')-%}
                            qm
                        {%-else-%}
                            master
                        {%-endif-%}_dbt a
                    WHERE table_nm = '{{res.node.name}}'
                {% endset %}

                {% set count_result = run_query(check_count) %}

                {% if count_result.columns[0][0] == 0 %}
                    {% set insert_query %}
                        INSERT INTO {{ res.node.database }}.{{ res.node.schema }}.int_load_control_
                        {%-if res.node.name.startswith('ctm')-%}
                            cmt
                        {%-elif res.node.name.startswith('qm')-%}
                            qm
                        {%-else-%}
                            master
                        {%-endif-%}_dbt (table_nm,active_load_flg, orchestrator_nm)
                        VALUES ('{{res.node.name}}',1,'dbt_pipeline')
                    {% endset %}
                    
                    {% do run_query(insert_query) %}
                {% endif %}
                {% set query -%}
                    update {{ res.node.database }}.{{ res.node.schema }}.int_load_control_
                        {%-if res.node.name.startswith('ctm')-%}
                            cmt
                        {%-elif res.node.name.startswith('qm')-%}
                            qm
                        {%-else-%}
                            master
                        {%-endif-%}_dbt a
                    {%if res.status == 'error'%}
                        set a.max_chg_dt = NULL
                        ,a.last_error_ts = current_timestamp()
                        ,a.load_status = 'KO'
                        ,a.load_mode = {%- if res.node.config.materialized == 'table' -%} 
                                        'FULL' 
                                        {%-else%}
                                        'DELTA'
                                        {%endif%}
                        ,a.load_type_prc = {%- if res.node.config.incremental_strategy == None -%} NULL {%-else-%} upper('{{res.node.config.incremental_strategy}}') {%endif%}
                        ,a.int_cre_ts= current_timestamp()
                        ,a.int_cre_usr=current_user()
                    {%elif res.status == 'success'%}
                        set a.max_chg_dt = (select max(int_tec_fr_dt) from {{ res.node.database }}.{{ res.node.schema }}.{{res.node.name}})
                        ,a.last_load_ts = current_timestamp()
                        ,a.load_status = 'OK'
                        ,a.load_mode = {%- if res.node.config.materialized == 'table' -%} 
                                        'FULL' 
                                        {%-else%}
                                        'DELTA'
                                        {%endif%}
                        ,a.load_type_prc = {%- if res.node.config.incremental_strategy == None -%} NULL {%-else-%} upper('{{res.node.config.incremental_strategy}}') {%endif%},a.int_cre_ts= current_timestamp()
                        ,a.int_cre_usr=current_user()
                    {%elif res.status == 'skipped'%}
                        set a.last_load_ts = current_timestamp()
                        ,a.load_status = 'SKIPPED'
                        ,a.load_mode = {%- if res.node.config.materialized == 'table' -%} 
                                        'FULL' 
                                        {%-else%}
                                        'DELTA'
                                        {%endif%}
                        ,a.load_type_prc = {%- if res.node.config.incremental_strategy == None -%} NULL {%-else-%} upper('{{res.node.config.incremental_strategy}}') {%endif%}
                        ,a.int_cre_ts= current_timestamp()
                        ,a.int_cre_usr=current_user()
                    {%endif%}
                    where table_nm = '{{res.node.name}}';
                {%- endset %}
                {% do run_query(query) %}
            {% endif %}
        {% endfor %}
        
    {% endif %}
{% endmacro %}
