# Global Load Balancer Module

variable "project_id" {}
variable "name" {}
variable "region" {}
variable "backends" {
  type = list(object({
    group_id = string
    balancing_mode = string
    capacity_scaler = number
    max_rate_per_instance = number
  }))
}
variable "health_check" {
  type = object({
    check_interval_sec = number
    timeout_sec = number
    healthy_threshold = number
    unhealthy_threshold = number
    request_path = string
    port = number
  })
  default = {
    check_interval_sec = 5
    timeout_sec = 5
    healthy_threshold = 2
    unhealthy_threshold = 2
    request_path = "/"
    port = 80
  }
}
variable "ssl_certificate" {
  type = string
  default = null
}
variable "custom_domains" {
  type = list(string)
  default = []
}

# Health Check
resource "google_compute_health_check" "default" {
  name               = "${var.name}-health-check"
  project            = var.project_id
  check_interval_sec = var.health_check.check_interval_sec
  timeout_sec        = var.health_check.timeout_sec

  http_health_check {
    port               = var.health_check.port
    request_path       = var.health_check.request_path
    port_specification = "USE_FIXED_PORT"
  }
}

# Backend Service
resource "google_compute_backend_service" "default" {
  name                  = "${var.name}-backend"
  project               = var.project_id
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL"
  timeout_sec           = 30
  health_checks        = [google_compute_health_check.default.id]
  security_policy      = google_compute_security_policy.policy.id

  dynamic "backend" {
    for_each = var.backends
    content {
      group           = backend.value.group_id
      balancing_mode  = backend.value.balancing_mode
      capacity_scaler = backend.value.capacity_scaler
      max_rate_per_instance = backend.value.max_rate_per_instance
    }
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }

  cdn_policy {
    cache_mode = "USE_ORIGIN_HEADERS"
    client_ttl = 3600
    default_ttl = 3600
    max_ttl     = 86400
    negative_caching = true
    serve_while_stale = 86400
  }
}

# URL Map
resource "google_compute_url_map" "default" {
  name            = "${var.name}-urlmap"
  project         = var.project_id
  default_service = google_compute_backend_service.default.id
}

# HTTP Proxy
resource "google_compute_target_http_proxy" "default" {
  name    = "${var.name}-http-proxy"
  project = var.project_id
  url_map = google_compute_url_map.default.id
}

# HTTPS Proxy (if SSL certificate is provided)
resource "google_compute_target_https_proxy" "default" {
  count   = var.ssl_certificate != null ? 1 : 0
  name    = "${var.name}-https-proxy"
  project = var.project_id
  url_map = google_compute_url_map.default.id
  ssl_certificates = [var.ssl_certificate]
}

# Global Forwarding Rules
resource "google_compute_global_forwarding_rule" "http" {
  name                  = "${var.name}-http-rule"
  project               = var.project_id
  target                = google_compute_target_http_proxy.default.id
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL"
  ip_address            = google_compute_global_address.default.address
}

resource "google_compute_global_forwarding_rule" "https" {
  count                 = var.ssl_certificate != null ? 1 : 0
  name                  = "${var.name}-https-rule"
  project               = var.project_id
  target                = google_compute_target_https_proxy.default[0].id
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL"
  ip_address            = google_compute_global_address.default.address
}

# Global IP Address
resource "google_compute_global_address" "default" {
  name    = "${var.name}-address"
  project = var.project_id
}

# Cloud Armor Security Policy
resource "google_compute_security_policy" "policy" {
  name    = "${var.name}-security-policy"
  project = var.project_id

  # Default rule (deny all)
  rule {
    action   = "allow"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "default rule"
  }

  # Rate limiting
  rule {
    action   = "rate_based_ban"
    priority = "1000"
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

  # DDoS protection
  rule {
    action   = "deny(403)"
    priority = "2000"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('xss-stable')"
      }
    }
    description = "XSS protection"
  }

  rule {
    action   = "deny(403)"
    priority = "2001"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('sqli-stable')"
      }
    }
    description = "SQL injection protection"
  }
}

output "load_balancer_ip" {
  value = google_compute_global_address.default.address
}

output "backend_service_id" {
  value = google_compute_backend_service.default.id
}

output "security_policy_id" {
  value = google_compute_security_policy.policy.id
}
