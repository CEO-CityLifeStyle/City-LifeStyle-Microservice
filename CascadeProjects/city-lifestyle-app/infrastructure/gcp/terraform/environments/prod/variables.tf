variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for resources"
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
  description = "The notification channel ID for alerts"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR range for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "environment_vars" {
  description = "Environment variables for Cloud Run services"
  type        = map(string)
  default     = {}
}

variable "secondary_region" {
  description = "Secondary region for disaster recovery"
  type        = string
  default     = "us-east1"
}

variable "enable_apis" {
  description = "List of APIs to enable in the project"
  type        = list(string)
  default = [
    "cloudrun.googleapis.com",
    "sql-component.googleapis.com",
    "secretmanager.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "cloudbuild.googleapis.com",
    "containerregistry.googleapis.com",
    "cloudkms.googleapis.com",
    "cloudarmor.googleapis.com",
    "vpcaccess.googleapis.com",
    "servicenetworking.googleapis.com"
  ]
}

variable "ssl_policy_min_tls_version" {
  description = "Minimum TLS version for SSL policy"
  type        = string
  default     = "TLS_1_2"
}

variable "budget_amount" {
  description = "Monthly budget amount in USD"
  type        = number
  default     = 1000
}

variable "alert_thresholds" {
  description = "Alert thresholds for monitoring"
  type = object({
    error_rate     = number
    latency_ms     = number
    cpu_threshold  = number
    memory_threshold = number
  })
  default = {
    error_rate      = 0.01  # 1%
    latency_ms      = 1000  # 1 second
    cpu_threshold   = 0.8   # 80%
    memory_threshold = 0.8   # 80%
  }
}
