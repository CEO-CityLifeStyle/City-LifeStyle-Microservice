# City Lifestyle App - Deployment Guide

This guide provides step-by-step instructions for deploying the City Lifestyle App using different deployment strategies.

## Table of Contents
- [Prerequisites](#prerequisites)
- [GCP Cloud Native Deployment](#gcp-cloud-native-deployment)
- [Kubernetes Deployment](#kubernetes-deployment)
- [Docker Compose Deployment](#docker-compose-deployment)
- [Monitoring and Maintenance](#monitoring-and-maintenance)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### Common Requirements
- Git
- PowerShell 7.0+
- Docker Desktop
- Access to deployment environment

### GCP Deployment Requirements
- Google Cloud SDK
- Terraform 1.0+
- GCP Project with billing enabled
- GCP Service Account with required permissions

### Kubernetes Requirements
- kubectl
- Helm 3.0+
- Access to Kubernetes cluster
- kubectl context configured

### Docker Compose Requirements
- Docker Compose v2.0+
- Access to container registry
- SSL certificates for production

## GCP Cloud Native Deployment

### 1. Initial Setup
```powershell
# Clone repository if not already done
git clone https://github.com/your-org/city-lifestyle-app.git
cd city-lifestyle-app

# Initialize GCP project
cd infrastructure/scripts/gcp
./init-project.ps1 -ProjectId "your-project-id"

# Authenticate with GCP
gcloud auth login
gcloud config set project your-project-id
```

### 2. Infrastructure Deployment
```powershell
# Initialize Terraform
cd ../../gcp/terraform
terraform init

# Create workspace for your environment
terraform workspace new prod  # or dev/staging

# Review infrastructure changes
terraform plan -var-file="environments/prod/terraform.tfvars"

# Apply infrastructure
terraform apply -var-file="environments/prod/terraform.tfvars"
```

### 3. Application Deployment
```powershell
# Deploy applications
cd ../../scripts/gcp
./deploy-apps.ps1 -Environment prod

# Verify deployment
./verify-deployment.ps1 -Environment prod
```

## Kubernetes Deployment

### 1. Cluster Setup
```powershell
# Setup Kubernetes cluster
cd infrastructure/scripts/kubernetes
./setup-cluster.ps1 -Environment prod

# Verify cluster access
kubectl get nodes
```

### 2. Infrastructure Components
```powershell
# Install required Helm charts
cd ../kubernetes/helm
./install-charts.ps1 -Environment prod

# Setup monitoring
cd ../scripts/kubernetes
./setup-monitoring.ps1 -Environment prod
```

### 3. Application Deployment
```powershell
# Deploy applications
./deploy-apps.ps1 -Environment prod

# Verify deployment
kubectl get pods -n prod
kubectl get services -n prod
```

## Docker Compose Deployment

### 1. Environment Setup
```powershell
# Navigate to production docker compose directory
cd infrastructure/docker/prod

# Copy and configure environment variables
cp .env.example .env
# Edit .env with your production values
```

### 2. Build and Deploy
```powershell
# Build all services
docker-compose build

# Deploy services
docker-compose up -d

# Scale services as needed
docker-compose up -d --scale api=3 --scale auth=2
```

### 3. Verify Deployment
```powershell
# Check service status
docker-compose ps

# View logs
docker-compose logs -f
```

## Monitoring and Maintenance

### Health Checks
```powershell
# GCP
./scripts/gcp/health-check.ps1 -Environment prod

# Kubernetes
kubectl get pods -n prod
kubectl describe pods -n prod

# Docker Compose
docker-compose ps
curl http://localhost/health
```

### Logging
```powershell
# GCP
./scripts/gcp/view-logs.ps1 -Service api -Environment prod

# Kubernetes
kubectl logs -n prod deployment/api
kubectl logs -n prod deployment/frontend

# Docker Compose
docker-compose logs -f api
docker-compose logs -f frontend
```

### Backup
```powershell
# Database backup
./scripts/gcp/backup.ps1 -Environment prod

# Verify backup
./scripts/gcp/list-backups.ps1 -Environment prod
```

## Troubleshooting

### Common Issues

1. Connection Issues
```powershell
# Check service connectivity
./scripts/troubleshoot/check-connectivity.ps1 -Environment prod

# Verify DNS resolution
./scripts/troubleshoot/check-dns.ps1 -Environment prod
```

2. Performance Issues
```powershell
# Check resource usage
./scripts/troubleshoot/check-resources.ps1 -Environment prod

# View performance metrics
./scripts/troubleshoot/view-metrics.ps1 -Environment prod
```

3. Deployment Issues
```powershell
# Verify configurations
./scripts/troubleshoot/verify-config.ps1 -Environment prod

# Check deployment status
./scripts/troubleshoot/deployment-status.ps1 -Environment prod
```

### Recovery Procedures

1. Service Recovery
```powershell
# Restart services
./scripts/recovery/restart-services.ps1 -Environment prod

# Rollback deployment
./scripts/recovery/rollback.ps1 -Environment prod -Version previous
```

2. Data Recovery
```powershell
# Restore database
./scripts/recovery/restore-db.ps1 -Environment prod -BackupId latest

# Verify restoration
./scripts/recovery/verify-data.ps1 -Environment prod
```

## Security Notes

1. Always rotate credentials after deployment
```powershell
./scripts/security/rotate-credentials.ps1 -Environment prod
```

2. Enable audit logging
```powershell
./scripts/security/enable-audit.ps1 -Environment prod
```

3. Review security configurations
```powershell
./scripts/security/security-check.ps1 -Environment prod
```

## Post-Deployment

1. Verify all services are running
2. Check monitoring dashboards
3. Test all critical paths
4. Review security settings
5. Document deployment-specific configurations

For additional support or questions, please refer to:
- [Infrastructure Documentation](./README.md)
- [Troubleshooting Guide](./docs/troubleshooting.md)
- [Security Guidelines](./docs/security.md)
