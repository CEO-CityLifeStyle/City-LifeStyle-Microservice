# Cloud Spanner Configuration

# Spanner Instance
resource "google_spanner_instance" "main" {
  name         = "city-lifestyle-${var.environment}"
  config       = "regional-${var.region}"
  display_name = "City Lifestyle Spanner Instance"
  project      = var.project_id
  num_nodes    = var.environment == "prod" ? 3 : 1

  labels = {
    environment = var.environment
    service     = "spanner"
  }
}

# Spanner Database
resource "google_spanner_database" "main" {
  instance = google_spanner_instance.main.name
  name     = "city_lifestyle_${var.environment}"
  project  = var.project_id

  deletion_protection = var.environment == "prod"

  version_retention_period = "7d"
  ddl = [
    file("${path.module}/schemas/users.sql"),
    file("${path.module}/schemas/events.sql"),
    file("${path.module}/schemas/places.sql")
  ]
}

# IAM Configuration
resource "google_spanner_database_iam_binding" "database" {
  instance = google_spanner_instance.main.name
  database = google_spanner_database.main.name
  project  = var.project_id
  role     = "roles/spanner.databaseUser"

  members = [
    "serviceAccount:${var.backend_service_account}",
    "serviceAccount:${var.analytics_service_account}"
  ]
}

# Backup Configuration
resource "google_spanner_database_backup" "backup" {
  count     = var.environment == "prod" ? 1 : 0
  instance  = google_spanner_instance.main.name
  database  = google_spanner_database.main.name
  backup_id = "scheduled-backup"
  project   = var.project_id

  expire_time = timeadd(timestamp(), "168h") # 7 days retention

  lifecycle {
    prevent_destroy = true
  }
}

# Outputs
output "instance_id" {
  value = google_spanner_instance.main.id
}

output "database_id" {
  value = google_spanner_database.main.id
}

output "database_name" {
  value = google_spanner_database.main.name
}
