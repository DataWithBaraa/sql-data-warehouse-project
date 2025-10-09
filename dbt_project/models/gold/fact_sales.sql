{{ config(materialized='table') }}

select
  s.sale_id,
  s.order_date,
  s.quantity,
  s.price,
  s.sales_amount,
  s.customer_key as customer_id,
  s.product_key as product_id,
  current_timestamp() as dwh_loaded_at
from {{ ref('sales') }} s