# Docker Cleanup Script

# Import common utilities
. "$PSScriptRoot\..\common\logging.ps1"
. "$PSScriptRoot\..\common\validation.ps1"
. "$PSScriptRoot\..\common\config.ps1"

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('all', 'containers', 'images', 'volumes', 'networks')]
    [string]$Target = 'all',
    
    [Parameter(Mandatory=$false)]
    [switch]$RemoveUnused,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force
)

# Initialize configuration
$config = Initialize-Configuration -Environment 'dev'
if (-not $config) {
    exit 1
}

# Validate Docker configuration
if (-not (Test-DockerConfiguration)) {
    exit 1
}

function Remove-StoppedContainers {
    Write-Step "Removing stopped containers"
    
    $containers = docker ps -a -q -f status=exited
    if ($containers) {
        docker rm $containers
    }
}

function Remove-DanglingImages {
    Write-Step "Removing dangling images"
    
    $images = docker images -q -f dangling=true
    if ($images) {
        docker rmi $images
    }
}

function Remove-UnusedVolumes {
    Write-Step "Removing unused volumes"
    
    docker volume prune -f
}

function Remove-UnusedNetworks {
    Write-Step "Removing unused networks"
    
    docker network prune -f
}

function Remove-ProjectResources {
    Write-Step "Removing project-specific resources"
    
    # Remove project containers
    Write-Log "Removing project containers"
    $containers = docker ps -a -q -f name=city-lifestyle
    if ($containers) {
        docker rm -f $containers
    }
    
    # Remove project images
    Write-Log "Removing project images"
    $images = docker images "gcr.io/$($config.Project.Name)/*" -q
    if ($images) {
        docker rmi -f $images
    }
    
    # Remove project volumes
    Write-Log "Removing project volumes"
    $volumes = docker volume ls -q -f name=city-lifestyle
    if ($volumes) {
        docker volume rm -f $volumes
    }
    
    # Remove project networks
    Write-Log "Removing project networks"
    $networks = docker network ls -q -f name=city-lifestyle
    if ($networks) {
        docker network rm $networks
    }
}

function Show-ResourceUsage {
    Write-Step "Current Docker resource usage"
    
    Write-Host "`nContainers:"
    docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Size}}"
    
    Write-Host "`nImages:"
    docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}"
    
    Write-Host "`nVolumes:"
    docker volume ls --format "table {{.Name}}\t{{.Driver}}"
    
    Write-Host "`nNetworks:"
    docker network ls --format "table {{.Name}}\t{{.Driver}}"
    
    Write-Host "`nDisk Usage:"
    docker system df
}

try {
    # Show current usage before cleanup
    Show-ResourceUsage
    
    if (-not $Force) {
        $message = "This will remove Docker resources"
        if ($RemoveUnused) {
            $message += " including unused resources"
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
            Remove-StoppedContainers
            Remove-DanglingImages
            Remove-UnusedVolumes
            Remove-UnusedNetworks
            if ($RemoveUnused) {
                Remove-ProjectResources
            }
        }
        'containers' {
            Remove-StoppedContainers
            if ($RemoveUnused) {
                docker container prune -f
            }
        }
        'images' {
            Remove-DanglingImages
            if ($RemoveUnused) {
                docker image prune -a -f
            }
        }
        'volumes' {
            Remove-UnusedVolumes
        }
        'networks' {
            Remove-UnusedNetworks
        }
    }
    
    Write-Success "Cleanup completed successfully!"
    
    # Show usage after cleanup
    Write-Host "`nResource usage after cleanup:"
    Show-ResourceUsage
}
catch {
    Write-Error "Cleanup failed: $_"
    exit 1
}
