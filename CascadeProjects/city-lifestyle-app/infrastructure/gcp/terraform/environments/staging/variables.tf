variable "project_id" {
  description = "The project ID to deploy to"
  type        = string
}

variable "region" {
  description = "The region to deploy to"
  type        = string
  default     = "us-central1"
}

variable "allowed_origins" {
  description = "List of allowed origins for CORS"
  type        = list(string)
}

variable "domain_name" {
  description = "The domain name for the application"
  type        = string
}

variable "alert_notification_channel" {
  description = "The notification channel for alerts"
  type        = string
}

variable "environment_vars" {
  description = "Environment variables for the application"
  type        = map(string)
  default     = {}
}

variable "ssl_policy_min_tls_version" {
  description = "Minimum TLS version for SSL policy"
  type        = string
  default     = "TLS_1_2"
}

variable "budget_amount" {
  description = "Monthly budget amount in USD"
  type        = number
  default     = 500
}

variable "alert_thresholds" {
  description = "Alert thresholds for monitoring"
  type = object({
    error_rate       = number
    latency_ms       = number
    cpu_threshold    = number
    memory_threshold = number
  })
  default = {
    error_rate       = 0.02  # 2%
    latency_ms       = 2000  # 2 seconds
    cpu_threshold    = 0.8   # 80%
    memory_threshold = 0.8   # 80%
  }
}
