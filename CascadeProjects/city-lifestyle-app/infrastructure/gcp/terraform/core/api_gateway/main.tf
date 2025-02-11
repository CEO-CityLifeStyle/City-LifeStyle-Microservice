# API Gateway Configuration

# API Gateway
resource "google_api_gateway_api" "api" {
  provider = google-beta
  api_id   = "city-lifestyle-api"
  project  = var.project_id
}

# API Config
resource "google_api_gateway_api_config" "api_config" {
  provider      = google-beta
  api           = google_api_gateway_api.api.api_id
  api_config_id = "city-lifestyle-config-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  project       = var.project_id

  openapi_documents {
    document {
      path = "spec.yaml"
      contents = base64encode(templatefile("${path.module}/specs/openapi.yaml", {
        project_id = var.project_id
        region     = var.region
        api_id     = google_api_gateway_api.api.api_id
      }))
    }
  }

  gateway_config {
    backend_config {
      google_service_account = var.gateway_service_account
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway
resource "google_api_gateway_gateway" "gateway" {
  provider   = google-beta
  region     = var.region
  project    = var.project_id
  api_config = google_api_gateway_api_config.api_config.id
  gateway_id = "city-lifestyle-gateway"

  labels = {
    environment = var.environment
  }
}

# Cloud Armor Security Policy
resource "google_compute_security_policy" "api_security" {
  name        = "api-security-policy"
  description = "Security policy for API Gateway"

  # Default rule (deny all)
  rule {
    action   = "deny(403)"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default deny rule"
  }

  # Allow trusted IPs
  rule {
    action   = "allow"
    priority = "1000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = var.allowed_ip_ranges
      }
    }
    description = "Allow trusted IPs"
  }

  # Rate limiting
  rule {
    action   = "rate_based_ban"
    priority = "2000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    rate_limit_options {
      rate_limit_threshold {
        count        = 100
        interval_sec = 60
      }
      conform_action   = "allow"
      exceed_action   = "deny(429)"
      enforce_on_key = "IP"
    }
    description = "Rate limiting rule"
  }
}

# SSL Certificate
resource "google_compute_managed_ssl_certificate" "api" {
  name = "api-cert"

  managed {
    domains = [var.api_domain]
  }
}

# Load Balancer
module "api_lb" {
  source = "../../modules/loadbalancer"

  project_id = var.project_id
  name       = "api-gateway"
  region     = var.region

  backends = [{
    group_id              = google_api_gateway_gateway.gateway.id
    balancing_mode        = "RATE"
    capacity_scaler       = 1.0
    max_rate_per_instance = 100
  }]

  health_check = {
    check_interval_sec  = 5
    timeout_sec        = 5
    healthy_threshold  = 2
    unhealthy_threshold = 2
    request_path       = "/health"
    port              = 443
  }

  ssl_certificate = google_compute_managed_ssl_certificate.api.id
  custom_domains  = [var.api_domain]
}

# Outputs
output "gateway_url" {
  value = google_api_gateway_gateway.gateway.default_hostname
}

output "load_balancer_ip" {
  value = module.api_lb.load_balancer_ip
}
