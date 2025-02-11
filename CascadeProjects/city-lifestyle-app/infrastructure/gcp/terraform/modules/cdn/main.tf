# Cloud CDN Module

variable "project_id" {}
variable "name" {}
variable "backend_bucket_name" {}
variable "custom_domain" {
  type = string
  default = null
}
variable "ssl_certificate" {
  type = string
  default = null
}
variable "enable_cdn" {
  type = bool
  default = true
}
variable "cache_mode" {
  type = string
  default = "CACHE_ALL_STATIC"
}
variable "default_ttl" {
  type = number
  default = 3600
}
variable "custom_response_headers" {
  type = list(string)
  default = []
}

# Backend bucket for static content
resource "google_compute_backend_bucket" "static" {
  name        = var.backend_bucket_name
  bucket_name = var.backend_bucket_name
  enable_cdn  = var.enable_cdn
  project     = var.project_id

  cdn_policy {
    cache_mode        = var.cache_mode
    default_ttl      = var.default_ttl
    client_ttl       = var.default_ttl
    max_ttl          = var.default_ttl * 2
    negative_caching = true
    
    cache_key_policy {
      include_host           = true
      include_protocol       = true
      include_query_string  = false
    }
  }
}

# URL Map
resource "google_compute_url_map" "urlmap" {
  name            = "${var.name}-urlmap"
  project         = var.project_id
  default_service = google_compute_backend_bucket.static.self_link
}

# HTTP Proxy
resource "google_compute_target_http_proxy" "http" {
  name    = "${var.name}-http"
  project = var.project_id
  url_map = google_compute_url_map.urlmap.self_link
}

# HTTPS Proxy (if SSL certificate is provided)
resource "google_compute_target_https_proxy" "https" {
  count   = var.ssl_certificate != null ? 1 : 0
  name    = "${var.name}-https"
  project = var.project_id
  url_map = google_compute_url_map.urlmap.self_link
  ssl_certificates = [var.ssl_certificate]
}

# Global Forwarding Rules
resource "google_compute_global_forwarding_rule" "http" {
  name       = "${var.name}-http"
  project    = var.project_id
  target     = google_compute_target_http_proxy.http.self_link
  port_range = "80"
  ip_address = google_compute_global_address.default.address
}

resource "google_compute_global_forwarding_rule" "https" {
  count      = var.ssl_certificate != null ? 1 : 0
  name       = "${var.name}-https"
  project    = var.project_id
  target     = google_compute_target_https_proxy.https[0].self_link
  port_range = "443"
  ip_address = google_compute_global_address.default.address
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

  # DDoS protection
  rule {
    action   = "deny(403)"
    priority = "1000"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('xss-stable')"
      }
    }
    description = "XSS protection"
  }

  rule {
    action   = "deny(403)"
    priority = "1001"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('sqli-stable')"
      }
    }
    description = "SQL injection protection"
  }
}

output "backend_bucket_name" {
  value = google_compute_backend_bucket.static.bucket_name
}

output "cdn_ip_address" {
  value = google_compute_global_address.default.address
}

output "security_policy_id" {
  value = google_compute_security_policy.policy.id
}
