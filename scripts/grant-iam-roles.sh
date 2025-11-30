#!/bin/bash

# Grant IAM Roles to Terraform Service Account
# Run this script if you have Project Editor or Owner permissions
# Usage: ./scripts/grant-iam-roles.sh

PROJECT_ID="ornate-producer-477604-s3"
SERVICE_ACCOUNT="terraform-sa@ornate-producer-477604-s3.iam.gserviceaccount.com"

echo "Granting IAM roles to $SERVICE_ACCOUNT in project $PROJECT_ID..."

# Grant Cloud SQL Admin role
echo "→ Granting Cloud SQL Admin..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:$SERVICE_ACCOUNT \
  --role=roles/cloudsql.admin \
  --quiet

# Grant Compute Network Admin role
echo "→ Granting Compute Network Admin..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:$SERVICE_ACCOUNT \
  --role=roles/compute.networkAdmin \
  --quiet

# Grant Secret Manager Admin role
echo "→ Granting Secret Manager Admin..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:$SERVICE_ACCOUNT \
  --role=roles/secretmanager.admin \
  --quiet

# Grant Service Account User role
echo "→ Granting Service Account User..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:$SERVICE_ACCOUNT \
  --role=roles/iam.serviceAccountUser \
  --quiet

echo "✅ All roles granted successfully!"
echo ""
echo "Verify with:"
echo "gcloud projects get-iam-policy $PROJECT_ID --flatten='bindings[].members' --filter='bindings.members:$SERVICE_ACCOUNT' --format='table(bindings.role)'"
