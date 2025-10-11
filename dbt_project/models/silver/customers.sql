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
    -- Build robust full_name with fallbacks and placeholder
    coalesce(
      -- First try: CRM first + last name
      nullif(trim(concat(
        coalesce(nullif(trim(raw.cst_firstname),''), ''), 
        case when nullif(trim(raw.cst_firstname),'') is not null and nullif(trim(raw.cst_lastname),'') is not null then ' ' else '' end,
        coalesce(nullif(trim(raw.cst_lastname),''), '')
      )), ''),
      -- Fallback: Use customer ID as identifier
      concat('Customer_', cast(raw.cst_id as string)),
      -- Last resort: Unknown customer placeholder
      'Unknown Name - Review'
    ) as full_name,
    case
      when upper(nullif(trim(raw.cst_gndr),'')) like 'M%' then 'M'
      when upper(nullif(trim(raw.cst_gndr),'')) like 'F%' then 'F'
      else null
    end as gender,
    raw.cst_create_date as create_date,
    current_timestamp() as dwh_create_date,
    -- Score for prioritization: prefer rows with complete names
    case 
      when nullif(trim(raw.cst_firstname),'') is not null and nullif(trim(raw.cst_lastname),'') is not null then 1
      when nullif(trim(raw.cst_firstname),'') is not null or nullif(trim(raw.cst_lastname),'') is not null then 2
      else 3
    end as name_completeness_score
  from raw
  left join erp on cast(raw.cst_id as string) = erp.cid
),

-- Filter out fully-empty rows (all major fields NULL)
filtered as (
  select * from unified
  where not (customer_id is null and (full_name is null or trim(full_name) = '') and gender is null and create_date is null)
),

-- Dedupe by customer_id, prioritizing complete names first, then latest timestamp
ranked as (
  select *,
    row_number() over (
      partition by customer_id 
      order by 
        name_completeness_score asc,  -- 1 = both names, 2 = one name, 3 = no names
        dwh_create_date desc nulls last
    ) as rn
  from filtered
)

select
  -- Deterministic surrogate key - NULL-safe
  concat('cust_', cast(abs(farm_fingerprint(concat(
    coalesce(cast(customer_id as string), 'NO_ID'), '||',
    coalesce(full_name, 'NO_NAME'), '||',
    coalesce(cast(create_date as string), 'NO_DATE')
  ))) as string)) as customer_key,
  customer_id,
  full_name,
  gender,
  create_date,
  dwh_create_date
from ranked
where rn = 1