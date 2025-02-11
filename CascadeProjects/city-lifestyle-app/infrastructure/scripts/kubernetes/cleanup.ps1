# Kubernetes Cluster Cleanup Script

# Import common utilities
. "$PSScriptRoot\..\common\logging.ps1"
. "$PSScriptRoot\..\common\validation.ps1"
. "$PSScriptRoot\..\common\config.ps1"

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('dev', 'staging', 'prod')]
    [string]$Environment,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('all', 'deployments', 'services', 'configmaps', 'secrets', 'pvcs', 'namespaces')]
    [string]$Target = 'all',
    
    [Parameter(Mandatory=$false)]
    [string]$Namespace,
    
    [Parameter(Mandatory=$false)]
    [string]$Selector,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun,
    
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

function Remove-KubernetesResources {
    param(
        [string]$ResourceType,
        [string]$Namespace,
        [string]$Selector
    )
    
    Write-Step "Removing $ResourceType resources"
    
    $namespaceArg = if ($Namespace) { "-n $Namespace" } else { "--all-namespaces" }
    $selectorArg = if ($Selector) { "-l $Selector" } else { "" }
    $dryRunArg = if ($DryRun) { "--dry-run=client" } else { "" }
    
    # Get resources
    $resources = kubectl get $ResourceType $namespaceArg $selectorArg -o json | ConvertFrom-Json
    
    foreach ($resource in $resources.items) {
        $name = $resource.metadata.name
        $ns = $resource.metadata.namespace
        
        # Skip system namespaces and resources
        if ($ns -in @('kube-system', 'kube-public', 'kube-node-lease')) {
            Write-Log "Skipping system namespace resource: $name in $ns" -Level WARN
            continue
        }
        
        # Skip protected resources
        if ($name -like 'kube-*' -or $name -like 'kubernetes-*') {
            Write-Log "Skipping protected resource: $name" -Level WARN
            continue
        }
        
        Write-Log "Removing $ResourceType: $name in namespace $ns"
        
        if ($DryRun) {
            Write-Host "[DRY RUN] Would delete $ResourceType/$name in $ns"
        }
        else {
            kubectl delete $ResourceType $name -n $ns --wait=false
        }
    }
}

function Remove-PersistentVolumes {
    Write-Step "Removing PersistentVolumes"
    
    $pvs = kubectl get pv -o json | ConvertFrom-Json
    
    foreach ($pv in $pvs.items) {
        $name = $pv.metadata.name
        
        # Skip if PV is still bound and force is not set
        if ($pv.status.phase -eq 'Bound' -and -not $Force) {
            Write-Log "Skipping bound PV: $name" -Level WARN
            continue
        }
        
        Write-Log "Removing PV: $name"
        
        if ($DryRun) {
            Write-Host "[DRY RUN] Would delete PV/$name"
        }
        else {
            kubectl delete pv $name --wait=false
        }
    }
}

function Remove-Namespaces {
    Write-Step "Removing namespaces"
    
    $namespaces = kubectl get namespaces -o json | ConvertFrom-Json
    
    foreach ($ns in $namespaces.items) {
        $name = $ns.metadata.name
        
        # Skip system namespaces
        if ($name -in @('default', 'kube-system', 'kube-public', 'kube-node-lease')) {
            Write-Log "Skipping system namespace: $name" -Level WARN
            continue
        }
        
        Write-Log "Removing namespace: $name"
        
        if ($DryRun) {
            Write-Host "[DRY RUN] Would delete namespace/$name"
        }
        else {
            kubectl delete namespace $name --wait=false
        }
    }
}

function Show-ClusterStatus {
    Write-Step "Cluster Status"
    
    # Show nodes
    Write-Host "`nNodes:"
    kubectl get nodes
    
    # Show namespaces
    Write-Host "`nNamespaces:"
    kubectl get namespaces
    
    # Show workloads
    Write-Host "`nWorkloads:"
    kubectl get pods --all-namespaces
    
    # Show services
    Write-Host "`nServices:"
    kubectl get services --all-namespaces
    
    # Show storage
    Write-Host "`nPersistent Volumes:"
    kubectl get pv
    
    Write-Host "`nPersistent Volume Claims:"
    kubectl get pvc --all-namespaces
}

function Remove-FinalizerWorkaround {
    param(
        [string]$ResourceType,
        [string]$Name,
        [string]$Namespace
    )
    
    Write-Log "Removing finalizers from $ResourceType/$Name"
    
    $resource = kubectl get $ResourceType $Name -n $Namespace -o json | ConvertFrom-Json
    $resource.metadata.finalizers = @()
    
    $tempFile = New-TemporaryFile
    $resource | ConvertTo-Json -Depth 100 | Set-Content $tempFile
    
    kubectl replace -f $tempFile --force
    Remove-Item $tempFile
}

try {
    # Show current status
    Show-ClusterStatus
    
    if (-not $Force -and -not $DryRun) {
        $message = "This will remove Kubernetes resources from the $Environment environment"
        if ($Namespace) {
            $message += " in namespace $Namespace"
        }
        $confirm = Read-Host "$message. Are you sure? (y/n)"
        if ($confirm -ne 'y') {
            Write-Warning "Cleanup cancelled"
            exit 0
        }
    }
    
    # Perform cleanup based on target
    switch ($Target) {
        'all' {
            Remove-KubernetesResources -ResourceType "deployments" -Namespace $Namespace -Selector $Selector
            Remove-KubernetesResources -ResourceType "services" -Namespace $Namespace -Selector $Selector
            Remove-KubernetesResources -ResourceType "configmaps" -Namespace $Namespace -Selector $Selector
            Remove-KubernetesResources -ResourceType "secrets" -Namespace $Namespace -Selector $Selector
            Remove-KubernetesResources -ResourceType "persistentvolumeclaims" -Namespace $Namespace -Selector $Selector
            Remove-PersistentVolumes
            if (-not $Namespace) {
                Remove-Namespaces
            }
        }
        'deployments' {
            Remove-KubernetesResources -ResourceType "deployments" -Namespace $Namespace -Selector $Selector
        }
        'services' {
            Remove-KubernetesResources -ResourceType "services" -Namespace $Namespace -Selector $Selector
        }
        'configmaps' {
            Remove-KubernetesResources -ResourceType "configmaps" -Namespace $Namespace -Selector $Selector
        }
        'secrets' {
            Remove-KubernetesResources -ResourceType "secrets" -Namespace $Namespace -Selector $Selector
        }
        'pvcs' {
            Remove-KubernetesResources -ResourceType "persistentvolumeclaims" -Namespace $Namespace -Selector $Selector
            Remove-PersistentVolumes
        }
        'namespaces' {
            Remove-Namespaces
        }
    }
    
    if ($Force) {
        Write-Step "Checking for stuck resources"
        Start-Sleep -Seconds 10
        
        # Check for stuck resources and remove finalizers if necessary
        $resources = @(
            @{Type="pods"; Plural="pod"},
            @{Type="persistentvolumeclaims"; Plural="pvc"},
            @{Type="namespaces"; Plural="namespace"}
        )
        
        foreach ($resource in $resources) {
            $stuck = kubectl get $resource.Type --all-namespaces -o json | ConvertFrom-Json
            foreach ($item in $stuck.items) {
                if ($item.metadata.deletionTimestamp) {
                    $name = $item.metadata.name
                    $ns = $item.metadata.namespace
                    Write-Warning "Found stuck $($resource.Plural): $name in $ns"
                    Remove-FinalizerWorkaround -ResourceType $resource.Type -Name $name -Namespace $ns
                }
            }
        }
    }
    
    Write-Success "Cleanup completed successfully!"
    
    if ($DryRun) {
        Write-Host "`nThis was a dry run. No resources were actually deleted."
    }
    else {
        # Show final status
        Write-Host "`nFinal cluster status:"
        Show-ClusterStatus
    }
}
catch {
    Write-Error "Cleanup failed: $_"
    exit 1
}
