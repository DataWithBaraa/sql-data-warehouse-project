{{ config(materialized='table') }}

with raw as (
  select * from {{ source('bronze_ds','crm_sales_details') }}
),

parsed as (
  select
    trim(sls_ord_num) as sale_id,
    safe_cast(nullif(trim(sls_prd_key),'') as int64) as product_key,
    sls_cust_id as customer_id,
    safe.parse_date('%Y%m%d', cast(sls_order_dt as string)) as order_date,
    safe.parse_date('%Y%m%d', cast(sls_ship_dt as string)) as ship_date,
    safe.parse_date('%Y%m%d', cast(sls_due_dt as string)) as due_date,
    sls_quantity as quantity,
    sls_price as price,
    -- compute sales_amount when missing
    coalesce(sls_sales, sls_quantity * sls_price) as sales_amount,
    current_timestamp() as dwh_create_date,
    -- keep raw row fingerprint for deterministic dedupe
    farm_fingerprint(concat(ifnull(trim(sls_ord_num),''), '||', ifnull(cast(sls_quantity as string),''), '||', ifnull(cast(sls_price as string),''), '||', ifnull(cast(sls_order_dt as string),''))) as row_fingerprint
  from raw
),

-- dedupe: partition by sale_id (business id); pick newest / best row
ranked as (
  select *, row_number() over (
     partition by ifnull(sale_id, concat('noid_', cast(row_fingerprint as string)))
     order by dwh_create_date desc
  ) as rn
  from parsed
)

select
  -- deterministic surrogate for fact: stable hash of business fields + fingerprint
  concat('sale_', cast(abs(farm_fingerprint(concat(ifnull(sale_id,''), cast(order_date as string), cast(quantity as string), cast(price as string), cast(row_fingerprint as string)))) as string)) as sale_key,
  sale_id,
  product_key,
  customer_id,
  order_date,
  ship_date,
  due_date,
  quantity,
  price,
  sales_amount,
  dwh_create_date
from ranked
where rn = 1