# City Lifestyle App - Multi-Platform Infrastructure

This infrastructure setup supports multiple deployment options:
- GCP Cloud Native
- Kubernetes (Cloud or Self-hosted)
- Container-based (Docker Compose)

## Directory Structure
```
infrastructure/
├── gcp/                    # GCP Cloud Native
│   ├── terraform/          # GCP Infrastructure as Code
│   │   ├── core/          # Core infrastructure components
│   │   │   ├── api_gateway/   # API Gateway & OpenAPI specs
│   │   │   ├── backup/        # Backup & disaster recovery
│   │   │   ├── bigquery/      # Analytics data warehouse
│   │   │   ├── dataflow/      # Data processing pipelines
│   │   │   ├── firestore/     # NoSQL database
│   │   │   ├── iam/          # Core IAM roles & accounts
│   │   │   ├── logging/      # Centralized logging
│   │   │   ├── monitoring/   # Platform monitoring
│   │   │   ├── network/      # VPC, NAT, firewall
│   │   │   ├── pubsub/       # Event messaging
│   │   │   ├── secrets/      # Secret Manager config
│   │   │   ├── spanner/      # Distributed database
│   │   │   ├── sql/          # Relational databases
│   │   │   ├── storage/      # Cloud Storage config
│   │   │   └── vpc_sc/       # VPC Service Controls
│   │   ├── modules/          # Reusable infrastructure modules
│   │   │   ├── bigquery/     # BigQuery module
│   │   │   ├── cdn/          # Content Delivery Network
│   │   │   ├── cloudrun/     # Cloud Run services
│   │   │   ├── dataflow/     # Dataflow jobs
│   │   │   ├── firestore/    # Firestore databases
│   │   │   ├── frontend/     # Frontend hosting
│   │   │   ├── loadbalancer/ # Load balancing
│   │   │   ├── monitoring/   # Monitoring & alerting
│   │   │   ├── network/      # VPC, subnets, firewall
│   │   │   ├── pubsub/       # Pub/Sub messaging
│   │   │   ├── spanner/      # Cloud Spanner
│   │   │   ├── sql/          # Cloud SQL databases
│   │   │   └── storage/      # Cloud Storage buckets
│   │   ├── environments/     # Environment configurations
│   │   │   ├── dev/         # Development environment
│   │   │   ├── staging/     # Staging environment
│   │   │   └── prod/        # Production environment
│   │   └── variables/       # Shared Terraform variables
│   ├── cloudbuild/         # CI/CD Configuration
│   │   ├── pipelines/      # Cloud Build pipelines
│   │   │   ├── backend-deploy.yaml    # Backend deployment
│   │   │   ├── frontend-deploy.yaml   # Frontend deployment
│   │   │   ├── terraform-plan.yaml    # Infrastructure planning
│   │   │   └── terraform-apply.yaml   # Infrastructure deployment
│   │   ├── scripts/        # Deployment scripts
│   │   │   ├── deploy.sh   # Deployment automation
│   │   │   └── destroy.sh  # Environment cleanup
│   │   └── triggers.tf     # Cloud Build triggers
│   └── monitoring/         # Monitoring Configuration
│       ├── dashboards/     # Monitoring dashboards
│       │   └── platform_dashboard.json
│       └── alerts/         # Alert policies
│           ├── error_rate.yaml
│           ├── high_latency.yaml
│           └── resource_usage.yaml
├── kubernetes/            # Kubernetes Deployments
│   ├── base/              # Base configurations
│   │   ├── frontend/      # Frontend deployments
│   │   ├── backend/       # Backend services
│   │   └── shared/        # Shared resources
│   ├── overlays/          # Environment-specific configs
│   │   ├── dev/
│   │   ├── staging/
│   │   └── prod/
│   └── helm/              # Helm charts
├── docker/                # Container Configurations
│   ├── local/            # Local development
│   │   ├── docker-compose.yml          # Backend services
│   │   ├── docker-compose.frontend.yml # Frontend service
│   │   ├── nginx/                      # Nginx configurations
│   │   │   ├── frontend.conf           # Frontend routing
│   │   │   └── nginx.conf             # Base configuration
│   │   └── .env                        # Local environment variables
│   └── prod/             # Production configuration
│       ├── docker-compose.yml          # All services
│       ├── nginx/                      # Nginx configurations
│       │   ├── nginx.conf              # Base configuration
│       │   └── conf.d/                 # Service configurations
│       │       └── default.conf        # Main routing
│       └── .env.example                # Environment template
└── scripts/              # Infrastructure Management Scripts
    ├── common/          # Shared utilities and functions
    │   ├── logging.ps1      # Logging utilities
    │   ├── validation.ps1   # Input validation
    │   └── config.ps1       # Configuration management
    ├── gcp/            # GCP-specific scripts
    │   ├── init-project.ps1     # Project initialization
    │   ├── setup-monitoring.ps1  # Monitoring configuration
    │   ├── backup.ps1           # Backup management
    │   ├── secrets.ps1          # Secrets management
    │   └── cleanup.ps1          # Resource cleanup
    ├── kubernetes/     # Kubernetes management
    │   ├── setup-cluster.ps1    # Cluster initialization
    │   ├── deploy-apps.ps1      # Application deployment
    │   ├── setup-monitoring.ps1 # K8s monitoring
    │   ├── update-secrets.ps1   # K8s secrets
    │   └── cleanup.ps1          # Cluster cleanup
    ├── docker/         # Docker management
    │   ├── build-images.ps1     # Image building
    │   ├── push-images.ps1      # Registry pushing
    │   ├── cleanup-images.ps1   # Image cleanup
    │   └── test-locally.ps1     # Local testing
    ├── deploy.ps1      # Main deployment script
    ├── start-local.ps1 # Local development
    └── cleanup.ps1     # Environment cleanup

```
## Service Build Configurations

### Service-Level Dockerfiles
The build configurations (Dockerfiles) are maintained in their respective service directories:

1. Backend Service Builds (`/backend`):
   - `Dockerfile` - API service with development/production stages
   - `Dockerfile.auth` - Auth service with development/production stages

2. Frontend Service Build (`/frontend`):
   - `Dockerfile` - Frontend application with development/production stages

This separation ensures:
- Service teams own their build process
- Build configurations stay close to the code
- Clear separation between infrastructure and application concerns

### Infrastructure-Level Docker Configurations
The Docker infrastructure configurations in `infrastructure/docker/` manage:
- Service orchestration (docker-compose)
- Environment-specific settings
- Networking and reverse proxy
- Shared resources (databases, caches)

## Frontend Deployment Options

1. GCP Cloud Native
```hcl
# Host on Cloud Storage + Cloud CDN
module "frontend" {
  source = "./modules/frontend"
  
  project_id = var.project_id
  domain     = var.frontend_domain
  
  # Existing CDN configuration
  cdn_configuration = {
    cache_mode = "CACHE_ALL_STATIC"
    default_ttl = 3600
  }
}
```

2. Kubernetes
```yaml
# Frontend deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: frontend
        image: ${FRONTEND_IMAGE}
        ports:
        - containerPort: 80
```

3. Docker Compose
```yaml
services:
  frontend:
    build:
      context: ../frontend
      target: production
    ports:
      - "80:80"
    depends_on:
      - api
```

## Quick Start

### Local Development
```powershell
# Start local development environment
cd infrastructure/docker/local
docker-compose -f docker-compose.yml -f docker-compose.frontend.yml up -d

# Build and start specific services
docker-compose -f docker-compose.yml -f docker-compose.frontend.yml up -d --build frontend api

# View logs
docker-compose -f docker-compose.yml -f docker-compose.frontend.yml logs -f
```

### Production Deployment
```powershell
# Build production images
cd infrastructure/docker/prod
docker-compose build

# Deploy to production
docker-compose up -d

# Scale services
docker-compose up -d --scale api=3 --scale auth=2
```

### Environment Variables
1. Local Development:
   - Copy `infrastructure/docker/local/.env.example` to `.env`
   - Modify variables as needed

2. Production:
   - Copy `infrastructure/docker/prod/.env.example` to `.env`
   - Set secure values for all required variables

## Health Checks and Monitoring

### Service Health Checks
All services include built-in health checks:
- Frontend: `http://localhost:3000/health`
- API: `http://localhost:8080/health`
- Auth: `http://localhost:8081/health`

### Monitoring Integration
The Docker configurations support:
- Container metrics
- Log aggregation
- Health check monitoring
- Resource usage tracking

## Security Notes

1. Environment Variables:
   - Never commit `.env` files
   - Use `.env.example` as templates
   - Store sensitive values in secure vaults

2. Production Deployment:
   - Always use production-optimized images
   - Enable security features in nginx
   - Follow least privilege principle
   - Regularly update base images

## Cleanup

```powershell
# Stop and remove containers
docker-compose down

# Clean up unused resources
./scripts/docker/cleanup.ps1

# Remove all related resources
docker-compose down -v --remove-orphans
```

## Production Deployment Options

1. GCP Cloud Native
```bash
# Deploy to GCP (includes frontend)
./scripts/gcp/deploy.sh [env] --with-frontend
```

2. Kubernetes
```bash
# Deploy to any Kubernetes cluster
./scripts/kubernetes/deploy.sh [env] [cluster] --with-frontend
```

3. Container-based
```bash
# Deploy containers including frontend
./scripts/docker/deploy.sh [env] --with-frontend
```

## Configuration

### Frontend Configuration
Each environment has its own frontend configuration:
- API endpoints
- Feature flags
- Environment variables
- Build optimization

### Existing Terraform Variables
```hcl
# From terraform.tfvars
project_id = var.project_id
region = var.region
environment = var.environment

# Resource limits
min_instances = var.min_instances
max_instances = var.max_instances
memory_limit = var.memory_limit
cpu_limit = var.cpu_limit

# Network
vpc_connector_range = var.vpc_connector_range

# Storage
bigquery_location = var.bigquery_location
storage_class = var.storage_class
bucket_lifecycle_age = var.bucket_lifecycle_age
```

## Deployment Matrix

| Component | GCP Native | Kubernetes | Docker |
|-----------|------------|------------|---------|
| Frontend  | Cloud Storage + CDN | Nginx Ingress | Nginx Container |
| Backend   | Cloud Run | Deployments | Containers |
| Database  | Cloud SQL | StatefulSet | Container |
| Cache     | Memorystore | Redis Cluster | Redis Container |
| Storage   | Cloud Storage | PVC | Volume Mount |

See each platform's README for specific configuration options.
