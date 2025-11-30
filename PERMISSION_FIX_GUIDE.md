# GCP Permission Issues - Resolution Guide

## Problem Summary

You're encountering two main issues:

1. **Permission Denied for Service Networking**: `servicenetworking.googleapis.com`
2. **Permission Denied for Secret Manager**: `secretmanager.versions.access`
3. **IAM Role Assignment Failed**: The Terraform service account cannot grant roles to itself

## Root Cause

The service account `terraform-sa@ornate-producer-477604-s3.iam.gserviceaccount.com` is missing required IAM roles. Additionally, you don't have permission to assign IAM roles (requires Project Editor or Owner role).

## Solution

### Step 1: Clean Up Existing Resources (One-time)

Since the VPC network and Secret Manager secret were partially created, you need to clean them up first:

```bash
cd terraform
# Import existing resources instead of creating them again
# OR delete and recreate them via Terraform
```

**Option A: Import Existing Resources (Recommended)**
```bash
terraform import google_compute_network.postgres_network projects/ornate-producer-477604-s3/global/networks/my-postgres-network
terraform import google_secret_manager_secret.db_password_secret projects/575780339385/secrets/my-postgres-db-password
```

**Option B: Delete via GCP Console**
1. Go to: https://console.cloud.google.com/vpc/networks?project=ornate-producer-477604-s3
2. Delete the `my-postgres-network` VPC
3. Go to: https://console.cloud.google.com/security/secret-manager?project=ornate-producer-477604-s3
4. Delete the `my-postgres-db-password` secret

### Step 2: Grant IAM Roles (CRITICAL)

You **MUST** have Project Editor or Owner permissions to complete this step.

#### Option A: Via GCP Console (Easiest)

1. **Go to IAM & Admin**: https://console.cloud.google.com/iam-admin/iam?project=ornate-producer-477604-s3

2. **Find or Add the Service Account**:
   - Look for `terraform-sa@ornate-producer-477604-s3.iam.gserviceaccount.com`
   - If not listed, click **"Grant Access"** and search for it

3. **Add Required Roles** - Click the service account row and **Edit Principal**:
   - ✅ **Cloud SQL Admin** (`roles/cloudsql.admin`)
   - ✅ **Compute Network Admin** (`roles/compute.networkAdmin`)
   - ✅ **Secret Manager Admin** (`roles/secretmanager.admin`)
   - ✅ **Service Account User** (`roles/iam.serviceAccountUser`)

4. **Click "Save"**

#### Option B: Via gcloud CLI (If you have permissions)

```bash
PROJECT_ID="ornate-producer-477604-s3"
SERVICE_ACCOUNT="terraform-sa@ornate-producer-477604-s3.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:$SERVICE_ACCOUNT \
  --role=roles/cloudsql.admin

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:$SERVICE_ACCOUNT \
  --role=roles/compute.networkAdmin

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:$SERVICE_ACCOUNT \
  --role=roles/secretmanager.admin

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:$SERVICE_ACCOUNT \
  --role=roles/iam.serviceAccountUser
```

### Step 3: Remove or Fix iam.tf

The `iam.tf` file cannot be used because:
- `roles/servicenetworking.admin` is **NOT** a valid project-level role
- The service account cannot grant roles to itself without Project Editor permissions

**Option A: Disable iam.tf (Recommended)**
```bash
# Rename to disable it
mv terraform/iam.tf terraform/iam.tf.disabled
```

**Option B: Keep iam.tf Disabled in Terraform**
The `terraform.tfvars` has `GCP_SERVICE_ACCOUNT_EMAIL = ""` which disables all IAM resources in `iam.tf`.

### Step 4: Deploy Terraform

```bash
cd terraform

# Clean state of failed IAM resources
terraform state rm 'google_project_iam_member.network_admin[0]' || true
terraform state rm 'google_project_iam_member.service_networking_admin[0]' || true
terraform state rm 'google_project_iam_member.cloudsql_admin[0]' || true
terraform state rm 'google_project_iam_member.secret_manager_admin[0]' || true
terraform state rm 'google_project_iam_member.service_account_user[0]' || true
terraform state rm 'google_project_iam_member.compute_instance_admin[0]' || true

# Initialize and plan
terraform init
terraform plan

# Apply if plan looks good
terraform apply
```

## Troubleshooting

### "Policy update access denied"
- **Cause**: Your GCP account doesn't have Project Editor role
- **Fix**: Contact the project owner to grant you Project Editor role

### "Role roles/servicenetworking.admin is not supported"
- **Cause**: This is not a valid project-level IAM role
- **Fix**: Don't try to assign this role; use the Terraform resources directly instead

### "Network already exists"
- **Cause**: The network was partially created in a previous run
- **Fix**: Either delete it via GCP Console or import it with `terraform import`

### "Secret already exists"
- **Cause**: The secret was partially created in a previous run
- **Fix**: Either delete it via GCP Console or import it with `terraform import`

## Required Roles Summary

| Role | Purpose |
|------|---------|
| `roles/cloudsql.admin` | Create and manage Cloud SQL instances |
| `roles/compute.networkAdmin` | Create and manage VPC networks |
| `roles/secretmanager.admin` | Create and manage secrets |
| `roles/iam.serviceAccountUser` | Impersonate service accounts |

## GitHub Actions Configuration

Your GitHub Actions workflow uses `GCP_SA_KEY` secret which contains the service account credentials. Once the IAM roles are granted, the workflow will succeed.

## Next Steps

1. **Confirm you have Project Editor permissions** on the GCP project
2. **Grant the required IAM roles** using the GCP Console (easiest option)
3. **Run terraform commands** from the steps above
4. **Verify deployment** by checking the Cloud SQL instance in GCP Console

Need help? Check the main README.md or IAM_SETUP_GUIDE.md files.
