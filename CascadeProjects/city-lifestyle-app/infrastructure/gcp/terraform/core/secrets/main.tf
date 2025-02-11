# Secret Manager Configuration

# Database Credentials
resource "google_secret_manager_secret" "db_credentials" {
  secret_id = "db-credentials"
  
  replication {
    automatic = true
  }

  labels = {
    environment = var.environment
    service     = "database"
  }
}

# API Keys
resource "google_secret_manager_secret" "api_keys" {
  secret_id = "api-keys"
  
  replication {
    automatic = true
  }

  labels = {
    environment = var.environment
    service     = "api"
  }
}

# JWT Secret
resource "google_secret_manager_secret" "jwt_secret" {
  secret_id = "jwt-secret"
  
  replication {
    automatic = true
  }

  labels = {
    environment = var.environment
    service     = "auth"
  }
}

# Service Account Keys
resource "google_secret_manager_secret" "service_account_keys" {
  secret_id = "service-account-keys"
  
  replication {
    automatic = true
  }

  labels = {
    environment = var.environment
    service     = "auth"
  }
}

# IAM Bindings
resource "google_secret_manager_secret_iam_binding" "backend_access" {
  for_each  = toset([
    google_secret_manager_secret.db_credentials.id,
    google_secret_manager_secret.api_keys.id,
    google_secret_manager_secret.jwt_secret.id
  ])
  
  project   = var.project_id
  secret_id = each.key
  role      = "roles/secretmanager.secretAccessor"
  members   = [
    "serviceAccount:${var.backend_service_account}",
    "serviceAccount:${var.cicd_service_account}"
  ]
}

# Outputs
output "secrets" {
  value = {
    db_credentials_id = google_secret_manager_secret.db_credentials.id
    api_keys_id      = google_secret_manager_secret.api_keys.id
    jwt_secret_id    = google_secret_manager_secret.jwt_secret.id
  }
  description = "Secret IDs for reference in other resources"
}
