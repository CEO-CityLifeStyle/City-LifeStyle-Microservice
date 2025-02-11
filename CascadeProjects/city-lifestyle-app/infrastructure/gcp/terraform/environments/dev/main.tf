terraform {
  backend "gcs" {
    bucket = "city-lifestyle-terraform-state"
    prefix = "dev"
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
  environment      = "dev"
  region          = var.region
  allowed_origins = var.allowed_origins
}

# Network
module "network" {
  source = "../../modules/network"

  project_id         = var.project_id
  environment        = "dev"
  region            = var.region
  private_subnet_cidr = "10.0.1.0/24"
  connector_cidr     = "10.8.0.0/28"
}

# IAM
module "iam" {
  source = "../../modules/iam"

  project_id  = var.project_id
  environment = "dev"
}

# Database
module "sql" {
  source = "../../modules/sql"

  project_id  = var.project_id
  environment = "dev"
  region     = var.region
  vpc_id     = module.network.vpc_id

  # Development-specific settings
  tier                = "db-f1-micro"
  availability_type   = "ZONAL"
  backup_enabled      = true
  backup_start_time   = "02:00"
  backup_count        = 3
}

# Cloud Run
module "cloudrun" {
  source = "../../modules/cloudrun"

  project_id           = var.project_id
  environment         = "dev"
  region             = var.region
  vpc_connector_id    = module.network.vpc_connector_id
  service_account_email = module.iam.service_account_email

  # Development-specific settings
  min_instances = 0
  max_instances = 2
  memory        = "512Mi"
  cpu           = "1"
}

# Load Balancer
module "loadbalancer" {
  source = "../../modules/loadbalancer"

  project_id = var.project_id
  environment = "dev"
  region     = var.region
  backend_id = module.cloudrun.service_id

  # Development-specific settings
  enable_cdn  = false
  ssl_policy  = "dev-ssl-policy"
}

# CDN
module "cdn" {
  source = "../../modules/cdn"

  project_id  = var.project_id
  environment = "dev"
  bucket_name = module.storage.frontend_bucket_name
  domain_name = var.domain_name

  # Development-specific settings
  cache_mode = "CACHE_ALL_STATIC"
  ttl        = 3600  # 1 hour for development
}

# Monitoring
module "monitoring" {
  source = "../../modules/monitoring"

  project_id                 = var.project_id
  environment               = "dev"
  alert_notification_channel = var.alert_notification_channel

  # Development-specific settings
  enable_uptime_checks     = false
  error_rate_threshold     = 0.1  # 10% error rate threshold for dev
  latency_threshold        = 2000 # 2 seconds
  enable_budget_alerts     = true
  budget_amount           = 100   # $100 USD
}
