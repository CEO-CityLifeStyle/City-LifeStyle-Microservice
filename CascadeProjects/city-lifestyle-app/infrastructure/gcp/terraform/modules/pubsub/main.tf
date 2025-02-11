# Cloud Pub/Sub Module

variable "project_id" {}
variable "topics" {
  type = list(object({
    name       = string
    labels     = map(string)
    subscriptions = list(object({
      name                 = string
      message_retention_duration = string
      retain_acked_messages = bool
      ack_deadline_seconds = number
      expiration_policy_ttl = string
      retry_policy = object({
        minimum_backoff = string
        maximum_backoff = string
      })
      push_config = optional(object({
        push_endpoint = string
        attributes    = map(string)
      }))
    }))
  }))
  default = []
}

# Create topics
resource "google_pubsub_topic" "topics" {
  for_each = { for topic in var.topics : topic.name => topic }

  name    = each.value.name
  project = var.project_id
  labels  = each.value.labels

  message_retention_duration = "604800s"  # 7 days

  depends_on = [
    google_project_service.pubsub
  ]
}

# Create subscriptions
resource "google_pubsub_subscription" "subscriptions" {
  for_each = { 
    for subscription in flatten([
      for topic in var.topics : [
        for sub in topic.subscriptions : {
          topic_name = topic.name
          sub_name   = sub.name
          config     = sub
        }
      ]
    ]) : "${subscription.topic_name}-${subscription.sub_name}" => subscription
  }

  name    = each.value.config.name
  topic   = google_pubsub_topic.topics[each.value.topic_name].name
  project = var.project_id

  message_retention_duration = each.value.config.message_retention_duration
  retain_acked_messages     = each.value.config.retain_acked_messages
  ack_deadline_seconds      = each.value.config.ack_deadline_seconds

  expiration_policy {
    ttl = each.value.config.expiration_policy_ttl
  }

  retry_policy {
    minimum_backoff = each.value.config.retry_policy.minimum_backoff
    maximum_backoff = each.value.config.retry_policy.maximum_backoff
  }

  dynamic "push_config" {
    for_each = each.value.config.push_config != null ? [each.value.config.push_config] : []
    content {
      push_endpoint = push_config.value.push_endpoint
      attributes    = push_config.value.attributes
    }
  }

  depends_on = [
    google_pubsub_topic.topics
  ]
}

# Enable Pub/Sub API
resource "google_project_service" "pubsub" {
  project = var.project_id
  service = "pubsub.googleapis.com"

  disable_dependent_services = true
  disable_on_destroy        = false
}

output "topic_names" {
  value = { for k, v in google_pubsub_topic.topics : k => v.name }
}

output "subscription_names" {
  value = { for k, v in google_pubsub_subscription.subscriptions : k => v.name }
}
