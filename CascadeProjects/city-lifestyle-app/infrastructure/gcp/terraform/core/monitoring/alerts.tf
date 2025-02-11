# Monitoring Alert Policies

# Error Rate Alert
resource "google_monitoring_alert_policy" "error_rate" {
  display_name = "High Error Rate"
  combiner     = "OR"
  conditions {
    display_name = "Error rate > 5%"
    condition_threshold {
      filter     = "resource.type = \"cloud_run_revision\" AND metric.type = \"run.googleapis.com/request_count\" AND metric.labels.response_code_class = \"5xx\""
      duration   = "300s"
      comparison = "COMPARISON_GT"
      threshold_value = 0.05
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]

  documentation {
    content = "High error rate detected in the application. Please investigate logs for more details."
    mime_type = "text/markdown"
  }
}

# Latency Alert
resource "google_monitoring_alert_policy" "latency" {
  display_name = "High Latency"
  combiner     = "OR"
  conditions {
    display_name = "P95 latency > 2s"
    condition_threshold {
      filter     = "resource.type = \"cloud_run_revision\" AND metric.type = \"run.googleapis.com/request_latencies\""
      duration   = "300s"
      comparison = "COMPARISON_GT"
      threshold_value = 2000
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_PERCENTILE_95"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]

  documentation {
    content = "High latency detected in the application. Please check the system resources and optimization opportunities."
    mime_type = "text/markdown"
  }
}

# Database Connection Alert
resource "google_monitoring_alert_policy" "db_connections" {
  display_name = "High Database Connections"
  combiner     = "OR"
  conditions {
    display_name = "Database connections > 80%"
    condition_threshold {
      filter     = "resource.type = \"cloudsql_database\" AND metric.type = \"cloudsql.googleapis.com/database/postgresql/num_connections\""
      duration   = "300s"
      comparison = "COMPARISON_GT"
      threshold_value = 80
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MAX"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]

  documentation {
    content = "High number of database connections detected. Please check for connection leaks or need for connection pooling optimization."
    mime_type = "text/markdown"
  }
}

# Memory Usage Alert
resource "google_monitoring_alert_policy" "memory_usage" {
  display_name = "High Memory Usage"
  combiner     = "OR"
  conditions {
    display_name = "Memory usage > 85%"
    condition_threshold {
      filter     = "resource.type = \"cloud_run_revision\" AND metric.type = \"run.googleapis.com/container/memory/utilizations\""
      duration   = "300s"
      comparison = "COMPARISON_GT"
      threshold_value = 0.85
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_PERCENTILE_95"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]

  documentation {
    content = "High memory usage detected. Consider increasing memory limits or optimizing memory usage."
    mime_type = "text/markdown"
  }
}

# Notification Channel
resource "google_monitoring_notification_channel" "email" {
  display_name = "Email Notification Channel"
  type         = "email"
  labels = {
    email_address = var.alert_email_address
  }
}
