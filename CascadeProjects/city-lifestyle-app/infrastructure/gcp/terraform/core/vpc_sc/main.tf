# VPC Service Controls Configuration

# Service Perimeter
resource "google_access_context_manager_service_perimeter" "city_lifestyle" {
  parent = "accessPolicies/${var.access_policy_name}"
  name   = "accessPolicies/${var.access_policy_name}/servicePerimeters/city_lifestyle"
  title  = "City Lifestyle Service Perimeter"
  status {
    restricted_services = [
      "cloudfunctions.googleapis.com",
      "cloudrun.googleapis.com",
      "sqladmin.googleapis.com",
      "storage.googleapis.com",
      "secretmanager.googleapis.com"
    ]
    
    resources = [
      "projects/${var.project_number}"
    ]
    
    access_levels = [google_access_context_manager_access_level.trusted_access.name]

    vpc_accessible_services {
      enable_restriction = true
      allowed_services   = ["RESTRICTED-SERVICES"]
    }
  }
}

# Access Level
resource "google_access_context_manager_access_level" "trusted_access" {
  parent = "accessPolicies/${var.access_policy_name}"
  name   = "accessPolicies/${var.access_policy_name}/accessLevels/trusted_access"
  title  = "Trusted Access"
  basic {
    conditions {
      ip_subnetworks = var.trusted_ip_ranges
      
      required_access_levels = []
      
      members = [
        "serviceAccount:${var.backend_service_account}",
        "serviceAccount:${var.cicd_service_account}"
      ]
      
      regions = [
        "US",
        "EU"
      ]
      
      device_policy {
        require_screen_lock = true
        os_constraints {
          os_type = "DESKTOP_MAC"
        }
        os_constraints {
          os_type = "DESKTOP_WINDOWS"
        }
        os_constraints {
          os_type = "DESKTOP_LINUX"
        }
      }
    }
  }
}

# Bridge Service Perimeter
resource "google_access_context_manager_service_perimeter" "bridge" {
  parent = "accessPolicies/${var.access_policy_name}"
  name   = "accessPolicies/${var.access_policy_name}/servicePerimeters/bridge"
  title  = "Bridge Service Perimeter"
  perimeter_type = "BRIDGE"
  status {
    resources = [
      "projects/${var.project_number}"
    ]
  }
}

# Outputs
output "perimeter_name" {
  value = google_access_context_manager_service_perimeter.city_lifestyle.name
}

output "access_level_name" {
  value = google_access_context_manager_access_level.trusted_access.name
}
