# City Lifestyle App - Deployment Guide

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Environment Setup](#environment-setup)
3. [Deployment Methods](#deployment-methods)
4. [Configuration](#configuration)
5. [Monitoring](#monitoring)
6. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Tools
- Google Cloud SDK
- Terraform >= 1.0.0
- Docker >= 20.10.0
- Node.js >= 18.0.0
- Git

### Required Accounts & Access
- Google Cloud Platform account
- Project Owner or Editor role
- Billing enabled on GCP project

### Required APIs
```bash
# These will be enabled automatically by Terraform, but you can enable them manually:
gcloud services enable \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  secretmanager.googleapis.com \
  vpcaccess.googleapis.com \
  redis.googleapis.com \
  monitoring.googleapis.com \
  logging.googleapis.com \
  pubsub.googleapis.com \
  bigquery.googleapis.com \
  artifactregistry.googleapis.com
```

## Environment Setup

### 1. Install Required Tools
```bash
# Install Google Cloud SDK
# Windows: Download and install from https://cloud.google.com/sdk/docs/install

# Install Terraform
# Windows: Download and install from https://www.terraform.io/downloads.html

# Verify installations
gcloud --version
terraform --version
```

### 2. Configure Google Cloud SDK
```bash
# Initialize gcloud
gcloud init

# Authenticate
gcloud auth login

# Configure Docker authentication
gcloud auth configure-docker

# Set project
gcloud config set project your-project-id
```

### 3. Set Up Environment Variables
```bash
# Create .env file from example
cp backend/.env.example backend/.env

# Create terraform.tfvars from example
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```

## Deployment Methods

### Method 1: Cloud Build (Recommended for Production)

1. **Trigger Deployment**
```bash
# Submit build
gcloud builds submit --config cloudbuild.yaml
```

2. **Monitor Build Progress**
```bash
# View build logs
gcloud builds log [BUILD_ID]

# List recent builds
gcloud builds list
```

### Method 2: Terraform (Infrastructure Management)

1. **Initialize Terraform**
```bash
cd terraform
terraform init
```

2. **Plan Deployment**
```bash
terraform plan -var-file="terraform.tfvars"
```

3. **Apply Configuration**
```bash
terraform apply -var-file="terraform.tfvars"
```

4. **Verify Deployment**
```bash
terraform output
```

### Method 3: Manual Deployment

1. **Build Container**
```bash
docker build -t gcr.io/[PROJECT_ID]/city-lifestyle-backend:latest ./backend
```

2. **Push to Container Registry**
```bash
docker push gcr.io/[PROJECT_ID]/city-lifestyle-backend:latest
```

3. **Deploy to Cloud Run**
```bash
gcloud run deploy city-lifestyle-backend \
  --image gcr.io/[PROJECT_ID]/city-lifestyle-backend:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated
```

## Configuration

### Secret Management

1. **Create Required Secrets**
```bash
# MongoDB URI
gcloud secrets create mongodb-uri \
  --replication-policy="automatic" \
  --data-file=- <<< "mongodb+srv://..."

# JWT Secret
gcloud secrets create jwt-secret \
  --replication-policy="automatic" \
  --data-file=- <<< "your-jwt-secret"

# Redis URL
gcloud secrets create redis-url \
  --replication-policy="automatic" \
  --data-file=- <<< "redis://..."
```

2. **Grant Access to Secrets**
```bash
gcloud secrets add-iam-policy-binding mongodb-uri \
  --member="serviceAccount:city-lifestyle-backend@[PROJECT_ID].iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

### Environment Variables

1. **Required Variables**
```
NODE_ENV=production
PORT=3000
GOOGLE_CLOUD_PROJECT=[PROJECT_ID]
BIGQUERY_DATASET_ID=city_lifestyle_analytics
ML_MODELS_BUCKET=city-lifestyle-ml-models
METRICS_SUBSCRIPTION=realtime-metrics-sub
```

2. **Optional Variables**
```
MIN_INSTANCES=1
MAX_INSTANCES=10
MEMORY_LIMIT=2Gi
CPU_LIMIT=2000m
```

## Monitoring

### Health Checks

1. **View Service Status**
```bash
gcloud run services describe city-lifestyle-backend
```

2. **Check Endpoint Health**
```bash
curl $(gcloud run services describe city-lifestyle-backend --format='value(status.url)')/health
```

### Logs

1. **View Application Logs**
```bash
gcloud logging tail "resource.type=cloud_run_revision"
```

2. **View Build Logs**
```bash
gcloud builds log [BUILD_ID]
```

### Metrics

1. **View Service Metrics**
```bash
gcloud monitoring dashboards list
```

2. **Access Cloud Monitoring**
Visit: https://console.cloud.google.com/monitoring

## Troubleshooting

### Common Issues

1. **Deployment Failures**
- Check build logs: `gcloud builds log [BUILD_ID]`
- Verify service account permissions
- Check resource quotas

2. **Container Issues**
- Check container logs: `gcloud logging tail "resource.type=cloud_run_revision"`
- Verify environment variables
- Check container health endpoint

3. **Database Connection Issues**
- Verify MongoDB URI secret
- Check VPC connector status
- Verify network firewall rules

### Recovery Steps

1. **Rollback Deployment**
```bash
# Using Cloud Run
gcloud run services update-traffic city-lifestyle-backend --to-revision=[REVISION_NAME]

# Using Terraform
terraform plan -target=[RESOURCE] -var-file="terraform.tfvars"
terraform apply -target=[RESOURCE] -var-file="terraform.tfvars"
```

2. **Reset Configuration**
```bash
# Reset to last known good state
git checkout [LAST_GOOD_COMMIT]
gcloud builds submit --config cloudbuild.yaml
```

### Support Resources

1. **Documentation**
- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Cloud Build Documentation](https://cloud.google.com/build/docs)

2. **Monitoring Tools**
- Cloud Monitoring Dashboard
- Error Reporting
- Cloud Trace
- Cloud Profiler

3. **Contact**
- Technical Support: [support@citylifestyle.com](mailto:support@citylifestyle.com)
- DevOps Team: [devops@citylifestyle.com](mailto:devops@citylifestyle.com)
