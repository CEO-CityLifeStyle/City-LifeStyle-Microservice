# Frontend Infrastructure Module

# Cloud Storage bucket for hosting
resource "google_storage_bucket" "frontend" {
  name     = "${var.project_id}-frontend-${var.environment}"
  location = var.region
  
  website {
    main_page_suffix = "index.html"
    not_found_page   = "index.html"
  }
  
  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD", "OPTIONS"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
  
  force_destroy = true
}

# Cloud CDN configuration
resource "google_compute_backend_bucket" "frontend" {
  name        = "${var.project_id}-frontend-backend"
  bucket_name = google_storage_bucket.frontend.name
  enable_cdn  = true
  
  cdn_policy {
    cache_mode        = var.cdn_configuration.cache_mode
    default_ttl       = var.cdn_configuration.default_ttl
    client_ttl        = var.cdn_configuration.default_ttl
    max_ttl          = var.cdn_configuration.default_ttl * 2
  }
}

# HTTPS Load Balancer
resource "google_compute_url_map" "frontend" {
  name            = "${var.project_id}-frontend-urlmap"
  default_service = google_compute_backend_bucket.frontend.self_link
}

resource "google_compute_managed_ssl_certificate" "frontend" {
  name = "${var.project_id}-frontend-cert"
  
  managed {
    domains = [var.domain]
  }
}

resource "google_compute_target_https_proxy" "frontend" {
  name             = "${var.project_id}-frontend-proxy"
  url_map          = google_compute_url_map.frontend.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.frontend.self_link]
}

resource "google_compute_global_address" "frontend" {
  name = "${var.project_id}-frontend-ip"
}

resource "google_compute_global_forwarding_rule" "frontend" {
  name       = "${var.project_id}-frontend-rule"
  target     = google_compute_target_https_proxy.frontend.self_link
  port_range = "443"
  ip_address = google_compute_global_address.frontend.address
}
