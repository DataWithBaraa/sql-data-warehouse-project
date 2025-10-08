{{ config(materialized='table') }}

select
  safe_cast(nullif(prd_id,'') as int64) as product_id,
  nullif(trim(prd_key),'') as product_key,
  nullif(trim(prd_nm),'') as product_name,
  safe_cast(nullif(prd_cost,'') as numeric) as product_cost,
  nullif(trim(prd_line),'') as product_line,
  safe_cast(nullif(prd_start_dt,'') as date) as start_date,
  safe_cast(nullif(prd_end_dt,'') as date) as end_date,
  current_timestamp() as dwh_create_date
from {{ source('bronze_ds','crm_prd_info') }}