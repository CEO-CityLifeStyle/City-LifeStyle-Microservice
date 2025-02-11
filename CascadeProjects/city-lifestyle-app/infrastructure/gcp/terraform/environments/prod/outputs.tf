output "storage_buckets" {
  description = "Storage bucket names"
  value = {
    frontend = module.storage.frontend_bucket_name
    uploads  = module.storage.uploads_bucket_name
    backups  = module.storage.backups_bucket_name
  }
}

output "database" {
  description = "Database connection information"
  value = {
    instance_name    = module.sql.instance_name
    connection_name  = module.sql.connection_name
    database_name    = module.sql.database_name
    private_ip      = module.sql.private_ip
  }
  sensitive = true
}

output "cloudrun_services" {
  description = "Cloud Run service URLs"
  value = {
    url = module.cloudrun.service_url
    revision = module.cloudrun.latest_revision
    status   = module.cloudrun.service_status
  }
}

output "load_balancer" {
  description = "Load balancer information"
  value = {
    ip_address     = module.loadbalancer.load_balancer_ip
    ssl_cert_id    = module.loadbalancer.ssl_certificate_id
    ssl_policy_id  = module.loadbalancer.ssl_policy_id
    backend_service = module.loadbalancer.backend_service_id
  }
}

output "network" {
  description = "Network information"
  value = {
    vpc_id            = module.network.vpc_id
    vpc_name          = module.network.network_name
    private_subnet_id = module.network.private_subnet_id
    connector_id      = module.network.vpc_connector_id
    nat_ip            = module.network.nat_ip
  }
}

output "monitoring" {
  description = "Monitoring configuration"
  value = {
    dashboard_url = module.monitoring.dashboard_url
    alert_policies = module.monitoring.alert_policy_ids
    uptime_check_ids = module.monitoring.uptime_check_ids
  }
}

output "cdn" {
  description = "CDN configuration"
  value = {
    backend_bucket = module.cdn.backend_bucket_name
    url_map        = module.cdn.url_map_id
    ssl_cert       = module.cdn.ssl_certificate_id
  }
}

output "service_accounts" {
  description = "Service account emails"
  value = {
    cloudrun = module.iam.service_account_email
    monitoring = module.iam.monitoring_service_account
    backup     = module.iam.backup_service_account
  }
  sensitive = true
}
