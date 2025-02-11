terraform {
  backend "gcs" {
    bucket = "city-lifestyle-terraform-state"
    prefix = "staging"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Storage
module "storage" {
  source = "../../modules/storage"

  project_id       = var.project_id
  environment      = "staging"
  region          = var.region
  allowed_origins = var.allowed_origins

  versioning_enabled = true
  lifecycle_rules = {
    frontend = {
      age = 14
      type = "SetStorageClass"
      storage_class = "NEARLINE"
    }
    uploads = {
      age = 30
      type = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }
}

# Network
module "network" {
  source = "../../modules/network"

  project_id         = var.project_id
  environment        = "staging"
  region            = var.region
  private_subnet_cidr = "10.1.0.0/20"
  connector_cidr     = "10.9.0.0/28"

  enable_flow_logs = true
  nat_min_ports_per_vm = 16384
  nat_log_config = {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# IAM
module "iam" {
  source = "../../modules/iam"

  project_id  = var.project_id
  environment = "staging"

  enable_audit_logs = true
  custom_roles = {
    app_viewer = [
      "resourcemanager.projects.get",
      "monitoring.timeSeries.list",
      "logging.logEntries.list"
    ]
  }
}

# Database
module "sql" {
  source = "../../modules/sql"

  project_id  = var.project_id
  environment = "staging"
  region     = var.region
  vpc_id     = module.network.vpc_id

  tier               = "db-custom-2-8192"
  availability_type  = "ZONAL"
  backup_enabled     = true
  backup_start_time  = "23:00"
  backup_count       = 3
  maintenance_window = {
    day          = 7
    hour         = 3
    update_track = "stable"
  }
}

# Cloud Run
module "cloudrun" {
  source = "../../modules/cloudrun"

  project_id           = var.project_id
  environment         = "staging"
  region             = var.region
  vpc_connector_id    = module.network.vpc_connector_id
  service_account_email = module.iam.service_account_email

  min_instances = 1
  max_instances = 5
  memory        = "1Gi"
  cpu           = "1"
  concurrency   = 80
  timeout       = "300s"
}

# Load Balancer
module "loadbalancer" {
  source = "../../modules/loadbalancer"

  project_id = var.project_id
  environment = "staging"
  region     = var.region
  backend_id = module.cloudrun.service_id

  enable_cdn = true
  ssl_policy = {
    min_tls_version = var.ssl_policy_min_tls_version
    profile         = "MODERN"
  }
  security_policy = {
    enabled = true
    rules = [
      {
        action = "deny(403)"
        priority = 1000
        ip_ranges = ["0.0.0.0/0"]
        description = "Deny all by default"
      }
    ]
  }
}

# CDN
module "cdn" {
  source = "../../modules/cdn"

  project_id  = var.project_id
  environment = "staging"
  bucket_name = module.storage.frontend_bucket_name
  domain_name = var.domain_name

  cache_mode = "CACHE_ALL_STATIC"
  ttl        = 3600  # 1 hour
  ssl_certificate = {
    type = "MANAGED"
    domains = [var.domain_name]
  }
}

# Monitoring
module "monitoring" {
  source = "../../modules/monitoring"

  project_id                 = var.project_id
  environment               = "staging"
  alert_notification_channel = var.alert_notification_channel

  enable_uptime_checks    = true
  error_rate_threshold    = var.alert_thresholds.error_rate
  latency_threshold       = var.alert_thresholds.latency_ms
  enable_budget_alerts    = true
  budget_amount          = var.budget_amount
  cpu_threshold          = var.alert_thresholds.cpu_threshold
  memory_threshold       = var.alert_thresholds.memory_threshold
}
