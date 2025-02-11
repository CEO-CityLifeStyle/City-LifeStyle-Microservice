# Core VPC Configuration
resource "google_compute_network" "main" {
  name                    = "city-lifestyle-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "services" {
  name          = "services-subnet"
  ip_cidr_range = "10.0.0.0/20"
  region        = var.region
  network       = google_compute_network.main.id

  secondary_ip_range {
    range_name    = "services-pods"
    ip_cidr_range = "10.1.0.0/20"
  }

  secondary_ip_range {
    range_name    = "services-services"
    ip_cidr_range = "10.2.0.0/20"
  }
}

# VPC Connector for Cloud Run
resource "google_vpc_access_connector" "connector" {
  name          = "vpc-connector"
  ip_cidr_range = var.vpc_connector_range
  network       = google_compute_network.main.name
  region        = var.region
}
