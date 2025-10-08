/*
===============================================================================
Bronze Layer Verification Queries
===============================================================================
Script Purpose:
    Quick verification queries to confirm bronze layer data loading success.
    Provides row counts and sample data for each bronze table.

Usage:
    Run after bronze layer loading to verify data integrity and completeness.
===============================================================================
*/

-- Row counts for all bronze tables
SELECT 'crm_cust_info' as table_name, COUNT(*) as row_count 
FROM `recloud-ecom-dwh.bronze_ds.crm_cust_info`
UNION ALL
SELECT 'crm_prd_info', COUNT(*) 
FROM `recloud-ecom-dwh.bronze_ds.crm_prd_info`
UNION ALL
SELECT 'crm_sales_details', COUNT(*) 
FROM `recloud-ecom-dwh.bronze_ds.crm_sales_details`
UNION ALL
SELECT 'erp_cust_az12', COUNT(*) 
FROM `recloud-ecom-dwh.bronze_ds.erp_cust_az12`
UNION ALL
SELECT 'erp_loc_a101', COUNT(*) 
FROM `recloud-ecom-dwh.bronze_ds.erp_loc_a101`
UNION ALL
SELECT 'erp_px_cat_g1v2', COUNT(*) 
FROM `recloud-ecom-dwh.bronze_ds.erp_px_cat_g1v2`
ORDER BY table_name;

-- Sample records from each table
SELECT 'crm_cust_info' as source_table, cst_id, cst_key, cst_firstname, cst_lastname
FROM `recloud-ecom-dwh.bronze_ds.crm_cust_info` 
WHERE cst_id IS NOT NULL
LIMIT 3;

SELECT 'crm_prd_info' as source_table, prd_id, prd_key, prd_nm, prd_cost
FROM `recloud-ecom-dwh.bronze_ds.crm_prd_info` 
LIMIT 3;

SELECT 'crm_sales_details' as source_table, sls_ord_num, sls_prd_key, sls_cust_id, sls_sales
FROM `recloud-ecom-dwh.bronze_ds.crm_sales_details` 
LIMIT 3;

-- Data quality checks
SELECT 
    'Data Quality Check' as check_type,
    COUNT(*) as total_sales_records,
    COUNT(CASE WHEN sls_sales = sls_quantity * sls_price THEN 1 END) as valid_calculations,
    COUNT(CASE WHEN sls_sales != sls_quantity * sls_price THEN 1 END) as invalid_calculations
FROM `recloud-ecom-dwh.bronze_ds.crm_sales_details`
WHERE sls_sales IS NOT NULL AND sls_quantity IS NOT NULL AND sls_price IS NOT NULL;