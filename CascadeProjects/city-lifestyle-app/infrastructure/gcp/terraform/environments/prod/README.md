# Production Environment Infrastructure

This directory contains the Terraform configuration for the production environment of the City Lifestyle application.

## Production Configuration

The production environment is configured with enterprise-grade settings:

### High Availability
- Regional Cloud Run deployment
- Cloud SQL with regional availability
- Multi-region Cloud Storage
- Load balancer with global anycast IP

### Security
- SSL/TLS 1.2+ enforcement
- VPC Service Controls
- Cloud Armor protection
- Private Google Access
- IAM least privilege

### Performance
- Global CDN
- Cloud Load Balancing
- Memory-optimized instances
- Connection pooling

### Monitoring
- Comprehensive dashboards
- Multi-channel alerting
- Uptime checks
- Error tracking
- Performance monitoring

### Backup & DR
- Automated backups
- Point-in-time recovery
- Cross-region replication
- Disaster recovery plan

## Deployment Order

Following the dependency hierarchy:

1. Core Infrastructure
   - Network (VPC, subnets, firewall)
   - IAM and security
   - Monitoring setup

2. Data Layer
   - Cloud Storage
   - Cloud SQL
   - Secret Manager

3. Service Layer
   - Cloud Run services
   - Pub/Sub topics
   - Load Balancer

4. API Layer
   - API Gateway
   - Cloud Armor
   - CDN

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars`:
```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Update the variables in `terraform.tfvars` with production values.

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

## Critical Notes

- All changes must go through CI/CD pipeline
- Manual changes are not allowed in production
- Follow change management process
- Monitor costs and performance
- Regular security audits
- Backup verification
- Load testing before major changes

## Rollback Procedure

1. Identify the last known good state
2. Use terraform plan to verify changes
3. Apply the rollback
4. Verify system health
5. Update documentation

## Security Considerations

- All secrets in Secret Manager
- Network isolation
- Regular security scanning
- Access audit logging
- Encryption at rest and in transit
- Regular security patches

## Cost Management

- Budget alerts
- Resource quotas
- Lifecycle policies
- Right-sizing recommendations
- Cost allocation tags
