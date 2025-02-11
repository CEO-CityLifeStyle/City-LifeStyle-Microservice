# Docker Image Build Script

# Import common utilities
. "$PSScriptRoot\..\common\logging.ps1"
. "$PSScriptRoot\..\common\validation.ps1"
. "$PSScriptRoot\..\common\config.ps1"

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('dev', 'staging', 'prod')]
    [string]$Environment,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('all', 'frontend', 'backend', 'api')]
    [string]$Component = 'all',
    
    [Parameter(Mandatory=$false)]
    [string]$Version = 'latest',
    
    [Parameter(Mandatory=$false)]
    [switch]$Push,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force
)

# Initialize configuration
$config = Initialize-Configuration -Environment $Environment
if (-not $config) {
    exit 1
}

# Validate Docker configuration
if (-not (Test-DockerConfiguration)) {
    exit 1
}

function Build-DockerImage {
    param(
        [string]$Name,
        [string]$Path,
        [string]$Dockerfile = "Dockerfile",
        [hashtable]$BuildArgs = @{}
    )
    
    Write-Step "Building Docker image: $Name"
    
    $registry = "gcr.io/$($config.Project.Name)"
    $tag = "$registry/$Name`:$Version"
    
    # Build arguments
    $buildArgsStr = ""
    foreach ($key in $BuildArgs.Keys) {
        $buildArgsStr += "--build-arg $key=$($BuildArgs[$key]) "
    }
    
    # Build image
    $buildCmd = "docker build -t $tag -f $Path/$Dockerfile $buildArgsStr $Path"
    Write-Log "Running: $buildCmd"
    Invoke-Expression $buildCmd
    
    if ($Push) {
        Write-Log "Pushing image to registry: $tag"
        docker push $tag
    }
    
    return $tag
}

function Build-Frontend {
    $frontendPath = "$PSScriptRoot\..\..\frontend"
    $buildArgs = @{
        "NODE_ENV" = $Environment
        "API_URL" = $config.API.Url
    }
    
    Build-DockerImage -Name "frontend" -Path $frontendPath -BuildArgs $buildArgs
}

function Build-Backend {
    $backendPath = "$PSScriptRoot\..\..\backend"
    $buildArgs = @{
        "ENV" = $Environment
        "DB_HOST" = $config.Database.Host
        "DB_PORT" = $config.Database.Port
    }
    
    Build-DockerImage -Name "backend" -Path $backendPath -BuildArgs $buildArgs
}

function Build-API {
    $apiPath = "$PSScriptRoot\..\..\api"
    $buildArgs = @{
        "ENV" = $Environment
        "API_VERSION" = $Version
    }
    
    Build-DockerImage -Name "api" -Path $apiPath -BuildArgs $buildArgs
}

try {
    # Authenticate with GCR if pushing
    if ($Push) {
        Write-Step "Authenticating with Google Container Registry"
        gcloud auth configure-docker gcr.io --quiet
    }
    
    # Build components
    $images = @()
    
    switch ($Component) {
        'all' {
            $images += Build-Frontend
            $images += Build-Backend
            $images += Build-API
        }
        'frontend' {
            $images += Build-Frontend
        }
        'backend' {
            $images += Build-Backend
        }
        'api' {
            $images += Build-API
        }
    }
    
    Write-Success "Image build completed successfully!"
    
    # Display image information
    Write-Host "`nBuilt Images:"
    foreach ($image in $images) {
        Write-Host "  $image"
        
        # Show image size
        $size = docker images --format "{{.Size}}" $image
        Write-Host "  Size: $size"
    }
    
    if ($Push) {
        Write-Host "`nImages have been pushed to Google Container Registry"
    }
}
catch {
    Write-Error "Image build failed: $_"
    exit 1
}
