# Pre-requisites

Before deploying PostgreSQL on GCP using this Terraform configuration, ensure you have:

## 1. GCP Setup
- An active GCP project with billing enabled
- GCP CLI (`gcloud`) installed and authenticated
- Required APIs enabled:
  - Cloud SQL Admin API
  - Service Networking API
  - Secret Manager API
  - Compute Engine API

Enable APIs with:
```bash
gcloud services enable sqladmin.googleapis.com
gcloud services enable servicenetworking.googleapis.com
gcloud services enable secretmanager.googleapis.com
gcloud services enable compute.googleapis.com
```

## 2. Service Account Setup

Create a GCP Service Account for Terraform:

```bash
# Create service account
gcloud iam service-accounts create terraform-postgres \
  --display-name="Terraform PostgreSQL Deployment"

# Get service account email
SA_EMAIL=$(gcloud iam service-accounts list --filter="displayName:Terraform PostgreSQL Deployment" --format='value(email)')

# Grant required roles
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member=serviceAccount:$SA_EMAIL \
  --role=roles/cloudsql.admin

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member=serviceAccount:$SA_EMAIL \
  --role=roles/compute.networkAdmin

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member=serviceAccount:$SA_EMAIL \
  --role=roles/secretmanager.admin

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member=serviceAccount:$SA_EMAIL \
  --role=roles/iam.serviceAccountUser

# Create and download JSON key
gcloud iam service-accounts keys create terraform-key.json \
  --iam-account=$SA_EMAIL
```

## 3. GitHub Repository Setup

### Add Secrets to GitHub

1. Go to your GitHub repository
2. Navigate to **Settings → Secrets and variables → Actions**
3. Add the following secrets:

- `GCP_SA_KEY`: Contents of `terraform-key.json` (base64 encoded or raw JSON)
- `GCP_PROJECT_ID`: Your GCP Project ID
- `SLACK_WEBHOOK_URL` (Optional): For Slack notifications

### Example:
```bash
# Get base64 encoded service account key
cat terraform-key.json | base64
```

## 4. Local Development Setup

### Install Required Tools
```bash
# Install Terraform
brew install terraform

# Install Google Cloud SDK
brew install google-cloud-sdk

# Install PostgreSQL Client
brew install postgresql
```

### Initialize Terraform
```bash
cd terraform
terraform init
```

### Validate Configuration
```bash
terraform validate
```

### Format Code
```bash
terraform fmt -recursive
```

## 5. Terraform State Management (Optional but Recommended)

Create a GCS bucket for remote state:

```bash
# Create bucket
gsutil mb gs://${PROJECT_ID}-terraform-state

# Enable versioning
gsutil versioning set on gs://${PROJECT_ID}-terraform-state

# Update backend in main.tf:
# backend "gcs" {
#   bucket = "your-terraform-state-bucket"
#   prefix = "gcp-postgres"
# }
```

## 6. Deployment Workflow

### Local Deployment
```bash
cd terraform

# Plan
terraform plan -out=tfplan

# Apply
terraform apply tfplan

# Get outputs
terraform output
```

### CI/CD Deployment
1. Commit changes to `main` branch
2. GitHub Actions will automatically:
   - Run `terraform plan`
   - Comment on PR with plan (if PR)
   - Apply on merge to main
   - Test database connection
   - Send Slack notification

## Security Best Practices

1. **Never commit sensitive data** (keys, passwords) to Git
2. **Use Secrets Manager** for database credentials
3. **Enable deletion protection** on production instances
4. **Use Private IP** for databases (not public internet)
5. **Enable backups and PITR** for production
6. **Regularly rotate service account keys**
7. **Use branch protection rules** on main branch
8. **Review Terraform plans** before applying
9. **Enable audit logging** in GCP
10. **Use IAM roles with least privilege**
