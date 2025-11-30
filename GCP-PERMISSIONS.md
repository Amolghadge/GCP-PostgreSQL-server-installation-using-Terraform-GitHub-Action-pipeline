# GCP Service Account Permissions Required

## Error: Permission denied for service networking peering

The service account used by GitHub Actions needs the following IAM roles to successfully deploy the PostgreSQL instance with private networking:

### Required Roles:

1. **Service Networking Admin** - `roles/servicenetworking.admin`
   - Allows creating and managing Private Service Connections
   - Required for: `google_service_networking_connection` resource

2. **Cloud SQL Admin** - `roles/cloudsql.admin`
   - Allows creating and managing Cloud SQL instances
   - Required for: `google_sql_database_instance`, `google_sql_database`, `google_sql_user` resources

3. **Compute Network Admin** - `roles/compute.networkAdmin`
   - Allows managing VPC networks and firewall rules
   - Required for: `google_compute_network`, `google_compute_subnetwork`, `google_compute_firewall` resources

4. **Secret Manager Admin** - `roles/secretmanager.admin`
   - Allows managing secrets
   - Required for: `google_secret_manager_secret` resources

### How to Grant Permissions:

#### Option 1: Using gcloud CLI

```bash
PROJECT_ID="ornate-producer-477604-s3"
SERVICE_ACCOUNT_EMAIL="your-service-account@${PROJECT_ID}.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/servicenetworking.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/cloudsql.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/compute.networkAdmin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/secretmanager.admin"
```

#### Option 2: Using Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to **IAM & Admin** → **IAM**
3. Find your service account in the list
4. Click the Edit button (pencil icon)
5. Click **Add Another Role** and add each of the roles listed above

### Enable Required APIs:

Make sure these APIs are enabled in your GCP project:

```bash
gcloud services enable \
  servicenetworking.googleapis.com \
  sqladmin.googleapis.com \
  compute.googleapis.com \
  secretmanager.googleapis.com
```

## Error: Secret already exists

If you get an error that the secret already exists, you have two options:

### Option 1: Delete the existing secret first

```bash
gcloud secrets delete my-postgres-db-password --quiet
```

Then run Terraform again.

### Option 2: Import the existing secret into Terraform state

```bash
terraform import google_secret_manager_secret.db_password_secret projects/PROJECT_ID/secrets/my-postgres-db-password
```

Replace `PROJECT_ID` with your actual GCP project ID.

## Verification

After granting permissions, verify by running:

```bash
cd terraform
terraform plan
```

This will show you what resources will be created without making any actual changes.
