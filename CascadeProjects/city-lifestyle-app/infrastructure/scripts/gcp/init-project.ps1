param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectId,
    
    [Parameter(Mandatory=$true)]
    [string]$Region,
    
    [Parameter(Mandatory=$false)]
    [string]$BillingAccountId
)

# Configuration
$ErrorActionPreference = 'Stop'
$requiredApis = @(
    'cloudresourcemanager.googleapis.com',
    'iam.googleapis.com',
    'compute.googleapis.com',
    'container.googleapis.com',
    'cloudbuild.googleapis.com',
    'run.googleapis.com',
    'secretmanager.googleapis.com',
    'servicenetworking.googleapis.com',
    'sqladmin.googleapis.com',
    'monitoring.googleapis.com',
    'logging.googleapis.com',
    'cloudtrace.googleapis.com',
    'cloudfunctions.googleapis.com',
    'apigateway.googleapis.com',
    'spanner.googleapis.com',
    'firestore.googleapis.com',
    'bigquery.googleapis.com',
    'dataflow.googleapis.com',
    'pubsub.googleapis.com',
    'storage.googleapis.com'
)

function Write-Step {
    param([string]$Message)
    Write-Host "`n=== $Message ===" -ForegroundColor Cyan
}

# Create new project if it doesn't exist
Write-Step "Creating/Setting Project"
$projectExists = gcloud projects list --filter="project_id:$ProjectId" --format="value(project_id)"
if (-not $projectExists) {
    Write-Host "Creating new project: $ProjectId"
    if ($BillingAccountId) {
        gcloud projects create $ProjectId --set-as-default
        gcloud beta billing projects link $ProjectId --billing-account=$BillingAccountId
    }
    else {
        Write-Host "Warning: No billing account specified. Some features may be limited." -ForegroundColor Yellow
        gcloud projects create $ProjectId --set-as-default
    }
}
else {
    Write-Host "Project $ProjectId already exists"
    gcloud config set project $ProjectId
}

# Enable required APIs
Write-Step "Enabling Required APIs"
foreach ($api in $requiredApis) {
    Write-Host "Enabling $api"
    gcloud services enable $api
}

# Set up service accounts
Write-Step "Creating Service Accounts"
$serviceAccounts = @{
    'terraform' = 'Terraform Service Account'
    'cloudbuild' = 'Cloud Build Service Account'
    'cloudrun' = 'Cloud Run Service Account'
}

foreach ($sa in $serviceAccounts.Keys) {
    $saEmail = "$sa@$ProjectId.iam.gserviceaccount.com"
    $saExists = gcloud iam service-accounts list --filter="email:$saEmail" --format="value(email)"
    
    if (-not $saExists) {
        Write-Host "Creating service account: $sa"
        gcloud iam service-accounts create $sa --display-name=$serviceAccounts[$sa]
    }
    else {
        Write-Host "Service account $sa already exists"
    }
}

# Set up IAM roles
Write-Step "Setting up IAM Roles"
$roles = @(
    'roles/editor',
    'roles/iam.serviceAccountUser',
    'roles/secretmanager.admin',
    'roles/storage.admin',
    'roles/cloudbuild.builds.editor',
    'roles/run.admin'
)

foreach ($role in $roles) {
    gcloud projects add-iam-policy-binding $ProjectId `
        --member="serviceAccount:terraform@$ProjectId.iam.gserviceaccount.com" `
        --role=$role
}

# Create storage buckets
Write-Step "Creating Storage Buckets"
$buckets = @(
    "$ProjectId-terraform-state",
    "$ProjectId-artifacts",
    "$ProjectId-backups"
)

foreach ($bucket in $buckets) {
    $bucketExists = gsutil ls -b "gs://$bucket" 2>$null
    if (-not $bucketExists) {
        Write-Host "Creating bucket: $bucket"
        gsutil mb -l $Region "gs://$bucket"
        gsutil versioning set on "gs://$bucket"
    }
    else {
        Write-Host "Bucket $bucket already exists"
    }
}

# Create VPC network
Write-Step "Setting up VPC Network"
$network = "city-lifestyle-network"
$subnet = "city-lifestyle-subnet"
$networkExists = gcloud compute networks list --filter="name=$network" --format="value(name)"

if (-not $networkExists) {
    Write-Host "Creating VPC network: $network"
    gcloud compute networks create $network --subnet-mode=custom
    
    Write-Host "Creating subnet: $subnet"
    gcloud compute networks subnets create $subnet `
        --network=$network `
        --region=$Region `
        --range=10.0.0.0/20
}
else {
    Write-Host "VPC network $network already exists"
}

Write-Host "`nProject initialization completed successfully!" -ForegroundColor Green
Write-Host "Next steps:"
Write-Host "1. Update terraform/environments/*/terraform.tfvars with your project settings"
Write-Host "2. Run deploy.ps1 to deploy the infrastructure"
Write-Host "3. Set up Cloud Build triggers for CI/CD"
