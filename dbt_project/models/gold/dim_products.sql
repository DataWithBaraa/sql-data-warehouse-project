{{ config(materialized='incremental', unique_key='product_id') }}

with src as (
  select product_id, product_key, product_name, product_cost, product_line, start_date, end_date
  from {{ ref('products') }}
)

select
  product_id,
  product_key,
  product_name,
  product_cost,
  product_line,
  start_date,
  end_date,
  current_timestamp() as last_updated
from src

{% if is_incremental() %}
-- incremental merge behavior for BigQuery
{% endif %}