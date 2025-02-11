# GCP Backup Management Script

# Import common utilities
. "$PSScriptRoot\..\common\logging.ps1"
. "$PSScriptRoot\..\common\validation.ps1"
. "$PSScriptRoot\..\common\config.ps1"

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('dev', 'staging', 'prod')]
    [string]$Environment,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet('create', 'restore', 'list', 'delete')]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('all', 'sql', 'storage', 'firestore')]
    [string]$Service = 'all',
    
    [Parameter(Mandatory=$false)]
    [string]$BackupId,
    
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

function Backup-CloudSQL {
    Write-Step "Backing up Cloud SQL instances"
    
    # Get all Cloud SQL instances
    $instances = gcloud sql instances list --format="value(name)"
    
    foreach ($instance in $instances) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $backupId = "backup-$instance-$timestamp"
        
        Write-Log "Creating backup for instance: $instance"
        gcloud sql backups create --instance=$instance --description="Automated backup $timestamp"
    }
}

function Backup-CloudStorage {
    Write-Step "Backing up Cloud Storage buckets"
    
    # Get all buckets
    $buckets = gsutil ls
    
    foreach ($bucket in $buckets) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $backupBucket = "$bucket-backup-$timestamp"
        
        Write-Log "Creating backup for bucket: $bucket"
        gsutil -m cp -r $bucket $backupBucket
    }
}

function Backup-Firestore {
    Write-Step "Backing up Firestore"
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupPath = "gs://$($config.Project.Name)-backups/firestore/$timestamp"
    
    Write-Log "Creating Firestore backup"
    gcloud firestore export $backupPath
}

function Restore-CloudSQL {
    param([string]$BackupId)
    
    Write-Step "Restoring Cloud SQL from backup: $BackupId"
    
    if (-not $BackupId) {
        Write-Error "BackupId is required for SQL restore"
        return
    }
    
    # Parse instance name from backup ID
    $instance = $BackupId -replace 'backup-(.+)-\d{8}-\d{6}','$1'
    
    Write-Log "Restoring instance: $instance"
    gcloud sql backups restore $BackupId --instance=$instance
}

function Restore-CloudStorage {
    param([string]$BackupId)
    
    Write-Step "Restoring Cloud Storage from backup: $BackupId"
    
    if (-not $BackupId) {
        Write-Error "BackupId is required for Storage restore"
        return
    }
    
    # Get source and destination buckets
    $sourceBucket = "gs://$BackupId"
    $destBucket = $sourceBucket -replace '-backup-\d{8}-\d{6}',''
    
    Write-Log "Restoring bucket: $destBucket"
    gsutil -m rsync -d -r $sourceBucket $destBucket
}

function Restore-Firestore {
    param([string]$BackupId)
    
    Write-Step "Restoring Firestore from backup: $BackupId"
    
    if (-not $BackupId) {
        Write-Error "BackupId is required for Firestore restore"
        return
    }
    
    Write-Log "Restoring Firestore"
    gcloud firestore import $BackupId
}

function List-Backups {
    Write-Step "Listing available backups"
    
    if ($Service -eq 'all' -or $Service -eq 'sql') {
        Write-Log "Cloud SQL Backups:" -Level INFO
        gcloud sql backups list --format="table(id,instance,created,status)"
    }
    
    if ($Service -eq 'all' -or $Service -eq 'storage') {
        Write-Log "Cloud Storage Backups:" -Level INFO
        gsutil ls -r "gs://*-backup-*"
    }
    
    if ($Service -eq 'all' -or $Service -eq 'firestore') {
        Write-Log "Firestore Backups:" -Level INFO
        gsutil ls -r "gs://$($config.Project.Name)-backups/firestore/*"
    }
}

function Remove-Backups {
    param([string]$BackupId)
    
    Write-Step "Removing backup: $BackupId"
    
    if (-not $BackupId) {
        Write-Error "BackupId is required for backup removal"
        return
    }
    
    if ($Service -eq 'all' -or $Service -eq 'sql') {
        Write-Log "Removing SQL backup"
        gcloud sql backups delete $BackupId --quiet
    }
    
    if ($Service -eq 'all' -or $Service -eq 'storage') {
        Write-Log "Removing Storage backup"
        gsutil -m rm -r "gs://$BackupId"
    }
    
    if ($Service -eq 'all' -or $Service -eq 'firestore') {
        Write-Log "Removing Firestore backup"
        gsutil -m rm -r $BackupId
    }
}

try {
    switch ($Action) {
        'create' {
            if ($Service -eq 'all' -or $Service -eq 'sql') { Backup-CloudSQL }
            if ($Service -eq 'all' -or $Service -eq 'storage') { Backup-CloudStorage }
            if ($Service -eq 'all' -or $Service -eq 'firestore') { Backup-Firestore }
        }
        'restore' {
            if (-not $BackupId) {
                Write-Error "BackupId is required for restore operation"
                exit 1
            }
            if ($Service -eq 'all' -or $Service -eq 'sql') { Restore-CloudSQL -BackupId $BackupId }
            if ($Service -eq 'all' -or $Service -eq 'storage') { Restore-CloudStorage -BackupId $BackupId }
            if ($Service -eq 'all' -or $Service -eq 'firestore') { Restore-Firestore -BackupId $BackupId }
        }
        'list' { List-Backups }
        'delete' {
            if (-not $BackupId) {
                Write-Error "BackupId is required for delete operation"
                exit 1
            }
            Remove-Backups -BackupId $BackupId
        }
    }
    
    Write-Success "Backup operation completed successfully!"
}
catch {
    Write-Error "Backup operation failed: $_"
    exit 1
}
