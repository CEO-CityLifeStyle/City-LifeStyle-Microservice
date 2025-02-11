# Docker Image Testing Script

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
    [switch]$KeepContainers,
    
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

function Test-DockerImage {
    param(
        [string]$Name,
        [string]$TestCommand,
        [hashtable]$Environment = @{},
        [string[]]$Volumes = @(),
        [string[]]$Networks = @()
    )
    
    Write-Step "Testing Docker image: $Name"
    
    $registry = "gcr.io/$($config.Project.Name)"
    $tag = "$registry/$Name`:$Version"
    
    # Environment variables
    $envStr = ""
    foreach ($key in $Environment.Keys) {
        $envStr += "-e $key=$($Environment[$key]) "
    }
    
    # Volumes
    $volumeStr = ""
    foreach ($volume in $Volumes) {
        $volumeStr += "-v $volume "
    }
    
    # Networks
    $networkStr = ""
    foreach ($network in $Networks) {
        $networkStr += "--network $network "
    }
    
    # Create test container
    $containerName = "test-$Name-$(Get-Random)"
    $runCmd = "docker run --rm -d --name $containerName $envStr $volumeStr $networkStr $tag"
    Write-Log "Starting test container: $runCmd"
    Invoke-Expression $runCmd
    
    try {
        # Run test command
        Write-Log "Running tests: $TestCommand"
        $testResult = docker exec $containerName $TestCommand
        Write-Log $testResult
        
        # Check exit code
        $exitCode = docker inspect $containerName --format='{{.State.ExitCode}}'
        if ($exitCode -ne 0) {
            throw "Tests failed with exit code $exitCode"
        }
    }
    finally {
        if (-not $KeepContainers) {
            Write-Log "Cleaning up test container"
            docker rm -f $containerName 2>$null
        }
    }
}

function Test-Frontend {
    $testEnv = @{
        "NODE_ENV" = "test"
        "CI" = "true"
    }
    
    Test-DockerImage -Name "frontend" `
        -TestCommand "npm run test" `
        -Environment $testEnv
}

function Test-Backend {
    $testEnv = @{
        "ENV" = "test"
        "DB_HOST" = "localhost"
        "DB_PORT" = "5432"
    }
    
    # Create test network if it doesn't exist
    docker network create test-network 2>$null
    
    # Start test database
    $dbContainer = "test-db-$(Get-Random)"
    docker run --rm -d --name $dbContainer `
        --network test-network `
        -e POSTGRES_DB=test `
        -e POSTGRES_USER=test `
        -e POSTGRES_PASSWORD=test `
        postgres:13
    
    try {
        Test-DockerImage -Name "backend" `
            -TestCommand "python -m pytest" `
            -Environment $testEnv `
            -Networks @("test-network")
    }
    finally {
        docker rm -f $dbContainer 2>$null
        docker network rm test-network 2>$null
    }
}

function Test-API {
    $testEnv = @{
        "ENV" = "test"
        "API_VERSION" = $Version
    }
    
    Test-DockerImage -Name "api" `
        -TestCommand "go test ./..." `
        -Environment $testEnv
}

try {
    # Create test results directory
    $testResultsDir = "$PSScriptRoot\..\..\test-results"
    New-Item -ItemType Directory -Force -Path $testResultsDir | Out-Null
    
    # Run tests
    switch ($Component) {
        'all' {
            Test-Frontend
            Test-Backend
            Test-API
        }
        'frontend' {
            Test-Frontend
        }
        'backend' {
            Test-Backend
        }
        'api' {
            Test-API
        }
    }
    
    Write-Success "Image tests completed successfully!"
}
catch {
    Write-Error "Image tests failed: $_"
    exit 1
}
finally {
    if (-not $KeepContainers) {
        Write-Step "Cleaning up test resources"
        docker container prune -f
        docker network prune -f
    }
}
