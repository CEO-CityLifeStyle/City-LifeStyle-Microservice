# Common configuration utilities for infrastructure scripts

# Import logging utilities
. "$PSScriptRoot\logging.ps1"

# Default configuration
$script:DefaultConfig = @{
    Project = @{
        Name = "city-lifestyle"
        Region = "us-central1"
        TimeZone = "America/Chicago"
    }
    Docker = @{
        Registry = "gcr.io"
        BaseImage = "alpine:3.18"
        BuildArgs = @{
            BUILDKIT_INLINE_CACHE = 1
        }
    }
    Kubernetes = @{
        Version = "1.27"
        NodeCount = 3
        MachineType = "e2-standard-2"
    }
    Monitoring = @{
        RetentionDays = 30
        AlertChannels = @(
            "email:alerts@citylifestyle.app"
            "slack:#alerts"
        )
    }
}

function Initialize-Configuration {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('dev', 'staging', 'prod')]
        [string]$Environment,
        
        [Parameter(Mandatory=$false)]
        [string]$ConfigFile = "$PSScriptRoot\..\..\config\$Environment.json"
    )
    
    # Start with default config
    $config = $script:DefaultConfig.Clone()
    
    # Load environment-specific config if exists
    if (Test-Path $ConfigFile) {
        try {
            $envConfig = Get-Content $ConfigFile | ConvertFrom-Json -AsHashtable
            $config = Merge-Hashtables $config $envConfig
        }
        catch {
            Write-Error "Failed to load configuration from $ConfigFile: $_"
            return $null
        }
    }
    
    # Add environment-specific overrides
    $config.Environment = $Environment
    switch ($Environment) {
        'dev' {
            $config.Project.Name += "-dev"
            $config.Kubernetes.NodeCount = 1
            $config.Kubernetes.MachineType = "e2-standard-2"
        }
        'staging' {
            $config.Project.Name += "-staging"
            $config.Kubernetes.NodeCount = 2
            $config.Kubernetes.MachineType = "e2-standard-2"
        }
        'prod' {
            $config.Project.Name += "-prod"
            $config.Kubernetes.NodeCount = 3
            $config.Kubernetes.MachineType = "e2-standard-4"
        }
    }
    
    return $config
}

function Merge-Hashtables {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Base,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$Override
    )
    
    $result = $Base.Clone()
    
    foreach ($key in $Override.Keys) {
        if ($result.ContainsKey($key) -and $result[$key] -is [hashtable] -and $Override[$key] -is [hashtable]) {
            $result[$key] = Merge-Hashtables $result[$key] $Override[$key]
        }
        else {
            $result[$key] = $Override[$key]
        }
    }
    
    return $result
}

function Get-ProjectConfig {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$false)]
        [string]$Key
    )
    
    if ($Key) {
        return $Config.Project[$Key]
    }
    return $Config.Project
}

function Get-KubernetesConfig {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$false)]
        [string]$Key
    )
    
    if ($Key) {
        return $Config.Kubernetes[$Key]
    }
    return $Config.Kubernetes
}

function Get-DockerConfig {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$false)]
        [string]$Key
    )
    
    if ($Key) {
        return $Config.Docker[$Key]
    }
    return $Config.Docker
}

function Get-MonitoringConfig {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$false)]
        [string]$Key
    )
    
    if ($Key) {
        return $Config.Monitoring[$Key]
    }
    return $Config.Monitoring
}

function Save-Configuration {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    
    try {
        $Config | ConvertTo-Json -Depth 10 | Set-Content $Path
        Write-Success "Configuration saved to $Path"
        return $true
    }
    catch {
        Write-Error "Failed to save configuration to $Path: $_"
        return $false
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Initialize-Configuration',
    'Merge-Hashtables',
    'Get-ProjectConfig',
    'Get-KubernetesConfig',
    'Get-DockerConfig',
    'Get-MonitoringConfig',
    'Save-Configuration'
)
