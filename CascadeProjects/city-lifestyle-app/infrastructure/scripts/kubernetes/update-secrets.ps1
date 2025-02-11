# Kubernetes Secrets Management Script

# Import common utilities
. "$PSScriptRoot\..\common\logging.ps1"
. "$PSScriptRoot\..\common\validation.ps1"
. "$PSScriptRoot\..\common\config.ps1"

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('dev', 'staging', 'prod')]
    [string]$Environment,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet('create', 'update', 'delete')]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [string]$SecretName,
    
    [Parameter(Mandatory=$false)]
    [string]$SecretFile,
    
    [Parameter(Mandatory=$false)]
    [hashtable]$SecretData,
    
    [Parameter(Mandatory=$false)]
    [switch]$FromGCP,
    
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

function Import-GCPSecrets {
    param([string]$Name)
    
    Write-Step "Importing secrets from GCP Secret Manager"
    
    # Get secret from GCP
    $secretValue = gcloud secrets versions access latest --secret=$Name
    if (-not $secretValue) {
        throw "Secret $Name not found in GCP Secret Manager"
    }
    
    # Create Kubernetes secret
    $secretData = @{
        value = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($secretValue))
    }
    
    New-KubernetesSecret -Name $Name -Data $secretData
}

function New-KubernetesSecret {
    param(
        [string]$Name,
        [hashtable]$Data
    )
    
    Write-Step "Creating Kubernetes secret: $Name"
    
    # Check if secret exists
    $secretExists = kubectl get secret $Name -n $Environment --no-headers 2>$null
    if ($secretExists -and -not $Force) {
        Write-Warning "Secret $Name already exists. Use -Force to overwrite."
        return
    }
    
    # Create secret manifest
    $secret = @{
        apiVersion = "v1"
        kind = "Secret"
        metadata = @{
            name = $Name
            namespace = $Environment
        }
        type = "Opaque"
        data = $Data
    }
    
    $secretFile = New-TemporaryFile
    $secret | ConvertTo-Json -Depth 10 | Set-Content $secretFile
    
    # Apply secret
    kubectl apply -f $secretFile
    Remove-Item $secretFile
}

function Update-KubernetesSecret {
    param(
        [string]$Name,
        [hashtable]$Data
    )
    
    Write-Step "Updating Kubernetes secret: $Name"
    
    # Check if secret exists
    $secretExists = kubectl get secret $Name -n $Environment --no-headers 2>$null
    if (-not $secretExists) {
        Write-Warning "Secret $Name does not exist. Creating new secret."
        New-KubernetesSecret -Name $Name -Data $Data
        return
    }
    
    # Update secret
    foreach ($key in $Data.Keys) {
        kubectl patch secret $Name -n $Environment -p "{`"data`":{`"$key`":`"$($Data[$key])`"}}"
    }
}

function Remove-KubernetesSecret {
    param([string]$Name)
    
    Write-Step "Removing Kubernetes secret: $Name"
    
    if (-not $Force) {
        $confirm = Read-Host "Are you sure you want to delete secret '$Name'? (y/n)"
        if ($confirm -ne 'y') {
            Write-Warning "Secret deletion cancelled"
            return
        }
    }
    
    kubectl delete secret $Name -n $Environment
}

try {
    # Create namespace if it doesn't exist
    kubectl create namespace $Environment --dry-run=client -o yaml | kubectl apply -f -
    
    if ($FromGCP) {
        if (-not $SecretName) {
            Write-Error "SecretName is required when importing from GCP"
            exit 1
        }
        Import-GCPSecrets -Name $SecretName
    }
    else {
        # Process secret data
        $secretData = @{}
        
        if ($SecretFile) {
            if (-not (Test-Path $SecretFile)) {
                Write-Error "Secret file not found: $SecretFile"
                exit 1
            }
            
            $fileContent = Get-Content $SecretFile -Raw
            try {
                $secretValues = $fileContent | ConvertFrom-Json -AsHashtable
                foreach ($key in $secretValues.Keys) {
                    $secretData[$key] = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($secretValues[$key]))
                }
            }
            catch {
                Write-Error "Invalid secret file format. Expected JSON format."
                exit 1
            }
        }
        elseif ($SecretData) {
            foreach ($key in $SecretData.Keys) {
                $secretData[$key] = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($SecretData[$key]))
            }
        }
        else {
            Write-Error "Either SecretFile or SecretData must be provided"
            exit 1
        }
        
        # Process action
        switch ($Action) {
            'create' { New-KubernetesSecret -Name $SecretName -Data $secretData }
            'update' { Update-KubernetesSecret -Name $SecretName -Data $secretData }
            'delete' { Remove-KubernetesSecret -Name $SecretName }
        }
    }
    
    Write-Success "Secret operation completed successfully!"
}
catch {
    Write-Error "Secret operation failed: $_"
    exit 1
}
