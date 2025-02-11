# Logging Configuration

# BigQuery Log Sink
resource "google_logging_project_sink" "bigquery" {
  name        = "bigquery-sink"
  description = "Export logs to BigQuery for analysis"
  
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${google_bigquery_dataset.logs.dataset_id}"
  
  filter = <<EOT
    resource.type="cloud_run_revision"
    OR resource.type="cloudsql_database"
    OR resource.type="cloud_function"
    OR severity >= WARNING
  EOT

  unique_writer_identity = true
}

# Storage Log Sink (for long-term retention)
resource "google_logging_project_sink" "storage" {
  name        = "storage-sink"
  description = "Export logs to Cloud Storage for archival"
  
  destination = "storage.googleapis.com/${google_storage_bucket.logs.name}"
  
  filter = <<EOT
    severity >= ERROR
    OR resource.type="cloud_run_revision"
    OR resource.type="cloudsql_database"
  EOT

  unique_writer_identity = true
}

# Pub/Sub Log Sink (for real-time processing)
resource "google_logging_project_sink" "pubsub" {
  name        = "pubsub-sink"
  description = "Export logs to Pub/Sub for real-time processing"
  
  destination = "pubsub.googleapis.com/projects/${var.project_id}/topics/${google_pubsub_topic.logs.name}"
  
  filter = <<EOT
    severity >= ERROR
    OR jsonPayload.type="security_alert"
    OR jsonPayload.type="performance_alert"
  EOT

  unique_writer_identity = true
}

# BigQuery Dataset for logs
resource "google_bigquery_dataset" "logs" {
  dataset_id  = "application_logs"
  description = "Application logs for analysis"
  location    = var.region

  default_table_expiration_ms = 8640000000  # 100 days

  access {
    role          = "OWNER"
    special_group = "projectOwners"
  }

  access {
    role          = "READER"
    special_group = "projectReaders"
  }
}

# Storage Bucket for log archival
resource "google_storage_bucket" "logs" {
  name          = "${var.project_id}-logs"
  location      = var.region
  force_destroy = false

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 365  # 1 year
    }
    action {
      type = "Delete"
    }
  }

  versioning {
    enabled = true
  }
}

# Pub/Sub topic for real-time log processing
resource "google_pubsub_topic" "logs" {
  name = "logs-topic"

  message_storage_policy {
    allowed_persistence_regions = [var.region]
  }
}

# IAM for log sinks
resource "google_project_iam_binding" "bigquery_sink" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  members = [google_logging_project_sink.bigquery.writer_identity]
}

resource "google_storage_bucket_iam_binding" "storage_sink" {
  bucket  = google_storage_bucket.logs.name
  role    = "roles/storage.objectCreator"
  members = [google_logging_project_sink.storage.writer_identity]
}

resource "google_pubsub_topic_iam_binding" "pubsub_sink" {
  project = var.project_id
  topic   = google_pubsub_topic.logs.name
  role    = "roles/pubsub.publisher"
  members = [google_logging_project_sink.pubsub.writer_identity]
}
