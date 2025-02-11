# BigQuery Configuration

# Analytics Dataset
resource "google_bigquery_dataset" "analytics" {
  dataset_id                  = "city_lifestyle_analytics"
  friendly_name              = "City Lifestyle Analytics"
  description                = "Analytics data for City Lifestyle application"
  location                   = var.region
  project                    = var.project_id
  delete_contents_on_destroy = false

  labels = {
    environment = var.environment
    service     = "analytics"
  }

  access {
    role          = "OWNER"
    special_group = "projectOwners"
  }

  access {
    role           = "READER"
    group_by_email = var.analytics_viewer_group
  }
}

# User Events Table
resource "google_bigquery_table" "user_events" {
  dataset_id = google_bigquery_dataset.analytics.dataset_id
  table_id   = "user_events"
  project    = var.project_id

  time_partitioning {
    type  = "DAY"
    field = "event_timestamp"
  }

  schema = file("${path.module}/schemas/user_events.json")

  labels = {
    environment = var.environment
    type        = "events"
  }
}

# Application Metrics Table
resource "google_bigquery_table" "app_metrics" {
  dataset_id = google_bigquery_dataset.analytics.dataset_id
  table_id   = "app_metrics"
  project    = var.project_id

  time_partitioning {
    type  = "DAY"
    field = "metric_timestamp"
  }

  schema = file("${path.module}/schemas/app_metrics.json")

  labels = {
    environment = var.environment
    type        = "metrics"
  }
}

# Log Sink to BigQuery
resource "google_logging_project_sink" "bigquery_sink" {
  name        = "app-logs-to-bigquery"
  project     = var.project_id
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${google_bigquery_dataset.analytics.dataset_id}"

  filter = "resource.type=\"cloud_run_revision\" OR resource.type=\"cloud_sql_database\""

  unique_writer_identity = true

  bigquery_options {
    use_partitioned_tables = true
  }
}

# IAM binding for the log sink writer
resource "google_project_iam_binding" "log_writer" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"

  members = [
    google_logging_project_sink.bigquery_sink.writer_identity,
  ]
}

# Outputs
output "dataset_id" {
  value = google_bigquery_dataset.analytics.dataset_id
}

output "tables" {
  value = {
    user_events = google_bigquery_table.user_events.table_id
    app_metrics = google_bigquery_table.app_metrics.table_id
  }
}
