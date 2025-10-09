{{ config(materialized='incremental', unique_key='customer_id') }}

with src as (
  select customer_id, full_name, gender, create_date, dwh_create_date
  from {{ ref('customers') }}
)

select
  customer_id,
  full_name,
  gender,
  create_date,
  current_timestamp() as last_updated
from src

{% if is_incremental() %}
-- BigQuery MERGE will be used by dbt when incremental_strategy=merge
{% endif %}