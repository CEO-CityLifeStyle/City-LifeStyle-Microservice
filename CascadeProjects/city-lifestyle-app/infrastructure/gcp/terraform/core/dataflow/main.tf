# Dataflow Configuration

# Enable Dataflow API
resource "google_project_service" "dataflow" {
  project = var.project_id
  service = "dataflow.googleapis.com"

  disable_dependent_services = true
  disable_on_destroy        = false
}

# Dataflow Job Template Storage
resource "google_storage_bucket" "dataflow_templates" {
  name          = "city-lifestyle-dataflow-${var.environment}"
  project       = var.project_id
  location      = var.region
  force_destroy = var.environment != "prod"

  uniform_bucket_level_access = true
  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
}

# Service Account for Dataflow Jobs
resource "google_service_account" "dataflow_worker" {
  account_id   = "dataflow-worker-${var.environment}"
  display_name = "Dataflow Worker Service Account"
  project      = var.project_id
}

# IAM roles for Dataflow Service Account
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
  member  = "serviceAccount:${google_service_account.dataflow_worker.email}"
}

# Dataflow Job - Events Analytics
resource "google_dataflow_job" "events_analytics" {
  name              = "events-analytics-${var.environment}"
  project           = var.project_id
  zone              = "${var.region}-a"
  temp_gcs_location = "${google_storage_bucket.dataflow_templates.url}/temp"
  template_gcs_path = "gs://dataflow-templates/latest/Cloud_PubSub_to_BigQuery"
  service_account_email = google_service_account.dataflow_worker.email
  network          = var.vpc_id
  subnetwork       = "regions/${var.region}/subnetworks/${var.subnet_id}"

  parameters = {
    inputTopic          = var.events_topic_id
    outputTableSpec     = "${var.project_id}:${var.analytics_dataset}.events_analytics"
    outputDeadLetterTable = "${var.project_id}:${var.analytics_dataset}.events_analytics_errors"
  }

  depends_on = [
    google_project_service.dataflow,
    google_storage_bucket.dataflow_templates
  ]
}

# Dataflow Job - User Analytics
resource "google_dataflow_job" "user_analytics" {
  name              = "user-analytics-${var.environment}"
  project           = var.project_id
  zone              = "${var.region}-a"
  temp_gcs_location = "${google_storage_bucket.dataflow_templates.url}/temp"
  template_gcs_path = "gs://dataflow-templates/latest/Cloud_PubSub_to_BigQuery"
  service_account_email = google_service_account.dataflow_worker.email
  network          = var.vpc_id
  subnetwork       = "regions/${var.region}/subnetworks/${var.subnet_id}"

  parameters = {
    inputTopic          = var.users_topic_id
    outputTableSpec     = "${var.project_id}:${var.analytics_dataset}.user_analytics"
    outputDeadLetterTable = "${var.project_id}:${var.analytics_dataset}.user_analytics_errors"
  }

  depends_on = [
    google_project_service.dataflow,
    google_storage_bucket.dataflow_templates
  ]
}

# Monitoring Configuration
resource "google_monitoring_alert_policy" "dataflow_errors" {
  display_name = "Dataflow Job Errors - ${var.environment}"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "Dataflow Job Error Count"
    condition_threshold {
      filter          = "resource.type = \"dataflow_job\" AND metric.type = \"dataflow.googleapis.com/job/element_count\" AND metric.labels.pcollection = \"errors\""
      duration        = "300s"
      comparison     = "COMPARISON_GT"
      threshold_value = 100
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
output "dataflow_bucket" {
  value = google_storage_bucket.dataflow_templates.name
}

output "dataflow_service_account" {
  value = google_service_account.dataflow_worker.email
}

output "job_ids" {
  value = {
    events = google_dataflow_job.events_analytics.job_id
    users  = google_dataflow_job.user_analytics.job_id
  }
}
