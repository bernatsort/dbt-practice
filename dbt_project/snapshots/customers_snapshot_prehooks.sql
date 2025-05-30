-- snapshots/customers_snapshot_prehooks.sql

{% snapshot customers_snapshot_prehooks %}
{{ config(
    target_schema='snapshot',
    unique_key='customer_id',
    strategy='timestamp',
    updated_at='updated_at',
    dbt_valid_to_current="to_date('9999-12-31', 'YYYY-MM-DD')",
    snapshot_meta_column_names={
        'dbt_valid_from': 'int_tec_fr_dt',
        'dbt_valid_to': 'int_tec_to_dt',
        'dbt_scd_id': 'dim_cdc_key',
        'dbt_updated_at': 'int_tec_upd_dt' 
    },
    pre_hook=[
        "{{ ensure_load_control_entry(this) }}",
        "{{ check_dependencies(this) }}",
        "{{ abort_if_not_active(this) }}",
        "{{ mark_model_as_pending(this) }}"
    ]
) }}

select *
from {{ ref('stg_customers') }}

{% endsnapshot %}

#'dbt_is_deleted': 'del_flg'
# dbt ahora espera que siempre exista una columna del_flg en el resultado del snapshot.
# Pero como no hay ninguna fila eliminada todavía, dbt no puede generar esa columna.
# la tenemos que eliminar tb del modelo incremental


