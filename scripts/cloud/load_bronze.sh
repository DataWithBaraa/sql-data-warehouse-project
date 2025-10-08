#!/bin/bash

# BigQuery Bronze Layer Data Loading Script
# Project: recloud-ecom-dwh
# Dataset: bronze_ds
# Bucket: recloud-ecom-daviddamon-20251007-datasets
# Aligned with repository bronze table schemas

set -e

PROJECT_ID="recloud-ecom-dwh"
DATASET="bronze_ds"
BUCKET="recloud-ecom-daviddamon-20251007-datasets"
LOCATION="US"

echo "================================================"
echo "Loading Bronze Layer to BigQuery"
echo "Project: $PROJECT_ID"
echo "Dataset: $DATASET"
echo "Bucket: gs://$BUCKET"
echo "================================================"

# Create dataset if it doesn't exist
echo "Creating dataset $DATASET..."
bq mk --location=$LOCATION --dataset $PROJECT_ID:$DATASET || echo "Dataset may already exist"

echo ""
echo "Loading CRM tables..."
echo "--------------------"

# Load CRM Customer Info
echo "Loading crm_cust_info..."
bq load \
  --source_format=CSV \
  --skip_leading_rows=1 \
  --location=$LOCATION \
  --replace \
  $PROJECT_ID:$DATASET.crm_cust_info \
  gs://$BUCKET/datasets/source_crm/cust_info.csv \
  cst_id:INTEGER,cst_key:STRING,cst_firstname:STRING,cst_lastname:STRING,cst_marital_status:STRING,cst_gndr:STRING,cst_create_date:DATE

# Load CRM Product Info  
echo "Loading crm_prd_info..."
bq load \
  --source_format=CSV \
  --skip_leading_rows=1 \
  --location=$LOCATION \
  --replace \
  --allow_quoted_newlines \
  $PROJECT_ID:$DATASET.crm_prd_info \
  gs://$BUCKET/datasets/source_crm/prd_info.csv \
  prd_id:INTEGER,prd_key:STRING,prd_nm:STRING,prd_cost:INTEGER,prd_line:STRING,prd_start_dt:DATETIME,prd_end_dt:DATETIME

# Load CRM Sales Details
echo "Loading crm_sales_details..."
bq load \
  --source_format=CSV \
  --skip_leading_rows=1 \
  --location=$LOCATION \
  --replace \
  $PROJECT_ID:$DATASET.crm_sales_details \
  gs://$BUCKET/datasets/source_crm/sales_details.csv \
  sls_ord_num:STRING,sls_prd_key:STRING,sls_cust_id:INTEGER,sls_order_dt:INTEGER,sls_ship_dt:INTEGER,sls_due_dt:INTEGER,sls_sales:INTEGER,sls_quantity:INTEGER,sls_price:INTEGER

echo ""
echo "Loading ERP tables..."
echo "--------------------"

# Load ERP Customer Data
echo "Loading erp_cust_az12..."
bq load \
  --source_format=CSV \
  --skip_leading_rows=1 \
  --location=$LOCATION \
  --replace \
  $PROJECT_ID:$DATASET.erp_cust_az12 \
  gs://$BUCKET/datasets/source_erp/CUST_AZ12.csv \
  cid:STRING,bdate:DATE,gen:STRING

# Load ERP Location Data
echo "Loading erp_loc_a101..."
bq load \
  --source_format=CSV \
  --skip_leading_rows=1 \
  --location=$LOCATION \
  --replace \
  $PROJECT_ID:$DATASET.erp_loc_a101 \
  gs://$BUCKET/datasets/source_erp/LOC_A101.csv \
  cid:STRING,cntry:STRING

# Load ERP Product Categories (note: ID column maps to 'id' field in bronze schema)
echo "Loading erp_px_cat_g1v2..."
bq load \
  --source_format=CSV \
  --skip_leading_rows=1 \
  --location=$LOCATION \
  --replace \
  $PROJECT_ID:$DATASET.erp_px_cat_g1v2 \
  gs://$BUCKET/datasets/source_erp/PX_CAT_G1V2.csv \
  id:STRING,cat:STRING,subcat:STRING,maintenance:STRING

echo ""
echo "========================================"
echo "Bronze layer loading completed!"
echo "========================================"