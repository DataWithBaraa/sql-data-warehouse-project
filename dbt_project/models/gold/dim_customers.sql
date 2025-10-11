{{ config(materialized='incremental', unique_key='customer_key') }}

select
  customer_key,
  customer_id,
  full_name,
  gender,
  create_date,
  max(dwh_create_date) as last_seen
from {{ ref('customers') }}
group by 1,2,3,4,5

{% if is_incremental() %}
-- BigQuery MERGE will be used by dbt when incremental_strategy=merge
{% endif %}