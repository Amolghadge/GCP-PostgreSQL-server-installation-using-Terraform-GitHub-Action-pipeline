variable "GCP_PROJECT_ID" {
  description = "GCP Project ID"
  type        = string
}

variable "gGCP_REGION" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "instance_name" {
  description = "Name of the Cloud SQL PostgreSQL instance"
  type        = string
  default     = "postgres"
}

variable "postgres_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "POSTGRES_15"
}

variable "machine_type" {
  description = "Machine type for the database instance"
  type        = string
  default     = "db-f1-micro"
}

variable "availability_type" {
  description = "Availability type (REGIONAL for HA, ZONAL for single zone)"
  type        = string
  default     = "REGIONAL"
}

variable "disk_type" {
  description = "Disk type (PD_SSD or PD_HDD)"
  type        = string
  default     = "PD_SSD"
}

variable "disk_size" {
  description = "Initial disk size in GB"
  type        = number
  default     = 20
}

variable "disk_autoresize" {
  description = "Enable automatic disk resizing"
  type        = bool
  default     = true
}

variable "enable_backups" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

variable "backup_start_time" {
  description = "Start time for backups (HH:MM format)"
  type        = string
  default     = "03:00"
}

variable "enable_pitr" {
  description = "Enable point-in-time recovery"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "database_name" {
  description = "Name of the default database"
  type        = string
  default     = "postgres"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "postgres"
}

variable "network_cidr" {
  description = "CIDR range for the VPC network"
  type        = string
  default     = "10.0.0.0/24"
}

variable "enable_public_ip" {
  description = "Enable public IP for the database instance"
  type        = bool
  default     = false
}

variable "authorized_networks" {
  description = "List of authorized networks for public access"
  type = list(object({
    name = string
    cidr = string
  }))
  default = []
}

variable "database_flags" {
  description = "Database flags for PostgreSQL"
  type        = map(string)
  default = {
    "max_connections" = "100"
  }
}

variable "maintenance_day" {
  description = "Day of week for maintenance window (1-7, where 1 is Sunday)"
  type        = number
  default     = 7
}

variable "maintenance_hour" {
  description = "Hour of day for maintenance window (0-23)"
  type        = number
  default     = 3
}

variable "enable_query_insights" {
  description = "Enable Query Insights for performance monitoring"
  type        = bool
  default     = true
}
