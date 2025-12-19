<#
.SYNOPSIS
    Validation module for win-dev-setup tool.
    Checks prerequisites, permissions, and system requirements.

.DESCRIPTION
    This module validates that the system meets requirements for running
    the installation scripts. It checks:
    - PowerShell execution policy
    - Administrator privileges
    - Operating system version
    - Required commands and tools
    
.NOTES
    Author: win-dev-setup
    Date: 2025-12-19
#>

# Import logger module for logging functionality
Import-Module (Join-Path $PSScriptRoot "logger.psm1") -Force

<#
.SYNOPSIS
    Checks if script is running with administrator privileges.

.DESCRIPTION
    Determines if the current PowerShell session has admin rights.
    Many package installations require elevation.

.RETURNS
    $true if running as admin, $false otherwise.

.EXAMPLE
    if (Test-IsAdmin) { Write-Host "Running as admin" }
#>
function Test-IsAdmin {
    [CmdletBinding()]
    param()
    
    $CURRENT_PRINCIPAL = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $IS_ADMIN = $CURRENT_PRINCIPAL.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if ($IS_ADMIN) {
        Write-LogInfo "Running with administrator privileges"
    }
    else {
        Write-LogWarning "NOT running with administrator privileges"
    }
    
    return $IS_ADMIN
}

<#
.SYNOPSIS
    Validates PowerShell execution policy.

.DESCRIPTION
    Checks if execution policy allows running scripts.
    If policy is too restrictive, provides guidance to user.

.RETURNS
    $true if execution policy is acceptable, $false otherwise.

.EXAMPLE
    if (-not (Test-ExecutionPolicy)) { exit 1 }
#>
function Test-ExecutionPolicy {
    [CmdletBinding()]
    param()
    
    $CURRENT_POLICY = Get-ExecutionPolicy
    
    Write-LogInfo "Current execution policy: $CURRENT_POLICY"
    
    # Acceptable policies: Unrestricted, RemoteSigned, Bypass
    # Not acceptable: Restricted, AllSigned (for automation purposes)
    $ACCEPTABLE_POLICIES = @('Unrestricted', 'RemoteSigned', 'Bypass', 'Undefined')
    
    if ($CURRENT_POLICY -in $ACCEPTABLE_POLICIES) {
        Write-LogSuccess "Execution policy is acceptable for script execution"
        return $true
    }
    else {
        Write-LogError "Execution policy is too restrictive: $CURRENT_POLICY"
        Write-LogInfo "To fix this, run PowerShell as Administrator and execute:"
        Write-LogInfo "    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser"
        Write-LogInfo "Or for system-wide (requires admin):"
        Write-LogInfo "    Set-ExecutionPolicy RemoteSigned -Scope LocalMachine"
        return $false
    }
}

<#
.SYNOPSIS
    Validates Windows version.

.DESCRIPTION
    Checks if running on a supported Windows version.
    Windows 10 (build 19041+) or Windows 11 required.

.RETURNS
    $true if Windows version is supported, $false otherwise.

.EXAMPLE
    Test-WindowsVersion
#>
function Test-WindowsVersion {
    [CmdletBinding()]
    param()
    
    # Get Windows version info
    $OS_INFO = Get-CimInstance Win32_OperatingSystem
    $OS_VERSION = $OS_INFO.Version
    $OS_CAPTION = $OS_INFO.Caption
    
    Write-LogInfo "Operating System: $OS_CAPTION (Version: $OS_VERSION)"
    
    # Parse version (format: Major.Minor.Build.Revision)
    $VERSION_PARTS = $OS_VERSION.Split('.')
    $MAJOR_VERSION = [int]$VERSION_PARTS[0]
    $BUILD_NUMBER = [int]$VERSION_PARTS[2]
    
    # Windows 10 = version 10.0.xxxxx
    # Windows 11 = version 10.0.22000+ (build number distinguishes it)
    
    if ($MAJOR_VERSION -ge 10) {
        # Check if build is recent enough (Windows 10 2004 or later)
        if ($BUILD_NUMBER -ge 19041) {
            Write-LogSuccess "Windows version is supported"
            return $true
        }
        else {
            Write-LogWarning "Windows 10 build is too old. Build 19041+ recommended (Windows 10 2004+)"
            return $false
        }
    }
    else {
        Write-LogError "Unsupported Windows version. Windows 10 or 11 required."
        return $false
    }
}

<#
.SYNOPSIS
    Checks if a command/executable is available.

.DESCRIPTION
    Tests if a command is available in the system PATH.
    Useful for checking prerequisites like git, winget, etc.

.PARAMETER command_name
    Name of the command to check.

.RETURNS
    $true if command is available, $false otherwise.

.EXAMPLE
    if (Test-CommandExists "git") { Write-Host "Git is installed" }
#>
function Test-CommandExists {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$command_name
    )
    
    # Use Get-Command to check if command exists
    $COMMAND = Get-Command $command_name -ErrorAction SilentlyContinue
    
    if ($COMMAND) {
        Write-LogInfo "Command found: $command_name (Path: $($COMMAND.Source))"
        return $true
    }
    else {
        Write-LogInfo "Command not found: $command_name"
        return $false
    }
}

<#
.SYNOPSIS
    Validates winget availability.

.DESCRIPTION
    Checks if winget (Windows Package Manager) is installed and accessible.
    Winget comes pre-installed on Windows 11 and recent Windows 10 builds.

.RETURNS
    $true if winget is available, $false otherwise.

.EXAMPLE
    Test-WingetAvailable
#>
function Test-WingetAvailable {
    [CmdletBinding()]
    param()
    
    Write-LogInfo "Checking for winget (Windows Package Manager)..."
    
    # Try to run winget --version
    try {
        $WINGET_VERSION = & winget --version 2>$null
        
        if ($LASTEXITCODE -eq 0) {
            Write-LogSuccess "Winget is available: $WINGET_VERSION"
            return $true
        }
    }
    catch {
        # Command not found
    }
    
    Write-LogWarning "Winget is not available on this system"
    Write-LogInfo "Winget comes pre-installed on Windows 11 and recent Windows 10 updates"
    Write-LogInfo "Install from: https://aka.ms/getwinget"
    
    return $false
}

<#
.SYNOPSIS
    Checks if WSL (Windows Subsystem for Linux) is installed.

.DESCRIPTION
    Determines if WSL is installed and available on the system.

.RETURNS
    $true if WSL is installed, $false otherwise.

.EXAMPLE
    if (Test-WslInstalled) { Write-Host "WSL is ready" }
#>
function Test-WslInstalled {
    [CmdletBinding()]
    param()
    
    Write-LogInfo "Checking for WSL (Windows Subsystem for Linux)..."
    
    # Check if wsl command exists
    if (Test-CommandExists "wsl") {
        # Try to run wsl --status to confirm it's functional
        try {
            $null = & wsl --status 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-LogSuccess "WSL is installed and functional"
                return $true
            }
        }
        catch {
            Write-LogWarning "WSL command found but not functional"
            return $false
        }
    }
    
    Write-LogInfo "WSL is not installed"
    return $false
}

<#
.SYNOPSIS
    Runs all prerequisite validations.

.DESCRIPTION
    Executes all validation checks and reports results.
    This should be called at the start of installation process.

.PARAMETER require_admin
    If specified, fails validation if not running as admin.

.RETURNS
    $true if all critical validations pass, $false otherwise.

.EXAMPLE
    if (-not (invoke-prerequisite-validation -require_admin)) { exit 1 }
#>
function Invoke-PrerequisiteValidation {
    [CmdletBinding()]
    param(
        [switch]$require_admin
    )
    
    Write-LogInfo "=========================================="
    Write-LogInfo "Running prerequisite validation checks..."
    Write-LogInfo "=========================================="
    
    $ALL_PASSED = $true
    
    # Check Windows version
    if (-not (Test-WindowsVersion)) {
        $ALL_PASSED = $false
    }
    
    # Check execution policy
    if (-not (Test-ExecutionPolicy)) {
        $ALL_PASSED = $false
    }
    
    # Check admin privileges
    $IS_ADMIN = Test-IsAdmin
    if ($require_admin -and -not $IS_ADMIN) {
        Write-LogError "Administrator privileges are required for this operation"
        Write-LogInfo "Please run PowerShell as Administrator and try again"
        $ALL_PASSED = $false
    }
    elseif (-not $IS_ADMIN) {
        Write-LogWarning "Some installations may require administrator privileges"
        Write-LogInfo "Consider re-running as Administrator if installations fail"
    }
    
    # Check for winget (informational - not critical)
    Test-WingetAvailable | Out-Null
    
    Write-LogInfo "=========================================="
    
    if ($ALL_PASSED) {
        Write-LogSuccess "All prerequisite validations passed"
    }
    else {
        Write-LogError "One or more prerequisite validations failed"
    }
    
    return $ALL_PASSED
}

# Export all functions
# All functions auto-exported

