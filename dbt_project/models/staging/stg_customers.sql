--models/staging/stg_customers.sql

{{ config(materialized='ephemeral') }}

select
    customer_id,
    first_name,
    last_name,
    email,
    -- to_timestamp(left(updated_at::text, 14), 'yyyymmddhh24miss') as updated_at
    cast(updated_at as timestamp) as updated_at

from {{ ref('customers') }}