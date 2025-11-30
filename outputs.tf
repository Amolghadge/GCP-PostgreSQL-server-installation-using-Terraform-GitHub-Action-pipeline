output "instance_name" {
  description = "Name of the Cloud SQL PostgreSQL instance"
  value       = google_sql_database_instance.postgres_instance.name
}

output "instance_connection_name" {
  description = "Connection name for the PostgreSQL instance (for Cloud SQL Proxy)"
  value       = google_sql_database_instance.postgres_instance.connection_name
}

output "private_ip_address" {
  description = "Private IP address of the PostgreSQL instance"
  value       = google_sql_database_instance.postgres_instance.private_ip_address
}

output "public_ip_address" {
  description = "Public IP address of the PostgreSQL instance"
  value       = google_sql_database_instance.postgres_instance.public_ip_address
}

output "database_name" {
  description = "Name of the default database"
  value       = google_sql_database.default_database.name
}

output "database_username" {
  description = "Database username"
  value       = google_sql_user.db_user.name
}

output "database_password_secret" {
  description = "Secret Manager secret ID containing the database password"
  value       = google_secret_manager_secret.db_password_secret.id
}

output "database_password" {
  description = "Database password (sensitive)"
  value       = random_password.db_password.result
  sensitive   = true
}

output "vpc_network_id" {
  description = "VPC network ID"
  value       = google_compute_network.postgres_network.id
}

output "vpc_subnet_id" {
  description = "VPC subnet ID"
  value       = google_compute_subnetwork.postgres_subnet.id
}

output "connection_string" {
  description = "PostgreSQL connection string"
  value       = "postgresql://${google_sql_user.db_user.name}:${random_password.db_password.result}@${google_sql_database_instance.postgres_instance.private_ip_address}:5432/${google_sql_database.default_database.name}"
  sensitive   = true
}
