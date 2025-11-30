# IAM roles required for Terraform service account
# Only create these if GCP_SERVICE_ACCOUNT_EMAIL is provided

# Role for networking operations
resource "google_project_iam_member" "network_admin" {
  count   = var.GCP_SERVICE_ACCOUNT_EMAIL != "" ? 1 : 0
  project = var.GCP_PROJECT_ID
  role    = "roles/compute.networkAdmin"
  member  = "serviceAccount:${var.GCP_SERVICE_ACCOUNT_EMAIL}"
}

# Role for Private Service Connection
resource "google_project_iam_member" "service_networking_admin" {
  count   = var.GCP_SERVICE_ACCOUNT_EMAIL != "" ? 1 : 0
  project = var.GCP_PROJECT_ID
  role    = "roles/servicenetworking.admin"
  member  = "serviceAccount:${var.GCP_SERVICE_ACCOUNT_EMAIL}"
}

# Role for Cloud SQL administration
resource "google_project_iam_member" "cloudsql_admin" {
  count   = var.GCP_SERVICE_ACCOUNT_EMAIL != "" ? 1 : 0
  project = var.GCP_PROJECT_ID
  role    = "roles/cloudsql.admin"
  member  = "serviceAccount:${var.GCP_SERVICE_ACCOUNT_EMAIL}"
}

# Role for Secret Manager
resource "google_project_iam_member" "secret_manager_admin" {
  count   = var.GCP_SERVICE_ACCOUNT_EMAIL != "" ? 1 : 0
  project = var.GCP_PROJECT_ID
  role    = "roles/secretmanager.admin"
  member  = "serviceAccount:${var.GCP_SERVICE_ACCOUNT_EMAIL}"
}

# Role for Service Account user
resource "google_project_iam_member" "service_account_user" {
  count   = var.GCP_SERVICE_ACCOUNT_EMAIL != "" ? 1 : 0
  project = var.GCP_PROJECT_ID
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${var.GCP_SERVICE_ACCOUNT_EMAIL}"
}

# Role for Compute Instance Admin
resource "google_project_iam_member" "compute_instance_admin" {
  count   = var.GCP_SERVICE_ACCOUNT_EMAIL != "" ? 1 : 0
  project = var.GCP_PROJECT_ID
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:${var.GCP_SERVICE_ACCOUNT_EMAIL}"
}

