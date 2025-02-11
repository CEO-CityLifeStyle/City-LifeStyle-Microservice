# Backup and Disaster Recovery Configuration

# Backup Schedule
resource "google_cloud_scheduler_job" "database_backup" {
  name        = "database-backup-${var.environment}"
  description = "Trigger database backup export"
  schedule    = "0 2 * * *"  # 2 AM daily
  time_zone   = "UTC"

  http_target {
    http_method = "POST"
    uri         = "https://${var.region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${var.project_id}/jobs/database-backup"
    
    oauth_token {
      service_account_email = var.backup_service_account
    }
  }
}

# Cloud Storage Bucket for Backups
resource "google_storage_bucket" "backups" {
  name          = "${var.project_id}-backups-${var.environment}"
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

# Cloud Run Job for Database Backup
resource "google_cloud_run_v2_job" "database_backup" {
  name     = "database-backup"
  location = var.region

  template {
    template {
      containers {
        image = "gcr.io/cloud-marketplace/google/postgresql"
        
        command = ["/bin/sh"]
        args = [
          "-c",
          "pg_dump -h ${var.db_host} -U ${var.db_user} -d ${var.db_name} | gzip > /backup/backup-$(date +%Y%m%d-%H%M%S).sql.gz && gsutil cp /backup/*.gz gs://${google_storage_bucket.backups.name}/"
        ]

        env {
          name = "PGPASSWORD"
          value_source {
            secret_key_ref {
              secret = var.db_password_secret
              version = "latest"
            }
          }
        }

        volume_mounts {
          name = "backup"
          mount_path = "/backup"
        }
      }

      volumes {
        name = "backup"
        empty_dir {}
      }

      service_account = var.backup_service_account
    }
  }
}

# Monitoring for Backup Jobs
resource "google_monitoring_alert_policy" "backup_failure" {
  display_name = "Backup Job Failure Alert"
  combiner     = "OR"
  
  conditions {
    display_name = "Failed backup job"
    condition_threshold {
      filter     = "resource.type = \"cloud_run_job\" AND resource.labels.job_name = \"database-backup\" AND metric.type = \"run.googleapis.com/job/execution_count\" AND metric.labels.status = \"FAILED\""
      duration   = "0s"
      comparison = "COMPARISON_GT"
      threshold_value = 0
      
      trigger {
        count = 1
      }
      
      aggregations {
        alignment_period   = "600s"
        per_series_aligner = "ALIGN_COUNT"
      }
    }
  }

  notification_channels = [var.alert_notification_channel]

  documentation {
    content = "Database backup job has failed. Please check the Cloud Run job logs for more details."
    mime_type = "text/markdown"
  }
}

# IAM Configuration
resource "google_storage_bucket_iam_binding" "backup_writer" {
  bucket = google_storage_bucket.backups.name
  role   = "roles/storage.objectCreator"
  members = [
    "serviceAccount:${var.backup_service_account}"
  ]
}

# Outputs
output "backup_bucket" {
  value = google_storage_bucket.backups.name
}

output "backup_schedule" {
  value = google_cloud_scheduler_job.database_backup.schedule
}
