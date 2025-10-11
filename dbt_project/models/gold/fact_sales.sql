{{ config(materialized='incremental', unique_key='sale_key') }}

select
  sale_key,
  sale_id,
  customer_id,
  product_key,
  order_date,
  ship_date,
  due_date,
  quantity,
  cast(price as numeric) as price,
  cast(sales_amount as numeric) as sales_amount,
  dwh_create_date
from {{ ref('sales') }}
where sale_key is not null  -- Prevent NULL surrogate keys from propagating

{% if is_incremental() %}
-- BigQuery MERGE will be used by dbt when incremental_strategy=merge
{% endif %}