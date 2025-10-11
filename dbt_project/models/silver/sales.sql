{{ config(materialized='table') }}

with raw as (
  select * from {{ source('bronze_ds','crm_sales_details') }}
),

parsed as (
  select
    trim(sls_ord_num) as sale_id,
    safe_cast(nullif(trim(sls_prd_key),'') as int64) as product_key,
    sls_cust_id as customer_id,
    -- Fix: Use PARSE_DATE with proper format, handle as string first
    case 
      when regexp_contains(cast(sls_order_dt as string), r'^[0-9]{8}$')
      then parse_date('%Y%m%d', cast(sls_order_dt as string))
      else null
    end as order_date,
    case 
      when regexp_contains(cast(sls_ship_dt as string), r'^[0-9]{8}$')
      then parse_date('%Y%m%d', cast(sls_ship_dt as string))
      else null
    end as ship_date,
    case 
      when regexp_contains(cast(sls_due_dt as string), r'^[0-9]{8}$')
      then parse_date('%Y%m%d', cast(sls_due_dt as string))
      else null
    end as due_date,
    safe_cast(sls_quantity as int64) as quantity,
    safe_cast(sls_price as numeric) as price,
    -- Fix: Cast to numeric first, then compute sales_amount when missing
    coalesce(
      safe_cast(sls_sales as numeric), 
      safe_cast(sls_quantity as int64) * safe_cast(sls_price as numeric)
    ) as sales_amount,
    current_timestamp() as dwh_create_date,
    -- Fix: NULL-safe row fingerprint with explicit COALESCE and CAST
    farm_fingerprint(concat(
      coalesce(trim(sls_ord_num), 'NO_SALE_ID'), '||',
      coalesce(cast(safe_cast(sls_quantity as int64) as string), 'NO_QTY'), '||', 
      coalesce(cast(safe_cast(sls_price as numeric) as string), 'NO_PRICE'), '||',
      coalesce(cast(sls_order_dt as string), 'NO_DATE')
    )) as row_fingerprint
  from raw
),

-- dedupe: partition by sale_id, prioritize non-null sales_amount, then latest timestamp
ranked as (
  select *, 
    row_number() over (
      partition by coalesce(sale_id, concat('noid_', cast(row_fingerprint as string)))
      order by 
        case when sales_amount is not null then 1 else 2 end,  -- prefer non-null sales_amount
        dwh_create_date desc
    ) as rn
  from parsed
)

select
  -- Fix: NULL-safe deterministic surrogate key with proper casting
  concat('sale_', cast(abs(farm_fingerprint(concat(
    coalesce(sale_id, 'NO_ID'), '||',
    coalesce(cast(order_date as string), 'NO_DATE'), '||',
    coalesce(cast(quantity as string), 'NO_QTY'), '||',
    coalesce(cast(price as string), 'NO_PRICE'), '||',
    cast(row_fingerprint as string)
  ))) as string)) as sale_key,
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
where rn = 1  -- Fix: Ensure we only get deduplicated rows