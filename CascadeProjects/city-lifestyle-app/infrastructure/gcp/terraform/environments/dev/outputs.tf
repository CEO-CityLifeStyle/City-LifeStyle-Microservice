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
    instance_name   = module.sql.instance_name
    connection_name = module.sql.connection_name
    database_name   = module.sql.database_name
  }
  sensitive = true
}

output "cloudrun_services" {
  description = "Cloud Run service URLs"
  value = {
    url = module.cloudrun.service_url
  }
}

output "load_balancer" {
  description = "Load balancer information"
  value = {
    ip_address = module.loadbalancer.load_balancer_ip
    url        = module.loadbalancer.load_balancer_url
  }
}

output "network" {
  description = "Network information"
  value = {
    vpc_id            = module.network.vpc_id
    vpc_name          = module.network.network_name
    private_subnet_id = module.network.private_subnet_id
    connector_id      = module.network.vpc_connector_id
  }
}

output "service_accounts" {
  description = "Service account emails"
  value = {
    cloudrun = module.iam.service_account_email
  }
}
