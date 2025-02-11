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
  default     = ["*"]  # More permissive for development
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
    "containerregistry.googleapis.com"
  ]
}
