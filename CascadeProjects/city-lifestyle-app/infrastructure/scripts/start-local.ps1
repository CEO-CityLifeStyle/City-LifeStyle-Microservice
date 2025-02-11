# Local development startup script
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('all', 'frontend', 'backend', 'database', 'services')]
    [string]$Component = 'all',
    
    [Parameter(Mandatory=$false)]
    [switch]$UseEmulators,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipBuild
)

# Configuration
$ErrorActionPreference = 'Stop'
$rootDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$dockerDir = Join-Path $rootDir "infrastructure\docker"
$envFile = Join-Path $rootDir ".env.local"

# Helper Functions
function Write-Step {
    param([string]$Message)
    Write-Host "`n=== $Message ===" -ForegroundColor Cyan
}

function Test-CommandExists {
    param([string]$Command)
    return [bool](Get-Command -Name $Command -ErrorAction SilentlyContinue)
}

function Initialize-LocalEnv {
    Write-Step "Initializing Local Environment"
    
    # Check required tools
    $requirements = @{
        'docker' = 'Docker'
        'docker-compose' = 'Docker Compose'
        'node' = 'Node.js'
        'npm' = 'NPM'
    }
    
    foreach ($req in $requirements.Keys) {
        if (-not (Test-CommandExists $req)) {
            throw "$($requirements[$req]) is not installed. Please install it first."
        }
    }
    
    # Create local environment file if not exists
    if (-not (Test-Path $envFile)) {
        Copy-Item "$envFile.example" $envFile
        Write-Host "Created .env.local file. Please update it with your local settings." -ForegroundColor Yellow
    }
}

function Start-GCPEmulators {
    Write-Step "Starting GCP Emulators"
    
    # Start Datastore emulator
    Start-Process -NoNewWindow gcloud "beta emulators datastore start --project=local-dev"
    
    # Start Pub/Sub emulator
    Start-Process -NoNewWindow gcloud "beta emulators pubsub start --project=local-dev"
    
    # Start Storage emulator
    Start-Process -NoNewWindow gcloud "beta emulators storage start --project=local-dev"
    
    # Export emulator environment variables
    $env:DATASTORE_EMULATOR_HOST = "localhost:8081"
    $env:PUBSUB_EMULATOR_HOST = "localhost:8085"
    $env:STORAGE_EMULATOR_HOST = "localhost:9023"
}

function Start-Frontend {
    Write-Step "Starting Frontend"
    
    Push-Location (Join-Path $rootDir "frontend")
    try {
        if (-not $SkipBuild) {
            npm install
            npm run build
        }
        npm run start:dev
    }
    finally {
        Pop-Location
    }
}

function Start-Backend {
    Write-Step "Starting Backend Services"
    
    # Start backend services using docker-compose
    $composeFile = Join-Path $dockerDir "docker-compose.local.yml"
    docker-compose -f $composeFile up -d backend api
}

function Start-Database {
    Write-Step "Starting Local Databases"
    
    # Start databases using docker-compose
    $composeFile = Join-Path $dockerDir "docker-compose.local.yml"
    docker-compose -f $composeFile up -d postgres redis mongodb
}

function Start-SupportingServices {
    Write-Step "Starting Supporting Services"
    
    if ($UseEmulators) {
        Start-GCPEmulators
    }
    else {
        # Start local alternatives using docker-compose
        $composeFile = Join-Path $dockerDir "docker-compose.local.yml"
        docker-compose -f $composeFile up -d minio rabbitmq elasticsearch
    }
}

# Main Logic
try {
    Initialize-LocalEnv
    
    switch ($Component) {
        'all' {
            Start-Database
            Start-SupportingServices
            Start-Backend
            Start-Frontend
        }
        'frontend' { Start-Frontend }
        'backend' { Start-Backend }
        'database' { Start-Database }
        'services' { Start-SupportingServices }
    }
    
    Write-Host "`nLocal development environment is running!" -ForegroundColor Green
    Write-Host "Frontend: http://localhost:3000"
    Write-Host "Backend API: http://localhost:8080"
    Write-Host "API Documentation: http://localhost:8080/docs"
    
    if ($UseEmulators) {
        Write-Host "`nGCP Emulators:"
        Write-Host "Datastore: localhost:8081"
        Write-Host "Pub/Sub: localhost:8085"
        Write-Host "Storage: localhost:9023"
    }
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}
