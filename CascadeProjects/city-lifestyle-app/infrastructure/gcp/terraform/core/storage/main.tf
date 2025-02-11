# Storage Configuration

# Frontend Static Assets Bucket
resource "google_storage_bucket" "frontend" {
  name          = "${var.project_id}-frontend-assets"
  location      = var.region
  force_destroy = false

  uniform_bucket_level_access = true
  
  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }

  cors {
    origin          = var.allowed_origins
    method          = ["GET", "HEAD", "OPTIONS"]
    response_header = ["*"]
    max_age_seconds = 3600
  }

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      num_newer_versions = 3
    }
    action {
      type = "Delete"
    }
  }
}

# User Uploads Bucket
resource "google_storage_bucket" "uploads" {
  name          = "${var.project_id}-user-uploads"
  location      = var.region
  force_destroy = false

  uniform_bucket_level_access = true

  cors {
    origin          = var.allowed_origins
    method          = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    response_header = ["*"]
    max_age_seconds = 3600
  }

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 90  # 90 days
    }
    action {
      type = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 365  # 1 year
    }
    action {
      type = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }
}

# Application Backups Bucket
resource "google_storage_bucket" "backups" {
  name          = "${var.project_id}-backups"
  location      = var.region
  force_destroy = false

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 30  # 30 days
    }
    action {
      type = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 90  # 90 days
    }
    action {
      type = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  retention_policy {
    is_locked = true
    retention_period = 2592000  # 30 days
  }
}

# IAM Bindings
resource "google_storage_bucket_iam_binding" "frontend_public" {
  bucket = google_storage_bucket.frontend.name
  role   = "roles/storage.objectViewer"
  members = ["allUsers"]
}

resource "google_storage_bucket_iam_binding" "uploads_backend" {
  bucket = google_storage_bucket.uploads.name
  role   = "roles/storage.objectAdmin"
  members = [
    "serviceAccount:${var.backend_service_account}"
  ]
}

resource "google_storage_bucket_iam_binding" "backups_admin" {
  bucket = google_storage_bucket.backups.name
  role   = "roles/storage.admin"
  members = [
    "serviceAccount:${var.backend_service_account}",
    "serviceAccount:${var.cicd_service_account}"
  ]
}

# Outputs
output "bucket_names" {
  value = {
    frontend = google_storage_bucket.frontend.name
    uploads  = google_storage_bucket.uploads.name
    backups  = google_storage_bucket.backups.name
  }
  description = "Bucket names for reference in other resources"
}
