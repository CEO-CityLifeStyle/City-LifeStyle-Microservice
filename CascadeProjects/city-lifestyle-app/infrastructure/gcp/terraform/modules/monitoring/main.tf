# Cloud Monitoring Module

variable "project_id" {}
variable "notification_channels" {
  type = list(object({
    display_name = string
    type        = string
    labels      = map(string)
  }))
  default = []
}
variable "alert_policies" {
  type = list(object({
    display_name = string
    conditions = list(object({
      display_name = string
      condition_threshold = object({
        filter     = string
        duration   = string
        comparison = string
        threshold_value = number
        aggregations = optional(list(object({
          alignment_period   = string
          per_series_aligner = string
          cross_series_reducer = optional(string)
          group_by_fields    = optional(list(string))
        })))
      })
    }))
    notification_channels = list(string)
    user_labels = map(string)
  }))
  default = []
}

# Notification Channels
resource "google_monitoring_notification_channel" "channels" {
  for_each = { for idx, channel in var.notification_channels : channel.display_name => channel }

  project      = var.project_id
  display_name = each.value.display_name
  type         = each.value.type
  labels       = each.value.labels
}

# Alert Policies
resource "google_monitoring_alert_policy" "alert_policies" {
  for_each = { for idx, policy in var.alert_policies : policy.display_name => policy }

  project      = var.project_id
  display_name = each.value.display_name
  combiner     = "OR"

  dynamic "conditions" {
    for_each = each.value.conditions
    content {
      display_name = conditions.value.display_name

      condition_threshold {
        filter          = conditions.value.condition_threshold.filter
        duration       = conditions.value.condition_threshold.duration
        comparison     = conditions.value.condition_threshold.comparison
        threshold_value = conditions.value.condition_threshold.threshold_value

        dynamic "aggregations" {
          for_each = conditions.value.condition_threshold.aggregations != null ? conditions.value.condition_threshold.aggregations : []
          content {
            alignment_period   = aggregations.value.alignment_period
            per_series_aligner = aggregations.value.per_series_aligner
            cross_series_reducer = aggregations.value.cross_series_reducer
            group_by_fields    = aggregations.value.group_by_fields
          }
        }
      }
    }
  }

  notification_channels = [
    for channel in each.value.notification_channels :
    google_monitoring_notification_channel.channels[channel].name
  ]

  user_labels = each.value.user_labels
}

# Dashboard
resource "google_monitoring_dashboard" "dashboard" {
  dashboard_json = jsonencode({
    displayName = "Service Overview"
    gridLayout = {
      widgets = [
        {
          title = "HTTP Request Count"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "metric.type=\"run.googleapis.com/request_count\""
                  aggregation = {
                    alignmentPeriod = "60s"
                    crossSeriesReducer = "REDUCE_SUM"
                    perSeriesAligner = "ALIGN_RATE"
                  }
                }
              }
            }]
          }
        },
        {
          title = "HTTP Response Latency"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "metric.type=\"run.googleapis.com/request_latencies\""
                  aggregation = {
                    alignmentPeriod = "60s"
                    perSeriesAligner = "ALIGN_PERCENTILE_99"
                  }
                }
              }
            }]
          }
        }
      ]
    }
  })
}

output "notification_channel_ids" {
  value = { for k, v in google_monitoring_notification_channel.channels : k => v.name }
}

output "alert_policy_ids" {
  value = { for k, v in google_monitoring_alert_policy.alert_policies : k => v.name }
}
