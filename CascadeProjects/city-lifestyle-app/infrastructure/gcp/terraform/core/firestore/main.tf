# Firestore Configuration

# Enable Firestore API
resource "google_project_service" "firestore" {
  project = var.project_id
  service = "firestore.googleapis.com"

  disable_dependent_services = true
  disable_on_destroy        = false
}

# Firestore Database
resource "google_firestore_database" "database" {
  project     = var.project_id
  name        = "(default)"
  location_id = var.region
  type        = "FIRESTORE_NATIVE"

  depends_on = [google_project_service.firestore]
}

# Firestore Index Configuration
resource "google_firestore_index" "events_index" {
  project = var.project_id
  database = google_firestore_database.database.name
  collection = "events"

  fields {
    field_path = "category"
    order      = "ASCENDING"
  }
  fields {
    field_path = "date"
    order      = "ASCENDING"
  }
}

resource "google_firestore_index" "places_index" {
  project = var.project_id
  database = google_firestore_database.database.name
  collection = "places"

  fields {
    field_path = "location"
    order      = "ASCENDING"
  }
  fields {
    field_path = "rating"
    order      = "DESCENDING"
  }
}

# IAM Configuration
resource "google_project_iam_binding" "firestore_user" {
  project = var.project_id
  role    = "roles/datastore.user"

  members = [
    "serviceAccount:${var.backend_service_account}",
    "serviceAccount:${var.analytics_service_account}"
  ]
}

# Backup Configuration (if using Firestore native mode)
resource "google_firestore_backup_schedule" "daily_backup" {
  count    = var.environment == "prod" ? 1 : 0
  project  = var.project_id
  database = google_firestore_database.database.name
  location = var.region

  retention_days = 14
  schedule      = "0 0 * * *" # Daily at midnight

  backup_config {
    collection_ids = ["events", "places", "users"]
  }
}

# Outputs
output "database_name" {
  value = google_firestore_database.database.name
}

output "database_id" {
  value = google_firestore_database.database.id
}
