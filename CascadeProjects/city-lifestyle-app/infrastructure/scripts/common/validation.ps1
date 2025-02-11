# Common validation utilities for infrastructure scripts

# Import logging utilities
. "$PSScriptRoot\logging.ps1"

function Test-CommandExists {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Command
    )
    return [bool](Get-Command -Name $Command -ErrorAction SilentlyContinue)
}

function Test-RequiredTools {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Requirements
    )
    
    $missingTools = @()
    foreach ($tool in $Requirements.Keys) {
        if (-not (Test-CommandExists $tool)) {
            $missingTools += "$($Requirements[$tool]) ($tool)"
        }
    }
    
    if ($missingTools.Count -gt 0) {
        Write-Error "Missing required tools: $($missingTools -join ', ')"
        return $false
    }
    
    return $true
}

function Test-Environment {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('dev', 'staging', 'prod')]
        [string]$Environment
    )
    
    $envPath = "$PSScriptRoot\..\..\environments\$Environment"
    if (-not (Test-Path $envPath)) {
        Write-Error "Environment '$Environment' does not exist at path: $envPath"
        return $false
    }
    
    return $true
}

function Test-ProjectStructure {
    param(
        [Parameter(Mandatory=$false)]
        [string[]]$RequiredPaths = @(
            'infrastructure',
            'infrastructure\gcp',
            'infrastructure\kubernetes',
            'infrastructure\docker'
        )
    )
    
    $missingPaths = @()
    foreach ($path in $RequiredPaths) {
        if (-not (Test-Path $path)) {
            $missingPaths += $path
        }
    }
    
    if ($missingPaths.Count -gt 0) {
        Write-Error "Missing required project paths: $($missingPaths -join ', ')"
        return $false
    }
    
    return $true
}

function Test-GCPConfiguration {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProjectId,
        
        [Parameter(Mandatory=$false)]
        [switch]$RequireBilling
    )
    
    # Check if logged in
    $auth = gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>$null
    if (-not $auth) {
        Write-Error "Not logged in to GCP. Please run 'gcloud auth login' first."
        return $false
    }
    
    # Check project exists
    $project = gcloud projects list --filter="project_id:$ProjectId" --format="value(project_id)" 2>$null
    if (-not $project) {
        Write-Error "Project '$ProjectId' does not exist or you don't have access to it."
        return $false
    }
    
    # Check billing if required
    if ($RequireBilling) {
        $billing = gcloud beta billing projects describe $ProjectId --format="value(billingEnabled)" 2>$null
        if ($billing -ne 'true') {
            Write-Error "Project '$ProjectId' does not have billing enabled."
            return $false
        }
    }
    
    return $true
}

function Test-KubernetesConfiguration {
    param(
        [Parameter(Mandatory=$false)]
        [string]$Context,
        
        [Parameter(Mandatory=$false)]
        [string]$Namespace
    )
    
    # Check kubectl
    if (-not (Test-CommandExists 'kubectl')) {
        Write-Error "kubectl is not installed"
        return $false
    }
    
    # Check context if specified
    if ($Context) {
        $currentContext = kubectl config current-context 2>$null
        if ($currentContext -ne $Context) {
            Write-Error "Current Kubernetes context is '$currentContext', expected '$Context'"
            return $false
        }
    }
    
    # Check namespace if specified
    if ($Namespace) {
        $namespaceExists = kubectl get namespace $Namespace --no-headers --output=name 2>$null
        if (-not $namespaceExists) {
            Write-Error "Namespace '$Namespace' does not exist"
            return $false
        }
    }
    
    return $true
}

function Test-DockerConfiguration {
    param(
        [Parameter(Mandatory=$false)]
        [switch]$RequireCompose
    )
    
    # Check Docker daemon
    $docker = docker info 2>$null
    if (-not $docker) {
        Write-Error "Docker daemon is not running"
        return $false
    }
    
    # Check Docker Compose if required
    if ($RequireCompose) {
        if (-not (Test-CommandExists 'docker-compose')) {
            Write-Error "Docker Compose is not installed"
            return $false
        }
    }
    
    return $true
}

# Export functions
Export-ModuleMember -Function @(
    'Test-CommandExists',
    'Test-RequiredTools',
    'Test-Environment',
    'Test-ProjectStructure',
    'Test-GCPConfiguration',
    'Test-KubernetesConfiguration',
    'Test-DockerConfiguration'
)
