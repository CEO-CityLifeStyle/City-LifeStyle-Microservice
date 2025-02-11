# Development Environment Infrastructure

This directory contains the Terraform configuration for the development environment of the City Lifestyle application.

## Configuration

The development environment is configured with the following characteristics:

### Compute Resources
- Cloud Run: Minimal instances (0-2) for cost optimization
- Memory: 512Mi per instance
- CPU: 1 core per instance

### Database
- Cloud SQL: `db-f1-micro` instance
- Zonal availability for cost savings
- Basic backup configuration (3 backups retained)

### Networking
- Private VPC with Cloud NAT
- VPC Connector for Cloud Run
- Basic load balancer without CDN

### Storage
- Standard storage class
- CORS configured for development domains
- Reduced retention periods

### Monitoring
- Basic monitoring setup
- Higher error rate thresholds
- Budget alerts enabled
- Simplified alerting rules

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars`:
```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Update the variables in `terraform.tfvars` with your specific values.

3. Initialize Terraform:
```bash
terraform init
```

4. Plan the changes:
```bash
terraform plan
```

5. Apply the configuration:
```bash
terraform apply
```

## Variables

See `variables.tf` for all available variables and their descriptions.

## Outputs

See `outputs.tf` for all available outputs and their descriptions.

## Notes

- This environment is optimized for development and testing
- Security settings are more permissive than production
- Cost optimization measures are in place
- Monitoring thresholds are relaxed
- Backup retention is minimal
