# Kubernetes Application Deployment Script

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
    [switch]$WaitForRollout,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force
)

# Initialize configuration
$config = Initialize-Configuration -Environment $Environment
if (-not $config) {
    exit 1
}

# Validate Kubernetes configuration
if (-not (Test-KubernetesConfiguration)) {
    exit 1
}

function Deploy-Application {
    param(
        [string]$Name,
        [string]$Path
    )
    
    Write-Step "Deploying $Name to $Environment"
    
    # Check if deployment exists
    $deploymentExists = kubectl get deployment -n $Environment -l app=$Name --no-headers 2>$null
    if ($deploymentExists -and -not $Force) {
        Write-Warning "Deployment $Name already exists. Use -Force to redeploy."
        return
    }
    
    # Apply Kubernetes manifests
    Write-Log "Applying Kubernetes manifests for $Name"
    kubectl apply -k $Path
    
    if ($WaitForRollout) {
        Write-Log "Waiting for rollout to complete..."
        kubectl rollout status deployment/$Name -n $Environment --timeout=300s
    }
}

function Deploy-Frontend {
    $frontendPath = "$PSScriptRoot\..\..\kubernetes\overlays\$Environment\frontend"
    Deploy-Application -Name "frontend" -Path $frontendPath
}

function Deploy-Backend {
    $backendPath = "$PSScriptRoot\..\..\kubernetes\overlays\$Environment\backend"
    Deploy-Application -Name "backend" -Path $backendPath
}

function Deploy-API {
    $apiPath = "$PSScriptRoot\..\..\kubernetes\overlays\$Environment\api"
    Deploy-Application -Name "api" -Path $apiPath
}

function Wait-ForHealthy {
    param([string]$Component)
    
    Write-Step "Checking health for $Component"
    
    $maxAttempts = 30
    $attempt = 1
    $healthy = $false
    
    while (-not $healthy -and $attempt -le $maxAttempts) {
        $pods = kubectl get pods -n $Environment -l app=$Component -o json | ConvertFrom-Json
        
        $readyCount = 0
        foreach ($pod in $pods.items) {
            $status = $pod.status
            if ($status.phase -eq 'Running' -and $status.containerStatuses.ready -contains $true) {
                $readyCount++
            }
        }
        
        if ($readyCount -eq $pods.items.Count) {
            $healthy = $true
        }
        else {
            Write-Log "Waiting for $Component pods to be ready ($readyCount/$($pods.items.Count))..."
            Start-Sleep -Seconds 10
            $attempt++
        }
    }
    
    if (-not $healthy) {
        throw "Timeout waiting for $Component to be healthy"
    }
}

try {
    # Set the namespace
    kubectl config set-context --current --namespace=$Environment
    
    # Deploy components
    switch ($Component) {
        'all' {
            Deploy-Frontend
            Deploy-Backend
            Deploy-API
            
            if ($WaitForRollout) {
                Wait-ForHealthy -Component "frontend"
                Wait-ForHealthy -Component "backend"
                Wait-ForHealthy -Component "api"
            }
        }
        'frontend' {
            Deploy-Frontend
            if ($WaitForRollout) { Wait-ForHealthy -Component "frontend" }
        }
        'backend' {
            Deploy-Backend
            if ($WaitForRollout) { Wait-ForHealthy -Component "backend" }
        }
        'api' {
            Deploy-API
            if ($WaitForRollout) { Wait-ForHealthy -Component "api" }
        }
    }
    
    Write-Success "Deployment completed successfully!"
    
    # Display service URLs
    Write-Host "`nService URLs:"
    $services = kubectl get services -n $Environment -o json | ConvertFrom-Json
    foreach ($service in $services.items) {
        $name = $service.metadata.name
        $type = $service.spec.type
        
        if ($type -eq 'LoadBalancer') {
            $ip = $service.status.loadBalancer.ingress.ip
            if ($ip) {
                Write-Host "$name: http://$ip"
            }
        }
        elseif ($type -eq 'ClusterIP') {
            Write-Host "$name: kubectl port-forward svc/$name -n $Environment 8080:80"
        }
    }
}
catch {
    Write-Error "Deployment failed: $_"
    exit 1
}
