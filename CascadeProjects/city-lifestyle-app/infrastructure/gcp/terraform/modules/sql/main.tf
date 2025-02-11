# Cloud SQL Module

variable "project_id" {}
variable "region" {}
variable "instance_name" {}
variable "database_version" {
  default = "POSTGRES_13"
}
variable "tier" {
  default = "db-f1-micro"
}
variable "disk_size" {
  default = 10
}
variable "database_flags" {
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}
variable "backup_configuration" {
  type = object({
    enabled                        = bool
    start_time                    = string
    location                      = string
    point_in_time_recovery_enabled = bool
    transaction_log_retention_days = number
    retained_backups              = number
    retention_unit                = string
  })
  default = {
    enabled                        = true
    start_time                    = "02:00"
    location                      = "us-central1"
    point_in_time_recovery_enabled = true
    transaction_log_retention_days = 7
    retained_backups              = 7
    retention_unit                = "COUNT"
  }
}

resource "google_sql_database_instance" "instance" {
  name             = var.instance_name
  project          = var.project_id
  region           = var.region
  database_version = var.database_version

  settings {
    tier = var.tier
    
    disk_size = var.disk_size
    disk_type = "PD_SSD"
    
    availability_type = "REGIONAL"
    
    backup_configuration {
      enabled                        = var.backup_configuration.enabled
      start_time                    = var.backup_configuration.start_time
      location                      = var.backup_configuration.location
      point_in_time_recovery_enabled = var.backup_configuration.point_in_time_recovery_enabled
      transaction_log_retention_days = var.backup_configuration.transaction_log_retention_days
      backup_retention_settings {
        retained_backups = var.backup_configuration.retained_backups
        retention_unit  = var.backup_configuration.retention_unit
      }
    }
    
    ip_configuration {
      ipv4_enabled = true
      require_ssl  = true
    }
    
    dynamic "database_flags" {
      for_each = var.database_flags
      content {
        name  = database_flags.value.name
        value = database_flags.value.value
      }
    }
    
    maintenance_window {
      day          = 7    # Sunday
      hour         = 3    # 3 AM
      update_track = "stable"
    }
  }

  deletion_protection = true
}

# Create database
resource "google_sql_database" "database" {
  name     = "city_lifestyle"
  instance = google_sql_database_instance.instance.name
  project  = var.project_id
}

# Create user
resource "google_sql_user" "user" {
  name     = "city_lifestyle_app"
  instance = google_sql_database_instance.instance.name
  project  = var.project_id
  password = random_password.db_password.result
}

# Generate random password
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# Store password in Secret Manager
resource "google_secret_manager_secret" "db_password" {
  secret_id = "db-password"
  project   = var.project_id

  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}

output "instance_name" {
  value = google_sql_database_instance.instance.name
}

output "connection_name" {
  value = google_sql_database_instance.instance.connection_name
}

output "database_name" {
  value = google_sql_database.database.name
}

output "password_secret_id" {
  value = google_secret_manager_secret.db_password.secret_id
}
