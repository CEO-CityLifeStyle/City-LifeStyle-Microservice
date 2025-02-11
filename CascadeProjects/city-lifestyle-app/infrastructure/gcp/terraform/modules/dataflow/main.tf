# Dataflow Module

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

variable "network_config" {
  description = "Network configuration for Dataflow jobs"
  type = object({
    vpc_id     = string
    subnet_id  = string
  })
}

variable "jobs" {
  description = "Map of Dataflow job configurations"
  type = map(object({
    name           = string
    template_path  = string
    temp_location  = string
    parameters     = map(string)
    max_workers    = optional(number)
    service_account = optional(string)
  }))
}

variable "alert_notification_channel" {
  description = "Notification channel for alerts"
  type        = string
  default     = null
}

# Storage for job templates and temp files
resource "google_storage_bucket" "dataflow" {
  name          = "dataflow-${var.project_id}-${var.environment}"
  project       = var.project_id
  location      = var.region
  force_destroy = var.environment != "prod"

  uniform_bucket_level_access = true
  versioning {
    enabled = true
  }
}

# Service Account
resource "google_service_account" "dataflow" {
  account_id   = "dataflow-${var.environment}"
  display_name = "Dataflow Service Account"
  project      = var.project_id
}

# IAM roles
resource "google_project_iam_member" "dataflow_worker" {
  for_each = toset([
    "roles/dataflow.worker",
    "roles/bigquery.dataEditor",
    "roles/storage.objectViewer",
    "roles/pubsub.publisher",
    "roles/pubsub.subscriber"
  ])

  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.dataflow.email}"
}

# Dataflow Jobs
resource "google_dataflow_job" "jobs" {
  for_each = var.jobs

  name              = each.value.name
  project           = var.project_id
  zone              = "${var.region}-a"
  temp_gcs_location = each.value.temp_location
  template_gcs_path = each.value.template_path
  service_account_email = coalesce(each.value.service_account, google_service_account.dataflow.email)
  network          = var.network_config.vpc_id
  subnetwork       = "regions/${var.region}/subnetworks/${var.network_config.subnet_id}"
  max_workers      = each.value.max_workers

  parameters = each.value.parameters

  on_delete = "drain"
}

# Monitoring
resource "google_monitoring_alert_policy" "errors" {
  count = var.alert_notification_channel != null ? 1 : 0

  display_name = "Dataflow Job Errors - ${var.environment}"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "Dataflow Job Error Count"
    condition_threshold {
      filter     = "resource.type = \"dataflow_job\" AND metric.type = \"dataflow.googleapis.com/job/element_count\" AND metric.labels.pcollection = \"errors\""
      duration   = "300s"
      comparison = "COMPARISON_GT"
      threshold_value = var.environment == "prod" ? 100 : 1000
      trigger {
        count = 1
      }
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = [var.alert_notification_channel]
}

# Outputs
output "bucket_name" {
  value = google_storage_bucket.dataflow.name
}

output "service_account" {
  value = google_service_account.dataflow.email
}

output "job_ids" {
  value = {
    for k, v in google_dataflow_job.jobs : k => v.job_id
  }
}
