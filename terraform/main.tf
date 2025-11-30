terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  # Backend configuration for storing Terraform state
  # Uncomment and configure if using remote state storage
  # backend "gcs" {
  #   bucket = "your-terraform-state-bucket"
  #   prefix = "gcp-postgres"
  # }
}


provider "google" {
  project = var.GCP_PROJECT_ID
  region  = var.GCP_REGION
}

# Create a random string for unique resource naming
resource "random_string" "db_instance_suffix" {
  length  = 4
  special = false
  lower   = true
}

# Create a private VPC network for database isolation
resource "google_compute_network" "postgres_network" {
  name                    = "${var.instance_name}-network"
  auto_create_subnetworks = false

  lifecycle {
    ignore_changes = [name]
  }
}

# Create a subnet within the VPC
resource "google_compute_subnetwork" "postgres_subnet" {
  name          = "${var.instance_name}-subnet"
  ip_cidr_range = var.network_cidr
  region        = var.GCP_REGION
  network       = google_compute_network.postgres_network.id

  private_ip_google_access = true
}

# Reserve a global static IP for Private Service Connection
resource "google_compute_global_address" "postgres_private_ip" {
  name          = "${var.instance_name}-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.postgres_network.id
}

# Create Private Service Connection
resource "google_service_networking_connection" "postgres_connection" {
  network                 = google_compute_network.postgres_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.postgres_private_ip.name]

  depends_on = [
    google_compute_global_address.postgres_private_ip,
    google_project_service.servicenetworking,
    google_project_service.compute,
    google_project_service.sqladmin
  ]
}

# Enable required API services
resource "google_project_service" "servicenetworking" {
  service            = "servicenetworking.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "compute" {
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "sqladmin" {
  service            = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

# Create Cloud SQL PostgreSQL instance
resource "google_sql_database_instance" "postgres_instance" {
  name             = "${var.instance_name}-${random_string.db_instance_suffix.result}"
  database_version = var.postgres_version
  region           = var.GCP_REGION

  deletion_protection = var.deletion_protection

  settings {
    tier              = var.machine_type
    availability_type = var.availability_type
    disk_type         = var.disk_type
    disk_size         = var.disk_size
    disk_autoresize   = var.disk_autoresize

    # Backup configuration
    backup_configuration {
      enabled                        = var.enable_backups
      start_time                     = var.backup_start_time
      point_in_time_recovery_enabled = var.enable_pitr
      transaction_log_retention_days = 7
    }

    # IP configuration
    ip_configuration {
      ipv4_enabled    = var.enable_public_ip
      private_network = google_compute_network.postgres_network.id

      # Authorized networks for public access (if enabled)
      dynamic "authorized_networks" {
        for_each = var.authorized_networks
        content {
          name  = authorized_networks.value.name
          value = authorized_networks.value.cidr
        }
      }
    }

    # Database flags
    database_flags {
      name  = "cloudsql_iam_authentication"
      value = "on"
    }

    dynamic "database_flags" {
      for_each = var.database_flags
      content {
        name  = database_flags.key
        value = database_flags.value
      }
    }

    # Maintenance window
    maintenance_window {
      day          = var.maintenance_day
      hour         = var.maintenance_hour
      update_track = "stable"
    }

    # Insights configuration
    insights_config {
      query_insights_enabled  = var.enable_query_insights
      query_plans_per_minute  = 5
      query_string_length     = 1024
      record_application_tags = true
    }
  }

  depends_on = [google_service_networking_connection.postgres_connection]
}

# Create default database
resource "google_sql_database" "default_database" {
  name     = var.database_name
  instance = google_sql_database_instance.postgres_instance.name

  depends_on = [google_sql_database_instance.postgres_instance]
}

# Create database user
resource "google_sql_user" "db_user" {
  name     = var.db_username
  instance = google_sql_database_instance.postgres_instance.name
  password = random_password.db_password.result
}

# Generate random password for database user
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# Manage password secret in Google Secret Manager
resource "google_secret_manager_secret" "db_password_secret" {
  secret_id = "${var.instance_name}-db-password"

  replication {
    auto {}
  }

  lifecycle {
    ignore_changes = [replication, secret_id]
    prevent_destroy = false
  }

  depends_on = [google_project_service.secretmanager]
}

# Enable Secret Manager API
resource "google_project_service" "secretmanager" {
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_secret_manager_secret_version" "db_password_secret_version" {
  secret      = google_secret_manager_secret.db_password_secret.id
  secret_data = random_password.db_password.result

  lifecycle {
    ignore_changes = [secret_data]
  }
}

# Create firewall rule for private network access
resource "google_compute_firewall" "postgres_internal" {
  name    = "${var.instance_name}-internal-rule"
  network = google_compute_network.postgres_network.name

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  source_ranges = [var.network_cidr]
  target_tags   = ["postgres-client"]
}
