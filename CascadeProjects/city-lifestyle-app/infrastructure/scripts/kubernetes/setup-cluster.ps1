# Kubernetes Cluster Setup Script

# Import common utilities
. "$PSScriptRoot\..\common\logging.ps1"
. "$PSScriptRoot\..\common\validation.ps1"
. "$PSScriptRoot\..\common\config.ps1"

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('dev', 'staging', 'prod')]
    [string]$Environment,
    
    [Parameter(Mandatory=$false)]
    [string]$ClusterName,
    
    [Parameter(Mandatory=$false)]
    [switch]$EnableMonitoring,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force
)

# Initialize configuration
$config = Initialize-Configuration -Environment $Environment
if (-not $config) {
    exit 1
}

# Set default cluster name if not provided
if (-not $ClusterName) {
    $ClusterName = "city-lifestyle-$Environment"
}

# Validate GCP configuration
if (-not (Test-GCPConfiguration -ProjectId $config.Project.Name)) {
    exit 1
}

function New-GKECluster {
    Write-Step "Creating GKE cluster: $ClusterName"
    
    $k8sConfig = Get-KubernetesConfig $config
    
    $args = @(
        "container clusters create $ClusterName",
        "--project=$($config.Project.Name)",
        "--region=$($config.Project.Region)",
        "--cluster-version=$($k8sConfig.Version)",
        "--num-nodes=$($k8sConfig.NodeCount)",
        "--machine-type=$($k8sConfig.MachineType)",
        "--network=city-lifestyle-network",
        "--subnetwork=city-lifestyle-subnet",
        "--enable-ip-alias",
        "--enable-autoscaling",
        "--min-nodes=1",
        "--max-nodes=5",
        "--enable-autorepair",
        "--enable-autoupgrade",
        "--enable-network-policy",
        "--enable-master-authorized-networks",
        "--enable-private-nodes",
        "--master-ipv4-cidr=172.16.0.0/28"
    )
    
    if ($EnableMonitoring) {
        $args += "--enable-monitoring"
        $args += "--enable-logging"
    }
    
    $command = "gcloud " + ($args -join " ")
    Invoke-Expression $command
}

function Install-ClusterAddons {
    Write-Step "Installing cluster add-ons"
    
    # Install Nginx Ingress Controller
    Write-Log "Installing Nginx Ingress Controller"
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
    
    # Install Cert-Manager
    Write-Log "Installing Cert-Manager"
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
    
    # Install Prometheus and Grafana if monitoring is enabled
    if ($EnableMonitoring) {
        Write-Log "Installing Prometheus and Grafana"
        
        # Add Helm repo
        helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
        helm repo update
        
        # Install Prometheus Stack
        helm install monitoring prometheus-community/kube-prometheus-stack `
            --namespace monitoring `
            --create-namespace `
            --set grafana.adminPassword="admin" `
            --set prometheus.prometheusSpec.retention="15d"
    }
}

function Set-KubernetesContext {
    Write-Step "Setting up kubectl context"
    
    gcloud container clusters get-credentials $ClusterName `
        --region $config.Project.Region `
        --project $config.Project.Name
    
    # Create namespaces
    $namespaces = @('dev', 'staging', 'prod')
    foreach ($ns in $namespaces) {
        kubectl create namespace $ns --dry-run=client -o yaml | kubectl apply -f -
    }
}

try {
    # Check if cluster already exists
    $clusterExists = gcloud container clusters list --filter="name=$ClusterName" --format="value(name)"
    if ($clusterExists) {
        if ($Force) {
            Write-Warning "Cluster $ClusterName already exists. Deleting..."
            gcloud container clusters delete $ClusterName --quiet
        }
        else {
            Write-Error "Cluster $ClusterName already exists. Use -Force to recreate."
            exit 1
        }
    }
    
    # Create cluster
    New-GKECluster
    
    # Set up kubectl context
    Set-KubernetesContext
    
    # Install add-ons
    Install-ClusterAddons
    
    Write-Success "Cluster setup completed successfully!"
    Write-Host "Cluster name: $ClusterName"
    Write-Host "Project: $($config.Project.Name)"
    Write-Host "Region: $($config.Project.Region)"
    
    if ($EnableMonitoring) {
        Write-Host "`nMonitoring URLs:"
        Write-Host "Grafana: http://localhost:3000 (use 'kubectl port-forward svc/monitoring-grafana 3000:80 -n monitoring')"
        Write-Host "Prometheus: http://localhost:9090 (use 'kubectl port-forward svc/monitoring-prometheus 9090:9090 -n monitoring')"
    }
}
catch {
    Write-Error "Cluster setup failed: $_"
    exit 1
}
