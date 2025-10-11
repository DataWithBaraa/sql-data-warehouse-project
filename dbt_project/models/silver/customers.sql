{{ config(materialized='table') }}

with raw as (
  select * from {{ source('bronze_ds','crm_cust_info') }}
),

erp as (
  select * from {{ source('bronze_ds','erp_cust_az12') }}
),

unified as (
  select
    raw.cst_id as customer_id,
    nullif(trim(concat(nullif(trim(raw.cst_firstname),''), case when trim(coalesce(raw.cst_firstname,'')) != '' and trim(coalesce(raw.cst_lastname,'')) != '' then ' ' else '' end, nullif(trim(raw.cst_lastname),''))), '') as full_name,
    case
      when upper(nullif(trim(raw.cst_gndr),'')) like 'M%' then 'M'
      when upper(nullif(trim(raw.cst_gndr),'')) like 'F%' then 'F'
      else null
    end as gender,
    raw.cst_create_date as create_date,
    current_timestamp() as dwh_create_date
  from raw
  left join erp on cast(raw.cst_id as string) = erp.cid
),

-- remove fully-empty rows and dedupe by customer_id keeping latest
filtered as (
  select * from unified
  where not (customer_id is null and (full_name is null or trim(full_name) = '') and gender is null)
),

ranked as (
  select *,
    row_number() over (partition by customer_id order by dwh_create_date desc nulls last) as rn
  from filtered
)

select
  -- deterministic surrogate: include customer_id if exists else fingerprint
  coalesce(cast(customer_id as string), concat('synth_', cast(abs(farm_fingerprint(concat(ifnull(full_name,''), cast(create_date as string)))) as string))) as customer_key,
  customer_id,
  full_name,
  gender,
  create_date,
  dwh_create_date
from ranked
where rn = 1