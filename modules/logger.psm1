<#
.SYNOPSIS
    Logging module for win-dev-setup tool.
    Provides console output and file logging with color-coded status levels.

.DESCRIPTION
    This module handles all logging operations for the installation process.
    It writes to both console (with color coding) and a timestamped log file.
    
    Log levels:
    - INFO: General information (Cyan)
    - SUCCESS: Successful operations (Green)
    - WARNING: Non-critical issues (Yellow)
    - ERROR: Critical failures (Red)
    
.NOTES
    Author: win-dev-setup
    Date: 2025-12-19
#>

# Module-level variables for log file path and quiet mode
$script:LOG_FILE_PATH = $null
$script:QUIET_MODE = $false

<#
.SYNOPSIS
    Initializes the logging system.

.DESCRIPTION
    Creates a timestamped log file in the temp directory and sets up logging preferences.
    This should be called at the start of any script using this module.

.PARAMETER quiet
    If specified, suppresses console output (file logging continues).

.EXAMPLE
    initialize-logger
    
.EXAMPLE
    initialize-logger -quiet
#>
function initialize-logger {
    [CmdletBinding()]
    param(
        [switch]$quiet
    )
    
    # Set quiet mode flag
    $script:QUIET_MODE = $quiet
    
    # Generate timestamped log filename
    $TIMESTAMP = Get-Date -Format "yyyyMMdd-HHmmss"
    $script:LOG_FILE_PATH = Join-Path $env:TEMP "win-dev-setup-$TIMESTAMP.log"
    
    # Create log file and write header
    $HEADER = @"
================================================================================
Windows Development Environment Setup - Installation Log
Started: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
================================================================================

"@
    
    $HEADER | Out-File -FilePath $script:LOG_FILE_PATH -Encoding UTF8
    
    # Only show message if not in quiet mode
    if (-not $script:QUIET_MODE) {
        Write-Host "Log file initialized: $script:LOG_FILE_PATH" -ForegroundColor Cyan
    }
}

<#
.SYNOPSIS
    Writes an informational message to log and console.

.PARAMETER message
    The message to log.

.EXAMPLE
    write-log-info "Starting installation process..."
#>
function write-log-info {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$message
    )
    
    $TIMESTAMP = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LOG_ENTRY = "[$TIMESTAMP] [INFO] $message"
    
    # Always write to log file
    $LOG_ENTRY | Out-File -FilePath $script:LOG_FILE_PATH -Append -Encoding UTF8
    
    # Write to console unless in quiet mode
    if (-not $script:QUIET_MODE) {
        Write-Host "[INFO] $message" -ForegroundColor Cyan
    }
}

<#
.SYNOPSIS
    Writes a success message to log and console.

.PARAMETER message
    The message to log.

.EXAMPLE
    write-log-success "Package installed successfully: git"
#>
function write-log-success {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$message
    )
    
    $TIMESTAMP = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LOG_ENTRY = "[$TIMESTAMP] [SUCCESS] $message"
    
    # Always write to log file
    $LOG_ENTRY | Out-File -FilePath $script:LOG_FILE_PATH -Append -Encoding UTF8
    
    # Write to console unless in quiet mode
    if (-not $script:QUIET_MODE) {
        Write-Host "[SUCCESS] $message" -ForegroundColor Green
    }
}

<#
.SYNOPSIS
    Writes a warning message to log and console.

.PARAMETER message
    The message to log.

.EXAMPLE
    write-log-warning "Package not found in winget, trying chocolatey..."
#>
function write-log-warning {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$message
    )
    
    $TIMESTAMP = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LOG_ENTRY = "[$TIMESTAMP] [WARNING] $message"
    
    # Always write to log file
    $LOG_ENTRY | Out-File -FilePath $script:LOG_FILE_PATH -Append -Encoding UTF8
    
    # Write to console unless in quiet mode
    if (-not $script:QUIET_MODE) {
        Write-Host "[WARNING] $message" -ForegroundColor Yellow
    }
}

<#
.SYNOPSIS
    Writes an error message to log and console.

.PARAMETER message
    The message to log.

.EXAMPLE
    write-log-error "Failed to install package: dotnet-sdk"
#>
function write-log-error {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$message
    )
    
    $TIMESTAMP = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LOG_ENTRY = "[$TIMESTAMP] [ERROR] $message"
    
    # Always write to log file
    $LOG_ENTRY | Out-File -FilePath $script:LOG_FILE_PATH -Append -Encoding UTF8
    
    # Always write errors to console, even in quiet mode
    Write-Host "[ERROR] $message" -ForegroundColor Red
}

<#
.SYNOPSIS
    Writes a package installation status message.

.DESCRIPTION
    Special formatter for package installation status.
    Shows: Package Name | Version | Status
    
.PARAMETER package_name
    Name of the package being installed.
    
.PARAMETER version
    Version being installed (or "latest").
    
.PARAMETER status
    Status of the installation (Installing, Installed, Failed, Skipped, etc.).
    
.PARAMETER package_manager
    Package manager being used (winget, choco, etc.).

.EXAMPLE
    write-log-package "git" "2.43.0" "Installing" "winget"
#>
function write-log-package {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$package_name,
        
        [Parameter(Mandatory = $true)]
        [string]$version,
        
        [Parameter(Mandatory = $true)]
        [string]$status,
        
        [Parameter(Mandatory = $false)]
        [string]$package_manager = ""
    )
    
    # Format: [Package: git] [Version: 2.43.0] [Status: Installing] [Manager: winget]
    $PM_TEXT = if ($package_manager) { " [Manager: $package_manager]" } else { "" }
    $message = "[Package: $package_name] [Version: $version] [Status: $status]$PM_TEXT"
    
    $TIMESTAMP = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LOG_ENTRY = "[$TIMESTAMP] [PACKAGE] $message"
    
    # Always write to log file
    $LOG_ENTRY | Out-File -FilePath $script:LOG_FILE_PATH -Append -Encoding UTF8
    
    # Write to console unless in quiet mode
    if (-not $script:QUIET_MODE) {
        # Color code based on status
        $COLOR = switch -Regex ($status) {
            "Install" { "Cyan" }
            "Success|Installed|Complete" { "Green" }
            "Skip|Disabled" { "Gray" }
            "Fail|Error" { "Red" }
            "Warning|Already" { "Yellow" }
            default { "White" }
        }
        
        Write-Host $message -ForegroundColor $COLOR
    }
}

<#
.SYNOPSIS
    Gets the current log file path.

.DESCRIPTION
    Returns the path to the current log file for reference.

.EXAMPLE
    $LOG_PATH = get-log-path
#>
function get-log-path {
    return $script:LOG_FILE_PATH
}

# Export module functions
Export-ModuleMember -Function @(
    'initialize-logger',
    'write-log-info',
    'write-log-success',
    'write-log-warning',
    'write-log-error',
    'write-log-package',
    'get-log-path'
)
