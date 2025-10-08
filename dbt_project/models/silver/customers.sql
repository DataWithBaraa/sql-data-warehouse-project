{{ config(materialized='table') }}

with raw as (
  select * from {{ source('bronze_ds','crm_cust_info') }}
),

erp as (
  select * from {{ source('bronze_ds','erp_cust_az12') }}
),

unified as (
  select
    safe_cast(nullif(trim(cst_id),'') as int64) as customer_id,
    nullif(trim(concat(cst_firstname, ' ', cst_lastname)),'') as full_name,
    case
      when upper(nullif(trim(cst_gndr),'')) like 'M%' then 'M'
      when upper(nullif(trim(cst_gndr),'')) like 'F%' then 'F'
      else null
    end as gender,
    safe_cast(nullif(trim(cst_create_date),'') as date) as create_date,
    current_timestamp() as dwh_create_date
  from raw
)

select * from unified