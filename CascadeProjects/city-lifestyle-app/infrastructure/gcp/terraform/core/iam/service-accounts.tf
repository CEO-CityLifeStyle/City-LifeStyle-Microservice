# Service Accounts

# Frontend Service Account
resource "google_service_account" "frontend" {
  account_id   = "city-lifestyle-frontend"
  display_name = "City Lifestyle Frontend Service Account"
  description  = "Service account for frontend services in City Lifestyle App"
}

resource "google_project_iam_member" "frontend_roles" {
  for_each = toset([
    "roles/storage.objectViewer",
    "roles/cloudcdn.admin",
    "roles/firebase.admin",
    google_project_iam_custom_role.frontend.id
  ])
  
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.frontend.email}"
}

# Backend Service Account
resource "google_service_account" "backend" {
  account_id   = "city-lifestyle-backend"
  display_name = "City Lifestyle Backend Service Account"
  description  = "Service account for backend services in City Lifestyle App"
}

resource "google_project_iam_member" "backend_roles" {
  for_each = toset([
    "roles/cloudsql.client",
    "roles/secretmanager.secretAccessor",
    "roles/pubsub.publisher",
    "roles/pubsub.subscriber",
    "roles/firebase.admin",
    google_project_iam_custom_role.backend.id
  ])
  
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.backend.email}"
}

# CI/CD Service Account
resource "google_service_account" "cicd" {
  account_id   = "city-lifestyle-cicd"
  display_name = "City Lifestyle CI/CD Service Account"
  description  = "Service account for CI/CD pipelines in City Lifestyle App"
}

resource "google_project_iam_member" "cicd_roles" {
  for_each = toset([
    "roles/cloudbuild.builds.builder",
    "roles/storage.admin",
    "roles/container.developer",
    "roles/cloudrun.admin",
    "roles/secretmanager.secretAccessor",
    "roles/firebase.admin"
  ])
  
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.cicd.email}"
}

# Workload Identity bindings for GitHub Actions
resource "google_service_account_iam_binding" "workload_identity_user" {
  service_account_id = google_service_account.cicd.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "principalSet://iam.googleapis.com/projects/${var.project_number}/locations/global/workloadIdentityPools/github-pool/attribute.repository/Qahtani1979/City-LifeStyle-App"
  ]
}
