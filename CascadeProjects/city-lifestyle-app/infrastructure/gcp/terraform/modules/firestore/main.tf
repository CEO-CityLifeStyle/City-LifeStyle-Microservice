# Firestore Module

variable "project_id" {
  description = "The project ID to deploy to"
  type        = string
}

variable "environment" {
  description = "The environment (dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "The region to deploy to"
  type        = string
}

variable "database_id" {
  description = "The ID of the Firestore database"
  type        = string
  default     = "(default)"
}

variable "indexes" {
  description = "Map of collection indexes to create"
  type = map(object({
    collection = string
    fields = list(object({
      field_path = string
      order      = string
    }))
  }))
  default = {}
}

variable "service_accounts" {
  description = "List of service accounts to grant access"
  type        = list(string)
  default     = []
}

# Database
resource "google_firestore_database" "database" {
  project     = var.project_id
  name        = var.database_id
  location_id = var.region
  type        = "FIRESTORE_NATIVE"

  concurrency_mode = var.environment == "prod" ? "OPTIMISTIC" : "PESSIMISTIC"
}

# Indexes
resource "google_firestore_index" "indexes" {
  for_each = var.indexes
  
  project    = var.project_id
  database   = google_firestore_database.database.name
  collection = each.value.collection

  dynamic "fields" {
    for_each = each.value.fields
    content {
      field_path = fields.value.field_path
      order      = fields.value.order
    }
  }
}

# IAM
resource "google_project_iam_binding" "firestore_user" {
  count   = length(var.service_accounts) > 0 ? 1 : 0
  project = var.project_id
  role    = "roles/datastore.user"

  members = [for sa in var.service_accounts : "serviceAccount:${sa}"]
}

# Backup Schedule (Prod only)
resource "google_firestore_backup_schedule" "backup" {
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

output "index_ids" {
  value = {
    for k, v in google_firestore_index.indexes : k => v.name
  }
}
