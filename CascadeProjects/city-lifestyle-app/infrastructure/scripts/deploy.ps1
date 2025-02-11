# Universal deployment script
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('dev', 'staging', 'prod')]
    [string]$Environment,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('all', 'gcp', 'kubernetes', 'docker')]
    [string]$InfraType = 'all',
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipConfirmation
)

$ErrorActionPreference = "Stop"

# Common functions
function Write-Step {
    param($Message)
    Write-Host "`n=== $Message ===`n" -ForegroundColor Cyan
}

# Platform-specific deployment functions
function Deploy-GCP {
    param($Environment)
    Write-Step "Deploying to GCP - $Environment"
    
    # Initialize Terraform
    Set-Location "infrastructure/gcp/terraform/environments/$Environment"
    terraform init
    terraform plan
    terraform apply -auto-approve
}

function Deploy-Kubernetes {
    param($Environment)
    Write-Step "Deploying to Kubernetes - $Environment"
    
    # Apply Kustomize overlays
    Set-Location "infrastructure/kubernetes"
    kubectl apply -k "overlays/$Environment"
}

function Deploy-Docker {
    param($Environment)
    Write-Step "Deploying Docker containers - $Environment"
    
    # Use appropriate docker-compose file
    Set-Location "infrastructure/docker/$Environment"
    docker-compose -f docker-compose.yml up -d
}

function Deploy-All {
    param($Environment)
    Write-Step "Deploying all infrastructure components - $Environment"
    
    Deploy-GCP $Environment
    Deploy-Kubernetes $Environment
    Deploy-Docker $Environment
}

# Main deployment logic
try {
    Write-Step "Starting deployment: Environment=$Environment, InfraType=$InfraType"
    
    # Validate repository
    if (-not (Test-Path "infrastructure")) {
        throw "Infrastructure directory not found. Are you in the right directory?"
    }
    
    # Execute platform-specific deployment
    switch ($InfraType) {
        'all' { Deploy-All $Environment }
        'gcp' { Deploy-GCP $Environment }
        'kubernetes' { Deploy-Kubernetes $Environment }
        'docker' { Deploy-Docker $Environment }
    }
    
    Write-Step "Deployment completed successfully!"
} catch {
    Write-Host "Error during deployment: $_" -ForegroundColor Red
    exit 1
}
