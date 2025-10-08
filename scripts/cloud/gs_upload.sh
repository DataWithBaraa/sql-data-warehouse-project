#!/bin/bash

# GCS Upload Helper Script
# Uploads local datasets/ directory to GCS bucket

set -e

PROJECT_ID="${PROJECT_ID:-recloud-ecom-dwh}"
BUCKET_NAME="${BUCKET_NAME:-recloud-ecom-daviddamon-20251007-datasets}"
LOCAL_PATH="${LOCAL_PATH:-datasets/}"

echo "================================================"
echo "Uploading datasets to GCS"
echo "Local path: $LOCAL_PATH"
echo "Target: gs://$BUCKET_NAME/datasets/"
echo "================================================"

# Check if local datasets directory exists
if [ ! -d "$LOCAL_PATH" ]; then
    echo "Error: Local datasets directory not found: $LOCAL_PATH"
    exit 1
fi

# Upload all CSV files recursively
echo "Uploading files..."
gsutil -m cp -r $LOCAL_PATH gs://$BUCKET_NAME/

# Verify upload
echo ""
echo "Verifying upload..."
gsutil ls -r gs://$BUCKET_NAME/datasets/

echo ""
echo "========================================"
echo "Upload completed successfully!"
echo "Files available at: gs://$BUCKET_NAME/datasets/"
echo "========================================"