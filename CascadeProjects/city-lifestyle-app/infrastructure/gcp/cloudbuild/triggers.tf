# Cloud Build Triggers

# Frontend Trigger
resource "google_cloudbuild_trigger" "frontend" {
  name        = "city-lifestyle-frontend-deploy"
  description = "Deploy City Lifestyle frontend on main branch changes"
  
  github {
    owner = "CEO-CityLifeStyle"
    name  = "City-LifeStyle-App"
    push {
      branch = "^main$"
      invert_regex = false
    }
  }
  
  included_files = ["frontend/**"]
  filename       = "infrastructure/gcp/cloudbuild/frontend.yaml"
  
  substitutions = {
    _ENVIRONMENT    = "production"
    _API_URL       = "https://api.${var.domain_name}"
    _STORAGE_BUCKET = "${var.project_id}-static-assets"
    _CDN_URL_MAP   = "city-lifestyle-frontend-cdn"
    _SERVICE_NAME  = "city-lifestyle-frontend"
    _REGION        = var.region
  }

  service_account = "projects/${var.project_id}/serviceAccounts/${google_service_account.cicd.email}"
}

# Backend Trigger
resource "google_cloudbuild_trigger" "backend" {
  name        = "city-lifestyle-backend-deploy"
  description = "Deploy City Lifestyle backend on main branch changes"
  
  github {
    owner = "CEO-CityLifeStyle"
    name  = "City-LifeStyle-App"
    push {
      branch = "^main$"
      invert_regex = false
    }
  }
  
  included_files = ["backend/**"]
  filename       = "infrastructure/gcp/cloudbuild/backend.yaml"
  
  substitutions = {
    _REGION          = var.region
    _REPOSITORY      = "city-lifestyle"
    _ENVIRONMENT     = "production"
    _SERVICE_NAME    = "city-lifestyle-backend"
    _SERVICE_ACCOUNT = google_service_account.backend.email
    _VPC_CONNECTOR   = "city-lifestyle-vpc-connector"
    _CLOUD_SQL_INSTANCE = "${var.project_id}:${var.region}:city-lifestyle-db"
  }

  service_account = "projects/${var.project_id}/serviceAccounts/${google_service_account.cicd.email}"
}

# Infrastructure Trigger
resource "google_cloudbuild_trigger" "terraform" {
  name        = "terraform-apply"
  description = "Apply Terraform changes on infrastructure changes"
  
  github {
    owner = "CEO-CityLifeStyle"
    name  = "City-LifeStyle-App"
    push {
      branch = "^main$"
      invert_regex = false
    }
  }
  
  included_files = [
    "infrastructure/gcp/terraform/**",
    "infrastructure/gcp/cloudbuild/**"
  ]
  filename = "infrastructure/gcp/cloudbuild/terraform.yaml"
  
  substitutions = {
    _ENVIRONMENT  = "production"
    _STATE_BUCKET = "${var.project_id}-terraform-state"
  }
}
