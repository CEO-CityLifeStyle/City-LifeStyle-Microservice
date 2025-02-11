# GCP Monitoring Setup Script

# Import common utilities
. "$PSScriptRoot\..\common\logging.ps1"
. "$PSScriptRoot\..\common\validation.ps1"
. "$PSScriptRoot\..\common\config.ps1"

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('dev', 'staging', 'prod')]
    [string]$Environment,
    
    [Parameter(Mandatory=$false)]
    [string]$NotificationEmail,
    
    [Parameter(Mandatory=$false)]
    [string]$SlackWebhook,
    
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

function New-MonitoringChannel {
    param(
        [string]$Name,
        [string]$Type,
        [hashtable]$Labels
    )
    
    Write-Step "Creating notification channel: $Name ($Type)"
    
    $channelConfig = @{
        displayName = $Name
        type = $Type
        labels = $Labels
    }
    
    $channelJson = $channelConfig | ConvertTo-Json -Depth 10
    $channelFile = New-TemporaryFile
    $channelJson | Set-Content $channelFile
    
    gcloud beta monitoring channels create --channel-content-from-file=$channelFile
    Remove-Item $channelFile
}

function New-AlertPolicy {
    param(
        [string]$Name,
        [string]$Description,
        [string]$Filter,
        [string]$Threshold,
        [string]$Duration,
        [string]$Alignment,
        [string[]]$NotificationChannels
    )
    
    Write-Step "Creating alert policy: $Name"
    
    $policyConfig = @{
        displayName = $Name
        documentation = @{
            content = $Description
            mimeType = "text/markdown"
        }
        conditions = @(
            @{
                displayName = $Name
                conditionThreshold = @{
                    filter = $Filter
                    duration = $Duration
                    comparison = "COMPARISON_GT"
                    thresholdValue = $Threshold
                    aggregations = @(
                        @{
                            alignmentPeriod = $Duration
                            perSeriesAligner = $Alignment
                        }
                    )
                }
            }
        )
        alertStrategy = @{
            autoClose = "3600s"
        }
        notificationChannels = $NotificationChannels
    }
    
    $policyJson = $policyConfig | ConvertTo-Json -Depth 10
    $policyFile = New-TemporaryFile
    $policyJson | Set-Content $policyFile
    
    gcloud beta monitoring policies create --policy-from-file=$policyFile
    Remove-Item $policyFile
}

try {
    # Create notification channels
    $channels = @()
    
    if ($NotificationEmail) {
        $emailChannel = New-MonitoringChannel `
            -Name "Email Alerts" `
            -Type "email" `
            -Labels @{ email_address = $NotificationEmail }
        $channels += $emailChannel
    }
    
    if ($SlackWebhook) {
        $slackChannel = New-MonitoringChannel `
            -Name "Slack Alerts" `
            -Type "slack" `
            -Labels @{ url = $SlackWebhook }
        $channels += $slackChannel
    }
    
    # Create alert policies
    $alerts = @(
        @{
            Name = "High CPU Usage"
            Description = "CPU usage exceeds 80% for 5 minutes"
            Filter = 'metric.type="compute.googleapis.com/instance/cpu/utilization" resource.type="gce_instance"'
            Threshold = "0.8"
            Duration = "300s"
            Alignment = "ALIGN_MEAN"
        }
        @{
            Name = "High Memory Usage"
            Description = "Memory usage exceeds 80% for 5 minutes"
            Filter = 'metric.type="compute.googleapis.com/instance/memory/utilization" resource.type="gce_instance"'
            Threshold = "0.8"
            Duration = "300s"
            Alignment = "ALIGN_MEAN"
        }
        @{
            Name = "High Error Rate"
            Description = "Error rate exceeds 5% for 5 minutes"
            Filter = 'metric.type="run.googleapis.com/request_count" resource.type="cloud_run_revision" metric.labels.response_code_class="5xx"'
            Threshold = "0.05"
            Duration = "300s"
            Alignment = "ALIGN_RATE"
        }
    )
    
    foreach ($alert in $alerts) {
        New-AlertPolicy @alert -NotificationChannels $channels
    }
    
    # Create dashboard
    Write-Step "Creating monitoring dashboard"
    $dashboardPath = "$PSScriptRoot\..\..\gcp\monitoring\dashboards\platform_dashboard.json"
    gcloud monitoring dashboards create --dashboard-json-from-file=$dashboardPath
    
    Write-Success "Monitoring setup completed successfully!"
}
catch {
    Write-Error "Failed to set up monitoring: $_"
    exit 1
}
