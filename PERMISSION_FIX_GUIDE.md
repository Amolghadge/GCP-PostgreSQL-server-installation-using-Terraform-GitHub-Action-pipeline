# GCP Permission Issues - Resolution Guide

## Problem Summary

You're encountering two main issues:

1. **Permission Denied for Service Networking**: `servicenetworking.googleapis.com`
   - Error: "Permission denied to add peering for service 'servicenetworking.googleapis.com'"
   - Missing: `roles/servicenetworking.admin` role (or equivalent permissions)

2. **Permission Denied for Secret Manager**: `secretmanager.versions.access`
   - Error: "Permission 'secretmanager.versions.access' denied"
   - Missing: `roles/secretmanager.admin` or `roles/secretmanager.secretAccessor` role

## Root Cause

The service account `terraform-sa@ornate-producer-477604-s3.iam.gserviceaccount.com` is missing required IAM roles. 

**IMPORTANT**: Your personal GCP account (`amolgcp02@gmail.com`) does NOT have Project Editor permissions, so you cannot assign roles yourself.

## Solution - Two Paths

### Path A: Project Owner Grants You Permissions (Recommended)

**Who**: Someone with Project Owner or Editor role must do this

**Steps**:
1. Ask the project owner to grant you **Project Editor** role on project `ornate-producer-477604-s3`
2. Once granted, you can run terraform yourself

OR share the script `scripts/grant-iam-roles.sh` with them to run

---

### Path B: Project Owner Grants Roles to Service Account (Fastest)

**Who**: Someone with Project Owner or Editor role

**Option B1: Run the provided script**
```bash
bash scripts/grant-iam-roles.sh
```

**Option B2: Run commands manually via gcloud**
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

**Option B3: Via GCP Console**
1. Go to: **https://console.cloud.google.com/iam-admin/iam?project=ornate-producer-477604-s3**
2. Click **Grant Access**
3. Enter service account: `terraform-sa@ornate-producer-477604-s3.iam.gserviceaccount.com`
4. Add roles:
   - ✅ **Cloud SQL Admin** (`roles/cloudsql.admin`)
   - ✅ **Compute Network Admin** (`roles/compute.networkAdmin`)
   - ✅ **Secret Manager Admin** (`roles/secretmanager.admin`)
   - ✅ **Service Account User** (`roles/iam.serviceAccountUser`)
5. Click **Save**

---

## Current Status

Your account: `amolai0126@gmail.com`  
Current permissions on project: **NONE** (you cannot assign IAM roles)

Service account: `terraform-sa@ornate-producer-477604-s3.iam.gserviceaccount.com`  
Current roles: **MISSING** (this is why Terraform fails)

## Troubleshooting

### "Policy update access denied"
- **Cause**: Your GCP account doesn't have Project Editor role
- **Fix**: Contact the project owner to grant you Project Editor role OR ask them to run the role-granting commands

### "Role roles/servicenetworking.admin is not supported"
- **Cause**: This is not a valid project-level IAM role in older GCP versions
- **Fix**: Use the provided script or manual commands above instead

### "Network already exists"
- **Cause**: The network was partially created in a previous run
- **Fix**: Either delete it via GCP Console or import it with `terraform import`

### "Secret already exists"
- **Cause**: The secret was partially created in a previous run
- **Fix**: Either delete it via GCP Console or import it with `terraform import`

## After Roles Are Granted

Once someone with Project Editor permissions has granted the roles:

```bash
cd terraform

# Verify roles were granted (you may still not be able to see them)
# But Terraform will work because the service account has them

# Clean up any failed state
terraform state rm 'google_project_iam_member.network_admin[0]' 2>/dev/null || true

# Deploy
terraform init
terraform plan
terraform apply
```

## GitHub Actions Deployment

Once roles are granted, your GitHub Actions workflow will succeed automatically because:
- GitHub Actions uses the `GCP_SA_KEY` secret to authenticate
- The service account in that key will have the required permissions
- Terraform will be able to create all resources

## Required Roles Summary

| Role | Purpose | Why Needed |
|------|---------|-----------|
| `roles/cloudsql.admin` | Create and manage Cloud SQL instances | To create the PostgreSQL database |
| `roles/compute.networkAdmin` | Create and manage VPC networks | To create the private VPC network |
| `roles/secretmanager.admin` | Create and manage secrets | To store the database password |
| `roles/iam.serviceAccountUser` | Impersonate service accounts | For Terraform to assume the service account role |

## Contact Project Owner

If you need to contact your GCP project owner, provide them this information:

**To Grant Permissions:**

```bash
PROJECT_ID="ornate-producer-477604-s3"
SERVICE_ACCOUNT="terraform-sa@ornate-producer-477604-s3.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding $PROJECT_ID --member=serviceAccount:$SERVICE_ACCOUNT --role=roles/cloudsql.admin
gcloud projects add-iam-policy-binding $PROJECT_ID --member=serviceAccount:$SERVICE_ACCOUNT --role=roles/compute.networkAdmin
gcloud projects add-iam-policy-binding $PROJECT_ID --member=serviceAccount:$SERVICE_ACCOUNT --role=roles/secretmanager.admin
gcloud projects add-iam-policy-binding $PROJECT_ID --member=serviceAccount:$SERVICE_ACCOUNT --role=roles/iam.serviceAccountUser
```

OR use the bash script: `scripts/grant-iam-roles.sh`

OR use GCP Console: https://console.cloud.google.com/iam-admin/iam?project=ornate-producer-477604-s3
