# Permission Resolution Guide

## Issue
The Terraform service account lacks the required permissions to create the Private Service Connection for Cloud SQL.

## Solution

### Step 1: Identify Your Service Account Email
Find the email of the service account running Terraform:
```bash
gcloud auth list
# or
gcloud config get-value account
```

### Step 2: Update terraform.tfvars
Add your service account email to `terraform/terraform.tfvars`:

```terraform
# ...existing variables...

GCP_SERVICE_ACCOUNT_EMAIL = "your-service-account@your-project.iam.gserviceaccount.com"
```

### Step 3: Grant Required IAM Roles (Option A - via gcloud)
If you have Project Editor or IAM Admin permissions:

```bash
PROJECT_ID="your-project-id"
SERVICE_ACCOUNT="your-service-account@your-project.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:$SERVICE_ACCOUNT \
  --role=roles/compute.networkAdmin

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:$SERVICE_ACCOUNT \
  --role=roles/servicenetworking.admin

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:$SERVICE_ACCOUNT \
  --role=roles/cloudsql.admin

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:$SERVICE_ACCOUNT \
  --role=roles/secretmanager.admin
```

### Step 4: Grant Required IAM Roles (Option B - via Terraform)
If you don't have gcloud access, use Terraform to grant the roles:

```bash
cd terraform
terraform apply
```

The `iam.tf` file will automatically grant all required roles if `GCP_SERVICE_ACCOUNT_EMAIL` is provided.

### Step 5: Run Terraform
After granting permissions:

```bash
cd terraform
terraform plan
terraform apply
```

## Required IAM Roles
The following roles must be granted to the service account:
- **roles/compute.networkAdmin** - For VPC, subnet, and firewall management
- **roles/servicenetworking.admin** - For Private Service Connection
- **roles/cloudsql.admin** - For Cloud SQL instance management
- **roles/secretmanager.admin** - For Secret Manager operations
- **roles/iam.serviceAccountUser** - For service account impersonation
- **roles/compute.instanceAdmin.v1** - For compute instance management

## Notes
- If you don't want to set up IAM roles via Terraform, leave `GCP_SERVICE_ACCOUNT_EMAIL` empty in terraform.tfvars
- The IAM setup will be skipped if the variable is empty
- You can manually grant roles via the GCP Console if needed
