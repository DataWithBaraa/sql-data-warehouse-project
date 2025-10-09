{{ config(materialized='table') }}

select
  trim(sls_ord_num) as sale_id,
  safe_cast(nullif(sls_prd_key,'') as int64) as product_key,
  safe_cast(nullif(sls_cust_id,'') as int64) as customer_key,
  safe_cast(nullif(sls_order_dt,'') as date) as order_date,
  safe_cast(nullif(sls_ship_dt,'') as date) as ship_date,
  safe_cast(nullif(sls_due_dt,'') as date) as due_date,
  safe_cast(nullif(sls_sales,'') as numeric) as sales_amount,
  safe_cast(nullif(sls_quantity,'') as int64) as quantity,
  safe_cast(nullif(sls_price,'') as numeric) as price,
  current_timestamp() as dwh_create_date
from {{ source('bronze_ds','crm_sales_details') }}