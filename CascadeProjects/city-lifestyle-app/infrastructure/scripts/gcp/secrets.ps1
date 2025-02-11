# GCP Secrets Management Script

# Import common utilities
. "$PSScriptRoot\..\common\logging.ps1"
. "$PSScriptRoot\..\common\validation.ps1"
. "$PSScriptRoot\..\common\config.ps1"

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('dev', 'staging', 'prod')]
    [string]$Environment,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet('create', 'update', 'get', 'list', 'delete')]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [string]$SecretName,
    
    [Parameter(Mandatory=$false)]
    [string]$SecretValue,
    
    [Parameter(Mandatory=$false)]
    [string]$SecretFile,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force
)

# Initialize configuration
$config = Initialize-Configuration -Environment $Environment
if (-not $config) {
    exit 1
}

# Validate GCP configuration
if (-not (Test-GCPConfiguration -ProjectId $config.Project.Name)) {
    exit 1
}

function New-Secret {
    param(
        [string]$Name,
        [string]$Value,
        [string]$File
    )
    
    Write-Step "Creating secret: $Name"
    
    if ($File) {
        if (-not (Test-Path $File)) {
            throw "Secret file not found: $File"
        }
        gcloud secrets create $Name --data-file=$File
    }
    elseif ($Value) {
        $Value | gcloud secrets create $Name --data-file=-
    }
    else {
        throw "Either SecretValue or SecretFile must be provided"
    }
    
    # Set up IAM policy
    $serviceAccounts = @(
        "serviceAccount:cloudbuild@$($config.Project.Name).iam.gserviceaccount.com",
        "serviceAccount:cloudrun@$($config.Project.Name).iam.gserviceaccount.com"
    )
    
    foreach ($sa in $serviceAccounts) {
        gcloud secrets add-iam-policy-binding $Name `
            --member=$sa `
            --role="roles/secretmanager.secretAccessor"
    }
}

function Update-Secret {
    param(
        [string]$Name,
        [string]$Value,
        [string]$File
    )
    
    Write-Step "Updating secret: $Name"
    
    if ($File) {
        if (-not (Test-Path $File)) {
            throw "Secret file not found: $File"
        }
        gcloud secrets versions add $Name --data-file=$File
    }
    elseif ($Value) {
        $Value | gcloud secrets versions add $Name --data-file=-
    }
    else {
        throw "Either SecretValue or SecretFile must be provided"
    }
}

function Get-Secret {
    param([string]$Name)
    
    Write-Step "Getting secret: $Name"
    gcloud secrets versions access latest --secret=$Name
}

function List-Secrets {
    Write-Step "Listing secrets"
    gcloud secrets list --format="table(name,create_time,labels)"
}

function Remove-Secret {
    param([string]$Name)
    
    Write-Step "Removing secret: $Name"
    
    if (-not $Force) {
        $confirm = Read-Host "Are you sure you want to delete secret '$Name'? (y/n)"
        if ($confirm -ne 'y') {
            Write-Warning "Secret deletion cancelled"
            return
        }
    }
    
    gcloud secrets delete $Name --quiet
}

try {
    switch ($Action) {
        'create' {
            if (-not $SecretName) {
                Write-Error "SecretName is required for create operation"
                exit 1
            }
            New-Secret -Name $SecretName -Value $SecretValue -File $SecretFile
        }
        'update' {
            if (-not $SecretName) {
                Write-Error "SecretName is required for update operation"
                exit 1
            }
            Update-Secret -Name $SecretName -Value $SecretValue -File $SecretFile
        }
        'get' {
            if (-not $SecretName) {
                Write-Error "SecretName is required for get operation"
                exit 1
            }
            Get-Secret -Name $SecretName
        }
        'list' { List-Secrets }
        'delete' {
            if (-not $SecretName) {
                Write-Error "SecretName is required for delete operation"
                exit 1
            }
            Remove-Secret -Name $SecretName
        }
    }
    
    Write-Success "Secret operation completed successfully!"
}
catch {
    Write-Error "Secret operation failed: $_"
    exit 1
}
