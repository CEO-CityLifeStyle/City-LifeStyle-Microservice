# Cloud SQL Configuration

# Primary Database Instance
resource "google_sql_database_instance" "primary" {
  name             = "city-lifestyle-db-${var.environment}"
  database_version = "POSTGRES_14"
  region           = var.region
  project          = var.project_id

  settings {
    tier = var.environment == "production" ? "db-custom-4-16384" : "db-f1-micro"
    
    availability_type = var.environment == "production" ? "REGIONAL" : "ZONAL"
    
    backup_configuration {
      enabled                        = true
      start_time                    = "02:00"
      location                      = var.region
      point_in_time_recovery_enabled = var.environment == "production"
      transaction_log_retention_days = 7
      backup_retention_settings {
        retained_backups = 7
        retention_unit  = "COUNT"
      }
    }
    
    ip_configuration {
      ipv4_enabled    = false
      private_network = var.vpc_id
      require_ssl     = true
    }
    
    database_flags {
      name  = "max_connections"
      value = var.environment == "production" ? "100" : "50"
    }

    database_flags {
      name  = "log_min_duration_statement"
      value = "1000"
    }
    
    maintenance_window {
      day          = 7    # Sunday
      hour         = 3    # 3 AM
      update_track = "stable"
    }
  }

  deletion_protection = var.environment == "production"
}

# Database
resource "google_sql_database" "database" {
  name     = "city_lifestyle"
  instance = google_sql_database_instance.primary.name
  project  = var.project_id
}

# Database Users
resource "google_sql_user" "application" {
  name     = "city_lifestyle_app"
  instance = google_sql_database_instance.primary.name
  project  = var.project_id
  password = random_password.db_password.result
}

resource "google_sql_user" "readonly" {
  name     = "city_lifestyle_readonly"
  instance = google_sql_database_instance.primary.name
  project  = var.project_id
  password = random_password.readonly_password.result
}

# Generate random passwords
resource "random_password" "db_password" {
  length  = 32
  special = true
}

resource "random_password" "readonly_password" {
  length  = 32
  special = true
}

# Store passwords in Secret Manager
resource "google_secret_manager_secret" "db_password" {
  secret_id = "db-password-${var.environment}"
  project   = var.project_id

  replication {
    automatic = true
  }

  labels = {
    environment = var.environment
    service     = "database"
  }
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}

resource "google_secret_manager_secret" "readonly_password" {
  secret_id = "db-readonly-password-${var.environment}"
  project   = var.project_id

  replication {
    automatic = true
  }

  labels = {
    environment = var.environment
    service     = "database"
  }
}

resource "google_secret_manager_secret_version" "readonly_password" {
  secret      = google_secret_manager_secret.readonly_password.id
  secret_data = random_password.readonly_password.result
}

# Outputs
output "instance_name" {
  value = google_sql_database_instance.primary.name
}

output "connection_name" {
  value = google_sql_database_instance.primary.connection_name
}

output "database_name" {
  value = google_sql_database.database.name
}
