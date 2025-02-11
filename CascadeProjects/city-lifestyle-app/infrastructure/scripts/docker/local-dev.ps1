# Docker Local Development Script

# Import common utilities
. "$PSScriptRoot\..\common\logging.ps1"
. "$PSScriptRoot\..\common\validation.ps1"
. "$PSScriptRoot\..\common\config.ps1"

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('all', 'frontend', 'backend', 'api')]
    [string]$Component = 'all',
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('up', 'down', 'logs', 'status')]
    [string]$Action = 'up',
    
    [Parameter(Mandatory=$false)]
    [switch]$Build,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force
)

# Initialize configuration
$config = Initialize-Configuration -Environment 'dev'
if (-not $config) {
    exit 1
}

# Validate Docker configuration
if (-not (Test-DockerConfiguration)) {
    exit 1
}

# Docker Compose file paths
$composeFiles = @(
    "$PSScriptRoot\..\..\docker-compose.yml"
)

if (Test-Path "$PSScriptRoot\..\..\docker-compose.override.yml") {
    $composeFiles += "$PSScriptRoot\..\..\docker-compose.override.yml"
}

function Get-ComposeCommand {
    $composeStr = $composeFiles | ForEach-Object { "-f $_" }
    return "docker-compose $composeStr"
}

function Start-LocalDev {
    param([string]$ServiceName)
    
    Write-Step "Starting local development environment"
    
    $compose = Get-ComposeCommand
    $buildFlag = if ($Build) { "--build" } else { "" }
    
    if ($ServiceName -eq 'all') {
        Invoke-Expression "$compose up -d $buildFlag"
    }
    else {
        Invoke-Expression "$compose up -d $buildFlag $ServiceName"
    }
    
    # Wait for services to be healthy
    $maxAttempts = 30
    $attempt = 1
    $healthy = $false
    
    while (-not $healthy -and $attempt -le $maxAttempts) {
        $services = Invoke-Expression "$compose ps --format json" | ConvertFrom-Json
        $unhealthy = $services | Where-Object { $_.State -ne "running" }
        
        if ($unhealthy) {
            Write-Log "Waiting for services to be healthy (Attempt $attempt/$maxAttempts)..."
            Start-Sleep -Seconds 2
            $attempt++
        }
        else {
            $healthy = $true
        }
    }
    
    if (-not $healthy) {
        throw "Timeout waiting for services to be healthy"
    }
    
    # Display service URLs
    Write-Host "`nService URLs:"
    Write-Host "Frontend: http://localhost:3000"
    Write-Host "Backend: http://localhost:8000"
    Write-Host "API: http://localhost:8080"
    Write-Host "Adminer (Database UI): http://localhost:8081"
}

function Stop-LocalDev {
    Write-Step "Stopping local development environment"
    
    $compose = Get-ComposeCommand
    if ($Force) {
        Invoke-Expression "$compose down -v --remove-orphans"
    }
    else {
        Invoke-Expression "$compose down"
    }
}

function Show-Logs {
    param([string]$ServiceName)
    
    Write-Step "Showing logs"
    
    $compose = Get-ComposeCommand
    if ($ServiceName -eq 'all') {
        Invoke-Expression "$compose logs -f"
    }
    else {
        Invoke-Expression "$compose logs -f $ServiceName"
    }
}

function Show-Status {
    Write-Step "Showing service status"
    
    $compose = Get-ComposeCommand
    
    # Show running containers
    Write-Host "`nRunning Containers:"
    Invoke-Expression "$compose ps"
    
    # Show resource usage
    Write-Host "`nResource Usage:"
    docker stats --no-stream
}

function Initialize-LocalEnv {
    Write-Step "Initializing local environment"
    
    # Create docker network if it doesn't exist
    docker network create city-lifestyle 2>$null
    
    # Create data directories
    $dataDir = "$PSScriptRoot\..\..\data"
    $dirs = @(
        "$dataDir\postgres",
        "$dataDir\redis",
        "$dataDir\minio"
    )
    
    foreach ($dir in $dirs) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir | Out-Null
        }
    }
    
    # Create .env file if it doesn't exist
    $envFile = "$PSScriptRoot\..\..\.env"
    if (-not (Test-Path $envFile)) {
        @"
# Database
POSTGRES_DB=city_lifestyle
POSTGRES_USER=developer
POSTGRES_PASSWORD=developer_password

# Redis
REDIS_PASSWORD=redis_password

# MinIO
MINIO_ROOT_USER=minio
MINIO_ROOT_PASSWORD=minio_password

# API
API_KEY=development_api_key

# Frontend
REACT_APP_API_URL=http://localhost:8080
"@ | Set-Content $envFile
    }
}

try {
    # Map component to service names
    $serviceMap = @{
        'frontend' = 'frontend'
        'backend' = 'backend'
        'api' = 'api'
        'all' = 'all'
    }
    
    $serviceName = $serviceMap[$Component]
    if (-not $serviceName) {
        throw "Invalid component: $Component"
    }
    
    # Initialize environment
    Initialize-LocalEnv
    
    # Execute requested action
    switch ($Action) {
        'up' { Start-LocalDev -ServiceName $serviceName }
        'down' { Stop-LocalDev }
        'logs' { Show-Logs -ServiceName $serviceName }
        'status' { Show-Status }
    }
}
catch {
    Write-Error "Local development operation failed: $_"
    exit 1
}
