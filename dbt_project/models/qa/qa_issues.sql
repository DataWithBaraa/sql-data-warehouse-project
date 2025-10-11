{{ config(materialized='table') }}

with customers_nulls as (
  select
    'customers' as table_name,
    null as sale_key,
    null as sale_id,
    customer_id,
    full_name,
    null as sales_amount,
    'NULL_CUSTOMER' as issue,
    current_timestamp() as detected_at
  from {{ ref('customers') }}
  where customer_id is null or full_name is null
),

sales_nulls as (
  select
    'sales' as table_name,
    sale_key,
    sale_id,
    customer_id,
    null as full_name,
    sales_amount,
    case when sales_amount is null then 'NULL_SALES_AMOUNT' else null end as issue,
    current_timestamp() as detected_at
  from {{ ref('sales') }}
  where sales_amount is null
),

bronze_dupes as (
  -- log bronze-level duplicate sale ids for audit
  select
    'bronze_sales_dup' as table_name,
    null as sale_key,
    sls_ord_num as sale_id,
    null as customer_id,
    null as full_name,
    null as sales_amount,
    concat('BRONZE_DUPLICATE_COUNT=', cast(count(*) as string)) as issue,
    current_timestamp() as detected_at
  from {{ source('bronze_ds','crm_sales_details') }}
  group by sls_ord_num
  having count(*) > 1
)

select * from customers_nulls
union all
select * from sales_nulls
union all
select * from bronze_dupes