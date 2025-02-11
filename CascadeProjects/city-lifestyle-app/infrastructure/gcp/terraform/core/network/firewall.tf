# Core Firewall Rules
resource "google_compute_firewall" "allow_internal" {
  name    = "allow-internal"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "icmp"
  }

  source_ranges = [
    google_compute_subnetwork.services.ip_cidr_range,
    google_compute_subnetwork.services.secondary_ip_range[0].ip_cidr_range,
    google_compute_subnetwork.services.secondary_ip_range[1].ip_cidr_range
  ]
}

resource "google_compute_firewall" "allow_health_checks" {
  name    = "allow-health-checks"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  target_tags   = ["load-balanced"]
}

# Cloud Armor Security Policy
resource "google_compute_security_policy" "main" {
  name = "city-lifestyle-security-policy"

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
        src_ip_ranges = var.trusted_ip_ranges
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
      enforce_on_key  = "IP"
      ban_duration_sec = 300
    }
    description = "Rate limiting rule"
  }
}
