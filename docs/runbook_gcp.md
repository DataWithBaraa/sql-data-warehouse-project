# GCP BigQuery Deployment Runbook

## Overview

This runbook provides step-by-step instructions for deploying the E-commerce Data Warehouse to Google Cloud Platform using BigQuery.

## Prerequisites

- Google Cloud SDK (`gcloud`, `gsutil`, `bq`) installed
- GCP project with billing enabled
- Service account with BigQuery and Storage permissions

## Quick Setup Steps

### 1. Infrastructure Bootstrap

```bash
# Set environment variables
export PROJECT_ID="recloud-ecom-dwh"
export BUCKET_NAME="recloud-ecom-daviddamon-20251007-datasets"

# Run infrastructure setup
./scripts/cloud/quick_setup.sh
```

### 2. Upload Datasets

```bash
# Upload local CSV files to GCS
./scripts/cloud/gs_upload.sh
```

### 3. Load Bronze Layer

```bash
# Load all CSV files into BigQuery bronze tables
./scripts/cloud/load_bronze.sh
```

### 4. Verify Data Loading

```bash
# Run verification queries
bq query --nouse_legacy_sql < tests/verify_bronze.sql
```

## Authentication

### Using Service Account (Recommended for CI)

```bash
# Set service account key path
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"

# Authenticate
gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS
```

### Using User Account (Local Development)

```bash
# Authenticate with your Google account
gcloud auth login

# Set project
gcloud config set project $PROJECT_ID
```

## Troubleshooting

### Common Issues

1. **Permission Denied**: Ensure service account has BigQuery Admin and Storage Admin roles
2. **Bucket Not Found**: Run `quick_setup.sh` to create the bucket
3. **Dataset Not Found**: Ensure BigQuery datasets are created in the correct region

### Verification Commands

```bash
# List datasets
bq ls --project_id=$PROJECT_ID

# List tables in bronze dataset
bq ls $PROJECT_ID:bronze_ds

# Check row counts
bq query --nouse_legacy_sql "SELECT COUNT(*) FROM \`$PROJECT_ID.bronze_ds.crm_sales_details\`"
```

## Next Steps

After successful bronze layer deployment:
1. Deploy dbt models for silver layer transformation
2. Create gold layer dimensional models
3. Set up monitoring and alerting