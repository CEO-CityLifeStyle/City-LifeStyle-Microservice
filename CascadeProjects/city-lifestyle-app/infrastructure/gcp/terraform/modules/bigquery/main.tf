# BigQuery Module

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

variable "dataset_id" {
  description = "The ID of the dataset"
  type        = string
}

variable "tables" {
  description = "Map of table configurations"
  type = map(object({
    table_id     = string
    schema_file  = string
    partition_by = optional(string)
    clustering   = optional(list(string))
  }))
}

variable "access_groups" {
  description = "Map of access groups"
  type = map(list(string))
  default = {}
}

# Dataset
resource "google_bigquery_dataset" "main" {
  dataset_id                  = var.dataset_id
  project                    = var.project_id
  location                   = var.region
  delete_contents_on_destroy = var.environment != "prod"

  labels = {
    environment = var.environment
  }

  dynamic "access" {
    for_each = var.access_groups
    content {
      role          = access.key
      user_by_email = access.value
    }
  }
}

# Tables
resource "google_bigquery_table" "tables" {
  for_each = var.tables

  dataset_id = google_bigquery_dataset.main.dataset_id
  table_id   = each.value.table_id
  project    = var.project_id

  schema = file(each.value.schema_file)

  dynamic "time_partitioning" {
    for_each = each.value.partition_by != null ? [1] : []
    content {
      type  = "DAY"
      field = each.value.partition_by
    }
  }

  dynamic "clustering" {
    for_each = each.value.clustering != null ? [1] : []
    content {
      fields = each.value.clustering
    }
  }

  labels = {
    environment = var.environment
  }
}

# Outputs
output "dataset_id" {
  value = google_bigquery_dataset.main.dataset_id
}

output "dataset_location" {
  value = google_bigquery_dataset.main.location
}

output "table_ids" {
  value = {
    for k, v in google_bigquery_table.tables : k => v.table_id
  }
}
