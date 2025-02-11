# GCP Resource Cleanup Script

# Import common utilities
. "$PSScriptRoot\..\common\logging.ps1"
. "$PSScriptRoot\..\common\validation.ps1"
. "$PSScriptRoot\..\common\config.ps1"

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('dev', 'staging', 'prod')]
    [string]$Environment,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('all', 'compute', 'storage', 'network', 'iam')]
    [string]$ResourceType = 'all',
    
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

# Validate GCP configuration
if (-not (Test-GCPConfiguration -ProjectId $config.Project.Name)) {
    exit 1
}

function Remove-ComputeResources {
    Write-Step "Cleaning up Compute resources"
    
    # Delete Cloud Run services
    $services = gcloud run services list --platform=managed --format="value(name)"
    foreach ($service in $services) {
        Write-Log "Deleting Cloud Run service: $service"
        if (-not $DryRun) {
            gcloud run services delete $service --platform=managed --quiet
        }
    }
    
    # Delete GCE instances
    $instances = gcloud compute instances list --format="value(name,zone)"
    foreach ($instance in $instances) {
        $name, $zone = $instance -split '\s+'
        Write-Log "Deleting GCE instance: $name in $zone"
        if (-not $DryRun) {
            gcloud compute instances delete $name --zone=$zone --quiet
        }
    }
}

function Remove-StorageResources {
    Write-Step "Cleaning up Storage resources"
    
    # Delete Cloud Storage buckets
    $buckets = gsutil ls
    foreach ($bucket in $buckets) {
        Write-Log "Deleting bucket: $bucket"
        if (-not $DryRun) {
            gsutil -m rm -r $bucket
        }
    }
    
    # Delete Cloud SQL instances
    $sqlInstances = gcloud sql instances list --format="value(name)"
    foreach ($instance in $sqlInstances) {
        Write-Log "Deleting Cloud SQL instance: $instance"
        if (-not $DryRun) {
            gcloud sql instances delete $instance --quiet
        }
    }
}

function Remove-NetworkResources {
    Write-Step "Cleaning up Network resources"
    
    # Delete forwarding rules
    $rules = gcloud compute forwarding-rules list --format="value(name,region)"
    foreach ($rule in $rules) {
        $name, $region = $rule -split '\s+'
        Write-Log "Deleting forwarding rule: $name in $region"
        if (-not $DryRun) {
            gcloud compute forwarding-rules delete $name --region=$region --quiet
        }
    }
    
    # Delete firewall rules
    $firewalls = gcloud compute firewall-rules list --format="value(name)"
    foreach ($firewall in $firewalls) {
        Write-Log "Deleting firewall rule: $firewall"
        if (-not $DryRun) {
            gcloud compute firewall-rules delete $firewall --quiet
        }
    }
    
    # Delete VPC networks
    $networks = gcloud compute networks list --format="value(name)"
    foreach ($network in $networks) {
        if ($network -ne "default") {
            Write-Log "Deleting VPC network: $network"
            if (-not $DryRun) {
                gcloud compute networks delete $network --quiet
            }
        }
    }
}

function Remove-IAMResources {
    Write-Step "Cleaning up IAM resources"
    
    # Delete service accounts
    $serviceAccounts = gcloud iam service-accounts list --format="value(email)"
    foreach ($sa in $serviceAccounts) {
        if ($sa -notmatch "^compute-system@|^cloud-build@") {
            Write-Log "Deleting service account: $sa"
            if (-not $DryRun) {
                gcloud iam service-accounts delete $sa --quiet
            }
        }
    }
}

try {
    if (-not $Force) {
        $message = "This will delete resources in the $Environment environment."
        if ($DryRun) {
            $message += " (Dry run mode)"
        }
        $confirm = Read-Host "$message`nAre you sure you want to continue? (y/n)"
        if ($confirm -ne 'y') {
            Write-Warning "Cleanup cancelled"
            exit 0
        }
    }
    
    if ($ResourceType -eq 'all' -or $ResourceType -eq 'compute') { Remove-ComputeResources }
    if ($ResourceType -eq 'all' -or $ResourceType -eq 'storage') { Remove-StorageResources }
    if ($ResourceType -eq 'all' -or $ResourceType -eq 'network') { Remove-NetworkResources }
    if ($ResourceType -eq 'all' -or $ResourceType -eq 'iam') { Remove-IAMResources }
    
    Write-Success "Cleanup completed successfully!"
    if ($DryRun) {
        Write-Host "This was a dry run. No resources were actually deleted."
    }
}
catch {
    Write-Error "Cleanup failed: $_"
    exit 1
}
