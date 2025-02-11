# Common logging utilities for infrastructure scripts

# Log levels
$script:LogLevels = @{
    DEBUG = 0
    INFO = 1
    WARN = 2
    ERROR = 3
}

# Default log level
$script:CurrentLogLevel = $LogLevels.INFO

# Log colors
$script:LogColors = @{
    DEBUG = 'Gray'
    INFO = 'White'
    WARN = 'Yellow'
    ERROR = 'Red'
}

function Set-LogLevel {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('DEBUG', 'INFO', 'WARN', 'ERROR')]
        [string]$Level
    )
    $script:CurrentLogLevel = $LogLevels[$Level]
}

function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('DEBUG', 'INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO',
        
        [Parameter(Mandatory=$false)]
        [string]$Component = ''
    )
    
    if ($LogLevels[$Level] -ge $script:CurrentLogLevel) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $componentInfo = if ($Component) { "[$Component] " } else { '' }
        $logMessage = "$timestamp $Level $componentInfo$Message"
        
        Write-Host $logMessage -ForegroundColor $LogColors[$Level]
        
        # Also write to log file if specified
        if ($env:LOG_FILE) {
            Add-Content -Path $env:LOG_FILE -Value $logMessage
        }
    }
}

function Write-Step {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [string]$Component = ''
    )
    
    $line = "=" * (4 + $Message.Length)
    Write-Log "" -Level INFO
    Write-Log $line -Level INFO
    Write-Log "  $Message  " -Level INFO -Component $Component
    Write-Log $line -Level INFO
    Write-Log "" -Level INFO
}

function Write-Success {
    param([string]$Message)
    Write-Log $Message -Level INFO -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Log $Message -Level WARN
}

function Write-Error {
    param([string]$Message)
    Write-Log $Message -Level ERROR
}

function Write-Debug {
    param([string]$Message)
    Write-Log $Message -Level DEBUG
}

# Export functions
Export-ModuleMember -Function @(
    'Set-LogLevel',
    'Write-Log',
    'Write-Step',
    'Write-Success',
    'Write-Warning',
    'Write-Error',
    'Write-Debug'
)
