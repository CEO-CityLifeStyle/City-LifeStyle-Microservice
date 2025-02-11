# Spanner Module

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

variable "instance_name" {
  description = "The name of the spanner instance"
  type        = string
}

variable "database_name" {
  description = "The name of the spanner database"
  type        = string
}

variable "node_count" {
  description = "The number of nodes for the instance"
  type        = number
  default     = 1
}

variable "ddl_files" {
  description = "List of DDL files to apply"
  type        = list(string)
}

variable "service_accounts" {
  description = "List of service accounts to grant access"
  type        = list(string)
  default     = []
}

# Instance
resource "google_spanner_instance" "instance" {
  name         = var.instance_name
  config       = "regional-${var.region}"
  display_name = "City Lifestyle ${title(var.environment)}"
  project      = var.project_id
  num_nodes    = var.node_count

  labels = {
    environment = var.environment
  }
}

# Database
resource "google_spanner_database" "database" {
  instance = google_spanner_instance.instance.name
  name     = var.database_name
  project  = var.project_id

  deletion_protection = var.environment == "prod"

  version_retention_period = var.environment == "prod" ? "7d" : "1d"
  
  ddl = [for file in var.ddl_files : file(file)]
}

# IAM
resource "google_spanner_database_iam_binding" "binding" {
  count    = length(var.service_accounts) > 0 ? 1 : 0
  instance = google_spanner_instance.instance.name
  database = google_spanner_database.database.name
  project  = var.project_id
  role     = "roles/spanner.databaseUser"

  members = [for sa in var.service_accounts : "serviceAccount:${sa}"]
}

# Outputs
output "instance_id" {
  value = google_spanner_instance.instance.id
}

output "instance_name" {
  value = google_spanner_instance.instance.name
}

output "database_id" {
  value = google_spanner_database.database.id
}

output "database_name" {
  value = google_spanner_database.database.name
}
