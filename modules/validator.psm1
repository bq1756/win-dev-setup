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
    if (test-is-admin) { Write-Host "Running as admin" }
#>
function test-is-admin {
    [CmdletBinding()]
    param()
    
    $CURRENT_PRINCIPAL = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $IS_ADMIN = $CURRENT_PRINCIPAL.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if ($IS_ADMIN) {
        write-log-info "Running with administrator privileges"
    }
    else {
        write-log-warning "NOT running with administrator privileges"
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
    if (-not (test-execution-policy)) { exit 1 }
#>
function test-execution-policy {
    [CmdletBinding()]
    param()
    
    $CURRENT_POLICY = Get-ExecutionPolicy
    
    write-log-info "Current execution policy: $CURRENT_POLICY"
    
    # Acceptable policies: Unrestricted, RemoteSigned, Bypass
    # Not acceptable: Restricted, AllSigned (for automation purposes)
    $ACCEPTABLE_POLICIES = @('Unrestricted', 'RemoteSigned', 'Bypass', 'Undefined')
    
    if ($CURRENT_POLICY -in $ACCEPTABLE_POLICIES) {
        write-log-success "Execution policy is acceptable for script execution"
        return $true
    }
    else {
        write-log-error "Execution policy is too restrictive: $CURRENT_POLICY"
        write-log-info "To fix this, run PowerShell as Administrator and execute:"
        write-log-info "    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser"
        write-log-info "Or for system-wide (requires admin):"
        write-log-info "    Set-ExecutionPolicy RemoteSigned -Scope LocalMachine"
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
    test-windows-version
#>
function test-windows-version {
    [CmdletBinding()]
    param()
    
    # Get Windows version info
    $OS_INFO = Get-CimInstance Win32_OperatingSystem
    $OS_VERSION = $OS_INFO.Version
    $OS_CAPTION = $OS_INFO.Caption
    
    write-log-info "Operating System: $OS_CAPTION (Version: $OS_VERSION)"
    
    # Parse version (format: Major.Minor.Build.Revision)
    $VERSION_PARTS = $OS_VERSION.Split('.')
    $MAJOR_VERSION = [int]$VERSION_PARTS[0]
    $BUILD_NUMBER = [int]$VERSION_PARTS[2]
    
    # Windows 10 = version 10.0.xxxxx
    # Windows 11 = version 10.0.22000+ (build number distinguishes it)
    
    if ($MAJOR_VERSION -ge 10) {
        # Check if build is recent enough (Windows 10 2004 or later)
        if ($BUILD_NUMBER -ge 19041) {
            write-log-success "Windows version is supported"
            return $true
        }
        else {
            write-log-warning "Windows 10 build is too old. Build 19041+ recommended (Windows 10 2004+)"
            return $false
        }
    }
    else {
        write-log-error "Unsupported Windows version. Windows 10 or 11 required."
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
    if (test-command-exists "git") { Write-Host "Git is installed" }
#>
function test-command-exists {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$command_name
    )
    
    # Use Get-Command to check if command exists
    $COMMAND = Get-Command $command_name -ErrorAction SilentlyContinue
    
    if ($COMMAND) {
        write-log-info "Command found: $command_name (Path: $($COMMAND.Source))"
        return $true
    }
    else {
        write-log-info "Command not found: $command_name"
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
    test-winget-available
#>
function test-winget-available {
    [CmdletBinding()]
    param()
    
    write-log-info "Checking for winget (Windows Package Manager)..."
    
    # Try to run winget --version
    try {
        $WINGET_VERSION = & winget --version 2>$null
        
        if ($LASTEXITCODE -eq 0) {
            write-log-success "Winget is available: $WINGET_VERSION"
            return $true
        }
    }
    catch {
        # Command not found
    }
    
    write-log-warning "Winget is not available on this system"
    write-log-info "Winget comes pre-installed on Windows 11 and recent Windows 10 updates"
    write-log-info "Install from: https://aka.ms/getwinget"
    
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
    if (test-wsl-installed) { Write-Host "WSL is ready" }
#>
function test-wsl-installed {
    [CmdletBinding()]
    param()
    
    write-log-info "Checking for WSL (Windows Subsystem for Linux)..."
    
    # Check if wsl command exists
    if (test-command-exists "wsl") {
        # Try to run wsl --status to confirm it's functional
        try {
            $null = & wsl --status 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                write-log-success "WSL is installed and functional"
                return $true
            }
        }
        catch {
            write-log-warning "WSL command found but not functional"
            return $false
        }
    }
    
    write-log-info "WSL is not installed"
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
function invoke-prerequisite-validation {
    [CmdletBinding()]
    param(
        [switch]$require_admin
    )
    
    write-log-info "=========================================="
    write-log-info "Running prerequisite validation checks..."
    write-log-info "=========================================="
    
    $ALL_PASSED = $true
    
    # Check Windows version
    if (-not (test-windows-version)) {
        $ALL_PASSED = $false
    }
    
    # Check execution policy
    if (-not (test-execution-policy)) {
        $ALL_PASSED = $false
    }
    
    # Check admin privileges
    $IS_ADMIN = test-is-admin
    if ($require_admin -and -not $IS_ADMIN) {
        write-log-error "Administrator privileges are required for this operation"
        write-log-info "Please run PowerShell as Administrator and try again"
        $ALL_PASSED = $false
    }
    elseif (-not $IS_ADMIN) {
        write-log-warning "Some installations may require administrator privileges"
        write-log-info "Consider re-running as Administrator if installations fail"
    }
    
    # Check for winget (informational - not critical)
    test-winget-available | Out-Null
    
    write-log-info "=========================================="
    
    if ($ALL_PASSED) {
        write-log-success "All prerequisite validations passed"
    }
    else {
        write-log-error "One or more prerequisite validations failed"
    }
    
    return $ALL_PASSED
}

# Export module functions
Export-ModuleMember -Function @(
    'test-is-admin',
    'test-execution-policy',
    'test-windows-version',
    'test-command-exists',
    'test-winget-available',
    'test-wsl-installed',
    'invoke-prerequisite-validation'
)
