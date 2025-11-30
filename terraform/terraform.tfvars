# GCP Configuration
GCP_PROJECT_ID = var.GCP_PROJECT_ID
GCP_REGION     = var.GCP_REGION


# PostgreSQL Instance Configuration
instance_name     = "my-postgres"
postgres_version  = "POSTGRES_15"
machine_type      = "db-f1-micro"
availability_type = "REGIONAL"
disk_type         = "PD_SSD"
disk_size         = 20
disk_autoresize   = true

# Backup Configuration
enable_backups    = true
backup_start_time = "03:00"
enable_pitr       = true

# Network Configuration
network_cidr     = "10.0.0.0/24"
enable_public_ip = false

# Security
deletion_protection = false

# Database Configuration
database_name = "postgres"
db_username   = "postgres"

# Maintenance
maintenance_day  = 7 # Sunday
maintenance_hour = 3 # 3 AM

# Monitoring
enable_query_insights = true

# Database Flags
database_flags = {
  "max_connections" = "100"
}

# Authorized Networks (for public access, if enabled)
# authorized_networks = [
#   {
#     name = "office"
#     cidr = "203.0.113.0/24"
#   }
# ]
