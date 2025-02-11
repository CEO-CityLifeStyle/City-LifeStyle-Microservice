# Network Module

# VPC Network
resource "google_compute_network" "vpc" {
  name                    = "city-lifestyle-vpc-${var.environment}"
  auto_create_subnetworks = false
  project                 = var.project_id
}

# Subnets
resource "google_compute_subnetwork" "private" {
  name          = "private-subnet-${var.environment}"
  ip_cidr_range = var.private_subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
  project       = var.project_id

  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling       = 0.5
    metadata           = "INCLUDE_ALL_METADATA"
  }
}

# Cloud NAT
resource "google_compute_router" "router" {
  name    = "nat-router-${var.environment}"
  region  = var.region
  network = google_compute_network.vpc.id
  project = var.project_id
}

resource "google_compute_router_nat" "nat" {
  name                               = "nat-config-${var.environment}"
  router                            = google_compute_router.router.name
  region                            = var.region
  project                           = var.project_id
  nat_ip_allocate_option           = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Firewall Rules
resource "google_compute_firewall" "allow_internal" {
  name    = "allow-internal-${var.environment}"
  network = google_compute_network.vpc.id
  project = var.project_id

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

  source_ranges = [var.private_subnet_cidr]
}

resource "google_compute_firewall" "allow_health_checks" {
  name    = "allow-health-checks-${var.environment}"
  network = google_compute_network.vpc.id
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["load-balanced"]
}

# VPC Connector
resource "google_vpc_access_connector" "connector" {
  name          = "vpc-connector-${var.environment}"
  region        = var.region
  project       = var.project_id
  ip_cidr_range = var.connector_cidr
  network       = google_compute_network.vpc.id
}

# Outputs
output "vpc_id" {
  value = google_compute_network.vpc.id
}

output "private_subnet_id" {
  value = google_compute_subnetwork.private.id
}

output "vpc_connector_id" {
  value = google_vpc_access_connector.connector.id
}

output "network_name" {
  value = google_compute_network.vpc.name
}
