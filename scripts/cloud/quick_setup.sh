#!/bin/bash

# GCP Infrastructure Bootstrap Script
# Creates project, enables APIs, sets up BigQuery datasets and GCS bucket

set -e

PROJECT_ID="${PROJECT_ID:-recloud-ecom-dwh}"
BUCKET_NAME="${BUCKET_NAME:-recloud-ecom-daviddamon-20251007-datasets}"
LOCATION="${LOCATION:-US}"
SERVICE_ACCOUNT_NAME="${SERVICE_ACCOUNT_NAME:-ci-runner}"

echo "================================================"
echo "GCP Infrastructure Bootstrap"
echo "Project: $PROJECT_ID"
echo "Bucket: $BUCKET_NAME"
echo "Location: $LOCATION"
echo "================================================"

# Enable required APIs
echo "Enabling required APIs..."
gcloud services enable bigquery.googleapis.com \
  storage.googleapis.com \
  --project=$PROJECT_ID

# Create GCS bucket
echo "Creating GCS bucket: $BUCKET_NAME"
gsutil mb -p $PROJECT_ID -c STANDARD -l $LOCATION gs://$BUCKET_NAME/ || echo "Bucket may already exist"

# Create BigQuery datasets
echo "Creating BigQuery datasets..."
bq mk --location=$LOCATION --dataset $PROJECT_ID:bronze_ds || echo "Dataset may already exist"
bq mk --location=$LOCATION --dataset $PROJECT_ID:silver_ds || echo "Dataset may already exist"
bq mk --location=$LOCATION --dataset $PROJECT_ID:gold_ds || echo "Dataset may already exist"

# Create service account for CI
echo "Creating service account: $SERVICE_ACCOUNT_NAME"
gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME \
  --display-name="CI Runner Service Account" \
  --project=$PROJECT_ID || echo "Service account may already exist"

# Grant necessary permissions
echo "Granting permissions to service account..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/bigquery.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/storage.admin"

echo "========================================"
echo "Infrastructure setup completed!"
echo "Next steps:"
echo "1. Upload datasets: ./scripts/cloud/gs_upload.sh"
echo "2. Load bronze layer: ./scripts/cloud/load_bronze.sh"
echo "========================================"