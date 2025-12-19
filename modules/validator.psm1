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
    if (test_is_admin) { Write-Host "Running as admin" }
#>
function test_is_admin {
    [CmdletBinding()]
    param()
    
    $CURRENT_PRINCIPAL = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $IS_ADMIN = $CURRENT_PRINCIPAL.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if ($IS_ADMIN) {
        write_log_info "Running with administrator privileges"
    }
    else {
        write_log_warning "NOT running with administrator privileges"
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
    if (-not (test_execution_policy)) { exit 1 }
#>
function test_execution_policy {
    [CmdletBinding()]
    param()
    
    $CURRENT_POLICY = Get-ExecutionPolicy
    
    write_log_info "Current execution policy: $CURRENT_POLICY"
    
    # Acceptable policies: Unrestricted, RemoteSigned, Bypass
    # Not acceptable: Restricted, AllSigned (for automation purposes)
    $ACCEPTABLE_POLICIES = @('Unrestricted', 'RemoteSigned', 'Bypass', 'Undefined')
    
    if ($CURRENT_POLICY -in $ACCEPTABLE_POLICIES) {
        write_log_success "Execution policy is acceptable for script execution"
        return $true
    }
    else {
        write_log_error "Execution policy is too restrictive: $CURRENT_POLICY"
        write_log_info "To fix this, run PowerShell as Administrator and execute:"
        write_log_info "    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser"
        write_log_info "Or for system-wide (requires admin):"
        write_log_info "    Set-ExecutionPolicy RemoteSigned -Scope LocalMachine"
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
    test_windows_version
#>
function test_windows_version {
    [CmdletBinding()]
    param()
    
    # Get Windows version info
    $OS_INFO = Get-CimInstance Win32_OperatingSystem
    $OS_VERSION = $OS_INFO.Version
    $OS_CAPTION = $OS_INFO.Caption
    
    write_log_info "Operating System: $OS_CAPTION (Version: $OS_VERSION)"
    
    # Parse version (format: Major.Minor.Build.Revision)
    $VERSION_PARTS = $OS_VERSION.Split('.')
    $MAJOR_VERSION = [int]$VERSION_PARTS[0]
    $BUILD_NUMBER = [int]$VERSION_PARTS[2]
    
    # Windows 10 = version 10.0.xxxxx
    # Windows 11 = version 10.0.22000+ (build number distinguishes it)
    
    if ($MAJOR_VERSION -ge 10) {
        # Check if build is recent enough (Windows 10 2004 or later)
        if ($BUILD_NUMBER -ge 19041) {
            write_log_success "Windows version is supported"
            return $true
        }
        else {
            write_log_warning "Windows 10 build is too old. Build 19041+ recommended (Windows 10 2004+)"
            return $false
        }
    }
    else {
        write_log_error "Unsupported Windows version. Windows 10 or 11 required."
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
    if (test_command_exists "git") { Write-Host "Git is installed" }
#>
function test_command_exists {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$command_name
    )
    
    # Use Get-Command to check if command exists
    $COMMAND = Get-Command $command_name -ErrorAction SilentlyContinue
    
    if ($COMMAND) {
        write_log_info "Command found: $command_name (Path: $($COMMAND.Source))"
        return $true
    }
    else {
        write_log_info "Command not found: $command_name"
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
    test_winget_available
#>
function test_winget_available {
    [CmdletBinding()]
    param()
    
    write_log_info "Checking for winget (Windows Package Manager)..."
    
    # Try to run winget --version
    try {
        $WINGET_VERSION = & winget --version 2>$null
        
        if ($LASTEXITCODE -eq 0) {
            write_log_success "Winget is available: $WINGET_VERSION"
            return $true
        }
    }
    catch {
        # Command not found
    }
    
    write_log_warning "Winget is not available on this system"
    write_log_info "Winget comes pre-installed on Windows 11 and recent Windows 10 updates"
    write_log_info "Install from: https://aka.ms/getwinget"
    
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
    if (test_wsl_installed) { Write-Host "WSL is ready" }
#>
function test_wsl_installed {
    [CmdletBinding()]
    param()
    
    write_log_info "Checking for WSL (Windows Subsystem for Linux)..."
    
    # Check if wsl command exists
    if (test_command_exists "wsl") {
        # Try to run wsl --status to confirm it's functional
        try {
            $null = & wsl --status 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                write_log_success "WSL is installed and functional"
                return $true
            }
        }
        catch {
            write_log_warning "WSL command found but not functional"
            return $false
        }
    }
    
    write_log_info "WSL is not installed"
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
function invoke_prerequisite_validation {
    [CmdletBinding()]
    param(
        [switch]$require_admin
    )
    
    write_log_info "=========================================="
    write_log_info "Running prerequisite validation checks..."
    write_log_info "=========================================="
    
    $ALL_PASSED = $true
    
    # Check Windows version
    if (-not (test_windows_version)) {
        $ALL_PASSED = $false
    }
    
    # Check execution policy
    if (-not (test_execution_policy)) {
        $ALL_PASSED = $false
    }
    
    # Check admin privileges
    $IS_ADMIN = test_is_admin
    if ($require_admin -and -not $IS_ADMIN) {
        write_log_error "Administrator privileges are required for this operation"
        write_log_info "Please run PowerShell as Administrator and try again"
        $ALL_PASSED = $false
    }
    elseif (-not $IS_ADMIN) {
        write_log_warning "Some installations may require administrator privileges"
        write_log_info "Consider re-running as Administrator if installations fail"
    }
    
    # Check for winget (informational - not critical)
    test_winget_available | Out-Null
    
    write_log_info "=========================================="
    
    if ($ALL_PASSED) {
        write_log_success "All prerequisite validations passed"
    }
    else {
        write_log_error "One or more prerequisite validations failed"
    }
    
    return $ALL_PASSED
}

# Export module functions
Export-ModuleMember -Function @(
    'test_is_admin',
    'test_execution_policy',
    'test_windows_version',
    'test_command_exists',
    'test_winget_available',
    'test_wsl_installed',
    'invoke_prerequisite_validation'
)

