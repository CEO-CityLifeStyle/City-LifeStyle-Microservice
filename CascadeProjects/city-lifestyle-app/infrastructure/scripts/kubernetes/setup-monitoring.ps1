# Kubernetes Monitoring Setup Script

# Import common utilities
. "$PSScriptRoot\..\common\logging.ps1"
. "$PSScriptRoot\..\common\validation.ps1"
. "$PSScriptRoot\..\common\config.ps1"

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('dev', 'staging', 'prod')]
    [string]$Environment,
    
    [Parameter(Mandatory=$false)]
    [string]$GrafanaPassword = "admin",
    
    [Parameter(Mandatory=$false)]
    [switch]$EnableLoki,
    
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

function Install-PrometheusStack {
    Write-Step "Installing Prometheus Stack"
    
    # Add Helm repositories
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    
    # Create monitoring namespace
    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
    
    # Install Prometheus Stack
    $values = @{
        grafana = @{
            adminPassword = $GrafanaPassword
            persistence = @{
                enabled = $true
                size = "10Gi"
            }
            dashboardProviders = @{
                dashboardproviders.yaml = @{
                    apiVersion = 1
                    providers = @(
                        @{
                            name = "default"
                            orgId = 1
                            folder = ""
                            type = "file"
                            disableDeletion = $false
                            editable = $true
                            options = @{
                                path = "/var/lib/grafana/dashboards"
                            }
                        }
                    )
                }
            }
        }
        prometheus = @{
            prometheusSpec = @{
                retention = "15d"
                storageSpec = @{
                    volumeClaimTemplate = @{
                        spec = @{
                            accessModes = @("ReadWriteOnce")
                            resources = @{
                                requests = @{
                                    storage = "50Gi"
                                }
                            }
                        }
                    }
                }
            }
        }
        alertmanager = @{
            alertmanagerSpec = @{
                storage = @{
                    volumeClaimTemplate = @{
                        spec = @{
                            accessModes = @("ReadWriteOnce")
                            resources = @{
                                requests = @{
                                    storage = "10Gi"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    $valuesFile = New-TemporaryFile
    $values | ConvertTo-Json -Depth 10 | Set-Content $valuesFile
    
    helm upgrade --install monitoring prometheus-community/kube-prometheus-stack `
        --namespace monitoring `
        --values $valuesFile `
        --wait
    
    Remove-Item $valuesFile
}

function Install-Loki {
    Write-Step "Installing Loki Stack"
    
    # Add Helm repository
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo update
    
    # Install Loki Stack
    helm upgrade --install loki grafana/loki-stack `
        --namespace monitoring `
        --set grafana.enabled=false `
        --set prometheus.enabled=false `
        --set loki.persistence.enabled=true `
        --set loki.persistence.size=50Gi `
        --wait
}

function Install-CustomDashboards {
    Write-Step "Installing custom dashboards"
    
    $dashboardsDir = "$PSScriptRoot\..\..\kubernetes\monitoring\dashboards"
    if (Test-Path $dashboardsDir) {
        Get-ChildItem $dashboardsDir -Filter *.json | ForEach-Object {
            $dashboardName = $_.BaseName
            $dashboardJson = Get-Content $_.FullName -Raw
            
            $configMap = @{
                apiVersion = "v1"
                kind = "ConfigMap"
                metadata = @{
                    name = "dashboard-$dashboardName"
                    namespace = "monitoring"
                    labels = @{
                        grafana_dashboard = "1"
                    }
                }
                data = @{
                    "$($_.Name)" = $dashboardJson
                }
            }
            
            $configMapFile = New-TemporaryFile
            $configMap | ConvertTo-Json -Depth 10 | Set-Content $configMapFile
            
            kubectl apply -f $configMapFile
            Remove-Item $configMapFile
        }
    }
}

function Install-AlertRules {
    Write-Step "Installing alert rules"
    
    $rulesDir = "$PSScriptRoot\..\..\kubernetes\monitoring\rules"
    if (Test-Path $rulesDir) {
        Get-ChildItem $rulesDir -Filter *.yaml | ForEach-Object {
            kubectl apply -f $_.FullName
        }
    }
}

try {
    # Check if monitoring is already installed
    $monitoringExists = kubectl get namespace monitoring --no-headers 2>$null
    if ($monitoringExists -and -not $Force) {
        Write-Warning "Monitoring stack is already installed. Use -Force to reinstall."
        exit 0
    }
    
    # Install components
    Install-PrometheusStack
    
    if ($EnableLoki) {
        Install-Loki
    }
    
    Install-CustomDashboards
    Install-AlertRules
    
    Write-Success "Monitoring setup completed successfully!"
    
    # Display access information
    Write-Host "`nAccess Information:"
    Write-Host "Grafana:"
    Write-Host "  URL: http://localhost:3000 (use 'kubectl port-forward svc/monitoring-grafana 3000:80 -n monitoring')"
    Write-Host "  Username: admin"
    Write-Host "  Password: $GrafanaPassword"
    Write-Host "`nPrometheus:"
    Write-Host "  URL: http://localhost:9090 (use 'kubectl port-forward svc/monitoring-prometheus 9090:9090 -n monitoring')"
    
    if ($EnableLoki) {
        Write-Host "`nLoki:"
        Write-Host "  URL: http://loki.monitoring:3100 (internal)"
    }
}
catch {
    Write-Error "Monitoring setup failed: $_"
    exit 1
}
