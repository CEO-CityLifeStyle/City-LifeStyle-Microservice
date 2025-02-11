# Cloud Run Service Module

variable "project_id" {}
variable "region" {}
variable "service_name" {}
variable "image" {}
variable "environment_variables" {
  type = map(string)
  default = {}
}
variable "vpc_connector" {
  default = null
}
variable "service_account_email" {
  default = null
}
variable "min_instances" {
  default = 0
}
variable "max_instances" {
  default = 100
}
variable "cpu_limit" {
  default = "1000m"
}
variable "memory_limit" {
  default = "512Mi"
}

resource "google_cloud_run_service" "service" {
  name     = var.service_name
  location = var.region

  template {
    spec {
      containers {
        image = var.image
        
        resources {
          limits = {
            cpu    = var.cpu_limit
            memory = var.memory_limit
          }
        }

        dynamic "env" {
          for_each = var.environment_variables
          content {
            name  = env.key
            value = env.value
          }
        }
      }

      service_account_name = var.service_account_email

      container_concurrency = 80
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/minScale"      = var.min_instances
        "autoscaling.knative.dev/maxScale"      = var.max_instances
        "run.googleapis.com/vpc-access-connector" = var.vpc_connector
        "run.googleapis.com/vpc-access-egress"    = "all-traffic"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  autogenerate_revision_name = true
}

# IAM policy for public access
resource "google_cloud_run_service_iam_member" "public" {
  location = google_cloud_run_service.service.location
  project  = var.project_id
  service  = google_cloud_run_service.service.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

output "service_url" {
  value = google_cloud_run_service.service.status[0].url
}

output "service_name" {
  value = google_cloud_run_service.service.name
}

output "latest_revision_name" {
  value = google_cloud_run_service.service.status[0].latest_created_revision_name
}
