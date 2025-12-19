<#
.SYNOPSIS
    Package manager abstraction module for win-dev-setup tool.
    Handles installation via winget, chocolatey, PowerShell Gallery, VS Code, and apt.

.DESCRIPTION
    This module provides a unified interface for installing packages across
    different package managers. It handles:
    - winget (Windows Package Manager)
    - Chocolatey
    - PowerShell Gallery
    - VS Code extensions
    - apt (for WSL/Ubuntu)
    
    The module includes automatic fallback from winget to chocolatey when needed.
    
.NOTES
    Author: win-dev-setup
    Date: 2025-12-19
#>

# Import required modules
Import-Module (Join-Path $PSScriptRoot "logger.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "validator.psm1") -Force

<#
.SYNOPSIS
    Ensures Chocolatey package manager is installed.

.DESCRIPTION
    Checks if Chocolatey is available and installs it if missing.
    Installation requires administrator privileges.

.RETURNS
    $true if chocolatey is available after check/install, $false otherwise.

.EXAMPLE
    ensure_chocolatey_installed
#>
function ensure_chocolatey_installed {
    [CmdletBinding()]
    param()
    
    # Check if choco command exists
    if (test_command_exists "choco") {
        write_log_success "Chocolatey is already installed"
        return $true
    }
    
    write_log_info "Chocolatey not found. Installing..."
    
    # Check if running as admin (required for chocolatey install)
    if (-not (test_is_admin)) {
        write_log_error "Administrator privileges required to install Chocolatey"
        return $false
    }
    
    try {
        # Download and run chocolatey install script
        write_log_info "Downloading Chocolatey installation script..."
        
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        
        # Refresh environment to pick up choco command
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        
        # Verify installation
        if (test_command_exists "choco") {
            write_log_success "Chocolatey installed successfully"
            return $true
        }
        else {
            write_log_error "Chocolatey installation completed but command not found"
            return $false
        }
    }
    catch {
        write_log_error "Failed to install Chocolatey: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Installs a package using winget.

.DESCRIPTION
    Uses Windows Package Manager (winget) to install a package.
    Handles version specification and installation options.

.PARAMETER package_name
    Name/ID of the package to install.

.PARAMETER version
    Version to install. Use "latest" or $null for latest version.

.PARAMETER force
    If specified, forces reinstallation even if already installed.

.PARAMETER whatif
    If specified, shows what would be done without actually installing.

.RETURNS
    $true if installation successful, $false otherwise.

.EXAMPLE
    install_package_winget -package_name "Git.Git" -version "latest"
#>
function install_package_winget {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$package_name,
        
        [Parameter(Mandatory = $false)]
        [string]$version = "latest",
        
        [switch]$force,
        [switch]$whatif
    )
    
    # Build winget command arguments
    $WINGET_ARGS = @("install", "--id", $package_name, "--silent", "--accept-source-agreements", "--accept-package-agreements")
    
    # Add version if specified and not "latest"
    if ($version -and $version -ne "latest") {
        $WINGET_ARGS += @("--version", $version)
    }
    
    # Add force flag if specified
    if ($force) {
        $WINGET_ARGS += "--force"
    }
    
    # WhatIf mode - just show the command
    if ($whatif) {
        write_log_info "[WHATIF] Would execute: winget $($WINGET_ARGS -join ' ')"
        return $true
    }
    
    write_log_package -package_name $package_name -version $version -status "Installing" -package_manager "winget"
    
    try {
        # Execute winget install
        $OUTPUT = & winget @WINGET_ARGS 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            write_log_package -package_name $package_name -version $version -status "Success" -package_manager "winget"
            return $true
        }
        else {
            # Check if already installed
            if ($OUTPUT -match "already installed|No applicable update found") {
                write_log_package -package_name $package_name -version $version -status "Already Installed" -package_manager "winget"
                return $true
            }
            
            write_log_error "Winget installation failed: $OUTPUT"
            return $false
        }
    }
    catch {
        write_log_error "Exception during winget installation: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Installs a package using Chocolatey.

.DESCRIPTION
    Uses Chocolatey package manager to install a package.
    Ensures Chocolatey is installed before attempting package install.

.PARAMETER package_name
    Name of the package to install.

.PARAMETER version
    Version to install. Use "latest" or $null for latest version.

.PARAMETER force
    If specified, forces reinstallation.

.PARAMETER whatif
    If specified, shows what would be done without actually installing.

.RETURNS
    $true if installation successful, $false otherwise.

.EXAMPLE
    install_package_choco -package_name "git" -version "latest"
#>
function install_package_choco {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$package_name,
        
        [Parameter(Mandatory = $false)]
        [string]$version = "latest",
        
        [switch]$force,
        [switch]$whatif
    )
    
    # Ensure chocolatey is installed
    if (-not (ensure_chocolatey_installed)) {
        write_log_error "Cannot install package '$package_name' - Chocolatey not available"
        return $false
    }
    
    # Build choco command arguments
    $CHOCO_ARGS = @("install", $package_name, "-y")
    
    # Add version if specified and not "latest"
    if ($version -and $version -ne "latest") {
        $CHOCO_ARGS += @("--version", $version)
    }
    
    # Add force flag if specified
    if ($force) {
        $CHOCO_ARGS += "--force"
    }
    
    # WhatIf mode
    if ($whatif) {
        write_log_info "[WHATIF] Would execute: choco $($CHOCO_ARGS -join ' ')"
        return $true
    }
    
    write_log_package -package_name $package_name -version $version -status "Installing" -package_manager "choco"
    
    try {
        # Execute chocolatey install
        $OUTPUT = & choco @CHOCO_ARGS 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            write_log_package -package_name $package_name -version $version -status "Success" -package_manager "choco"
            return $true
        }
        else {
            write_log_error "Chocolatey installation failed: $OUTPUT"
            return $false
        }
    }
    catch {
        write_log_error "Exception during chocolatey installation: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Installs a PowerShell module from PowerShell Gallery.

.DESCRIPTION
    Installs a module using Install-Module cmdlet.
    Installs to CurrentUser scope by default.

.PARAMETER package_name
    Name of the PowerShell module to install.

.PARAMETER version
    Version to install. Use "latest" or $null for latest version.

.PARAMETER force
    If specified, forces reinstallation.

.PARAMETER whatif
    If specified, shows what would be done without actually installing.

.RETURNS
    $true if installation successful, $false otherwise.

.EXAMPLE
    install_package_pwsh -package_name "Az" -version "latest"
#>
function install_package_pwsh {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$package_name,
        
        [Parameter(Mandatory = $false)]
        [string]$version = "latest",
        
        [switch]$force,
        [switch]$whatif
    )
    
    # WhatIf mode
    if ($whatif) {
        write_log_info "[WHATIF] Would install PowerShell module: $package_name (Version: $version)"
        return $true
    }
    
    write_log_package -package_name $package_name -version $version -status "Installing" -package_manager "pwsh"
    
    try {
        # Check if module already exists
        $EXISTING_MODULE = Get-Module -ListAvailable -Name $package_name | Select-Object -First 1
        
        if ($EXISTING_MODULE -and -not $force) {
            write_log_package -package_name $package_name -version $EXISTING_MODULE.Version -status "Already Installed" -package_manager "pwsh"
            return $true
        }
        
        # Build install parameters
        $INSTALL_PARAMS = @{
            Name  = $package_name
            Scope = "CurrentUser"
            Force = $force
        }
        
        # Add version if specified and not "latest"
        if ($version -and $version -ne "latest") {
            $INSTALL_PARAMS.RequiredVersion = $version
        }
        
        # Install module
        Install-Module @INSTALL_PARAMS -ErrorAction Stop
        
        write_log_package -package_name $package_name -version $version -status "Success" -package_manager "pwsh"
        return $true
    }
    catch {
        write_log_error "Failed to install PowerShell module '$package_name': $_"
        return $false
    }
}

<#
.SYNOPSIS
    Installs a VS Code extension.

.DESCRIPTION
    Uses VS Code CLI (code command) to install an extension.
    Requires VS Code to be installed first.

.PARAMETER package_name
    Extension ID (e.g., "ms-python.python").

.PARAMETER version
    Version parameter is ignored for VS Code extensions (always installs latest).

.PARAMETER force
    If specified, forces reinstallation.

.PARAMETER whatif
    If specified, shows what would be done without actually installing.

.RETURNS
    $true if installation successful, $false otherwise.

.EXAMPLE
    install_package_vscode -package_name "ms-python.python"
#>
function install_package_vscode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$package_name,
        
        [Parameter(Mandatory = $false)]
        [string]$version = "latest",
        
        [switch]$force,
        [switch]$whatif
    )
    
    # Check if 'code' command is available
    if (-not (test_command_exists "code")) {
        write_log_error "VS Code CLI not found. Install VS Code first."
        return $false
    }
    
    # WhatIf mode
    if ($whatif) {
        write_log_info "[WHATIF] Would install VS Code extension: $package_name"
        return $true
    }
    
    write_log_package -package_name $package_name -version "latest" -status "Installing" -package_manager "vscode"
    
    try {
        # Build command arguments
        $CODE_ARGS = @("--install-extension", $package_name)
        
        if ($force) {
            $CODE_ARGS += "--force"
        }
        
        # Execute code command
        $OUTPUT = & code @CODE_ARGS 2>&1
        
        if ($LASTEXITCODE -eq 0 -or $OUTPUT -match "already installed") {
            write_log_package -package_name $package_name -version "latest" -status "Success" -package_manager "vscode"
            return $true
        }
        else {
            write_log_error "VS Code extension installation failed: $OUTPUT"
            return $false
        }
    }
    catch {
        write_log_error "Exception during VS Code extension installation: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Installs a package using the appropriate package manager.

.DESCRIPTION
    Main entry point for package installation. Routes to the correct
    package manager based on the pkgmgr parameter.
    
    Implements automatic fallback from winget to chocolatey for Windows packages.

.PARAMETER package
    Package configuration object with name, version, pkgmgr fields.

.PARAMETER force
    If specified, forces reinstallation.

.PARAMETER whatif
    If specified, shows what would be done without actually installing.

.PARAMETER latest_everything
    If specified, overrides version and installs latest version.

.RETURNS
    $true if installation successful, $false otherwise.

.EXAMPLE
    $pkg = @{ name = "git"; version = "2.43.0"; pkgmgr = "winget" }
    install_package -package $pkg
#>
function install_package {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$package,
        
        [switch]$force,
        [switch]$whatif,
        [switch]$latest_everything
    )
    
    # Determine version to install
    $VERSION_TO_INSTALL = if ($latest_everything) {
        "latest"
    }
    elseif ($package.version) {
        $package.version
    }
    else {
        "latest"
    }
    
    # Route to appropriate package manager
    switch ($package.pkgmgr) {
        "winget" {
            # Try winget first
            $SUCCESS = install_package_winget -package_name $package.name -version $VERSION_TO_INSTALL -force:$force -whatif:$whatif
            
            # If winget fails and we're not in whatif mode, try chocolatey as fallback
            if (-not $SUCCESS -and -not $whatif) {
                write_log_warning "Winget installation failed for '$($package.name)', trying Chocolatey as fallback..."
                $SUCCESS = install_package_choco -package_name $package.name -version $VERSION_TO_INSTALL -force:$force -whatif:$whatif
            }
            
            return $SUCCESS
        }
        
        "choco" {
            return install_package_choco -package_name $package.name -version $VERSION_TO_INSTALL -force:$force -whatif:$whatif
        }
        
        "pwsh" {
            return install_package_pwsh -package_name $package.name -version $VERSION_TO_INSTALL -force:$force -whatif:$whatif
        }
        
        "vscode" {
            return install_package_vscode -package_name $package.name -version $VERSION_TO_INSTALL -force:$force -whatif:$whatif
        }
        
        "apt" {
            write_log_warning "APT package manager (for WSL/Ubuntu) should be run inside WSL environment"
            write_log_info "Please log into WSL and run install.ps1 from there"
            return $false
        }
        
        default {
            write_log_error "Unknown package manager: $($package.pkgmgr)"
            return $false
        }
    }
}

<#
.SYNOPSIS
    Installs multiple packages from a configuration.

.DESCRIPTION
    Processes a list of packages and installs each one.
    Continues even if individual packages fail.
    
    Returns a summary of successes and failures.

.PARAMETER packages
    Array of package configuration objects.

.PARAMETER force
    If specified, forces reinstallation of all packages.

.PARAMETER whatif
    If specified, shows what would be done without actually installing.

.PARAMETER latest_everything
    If specified, installs latest version of all packages.

.RETURNS
    Hashtable with success_count and failure_count.

.EXAMPLE
    $result = install_packages -packages $package_list
    Write-Host "Installed: $($result.success_count), Failed: $($result.failure_count)"
#>
function install_packages {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$packages,
        
        [switch]$force,
        [switch]$whatif,
        [switch]$latest_everything
    )
    
    $SUCCESS_COUNT = 0
    $FAILURE_COUNT = 0
    $TOTAL_COUNT = $packages.Count
    
    write_log_info "=========================================="
    write_log_info "Starting package installation..."
    write_log_info "Total packages to process: $TOTAL_COUNT"
    write_log_info "=========================================="
    
    $CURRENT = 0
    
    foreach ($PACKAGE in $packages) {
        $CURRENT++
        
        write_log_info "[$CURRENT/$TOTAL_COUNT] Processing package: $($PACKAGE.name)"
        
        # Install the package
        $RESULT = install_package -package $PACKAGE -force:$force -whatif:$whatif -latest_everything:$latest_everything
        
        if ($RESULT) {
            $SUCCESS_COUNT++
        }
        else {
            $FAILURE_COUNT++
        }
        
        write_log_info "---"
    }
    
    write_log_info "=========================================="
    write_log_success "Package installation complete!"
    write_log_info "Successful: $SUCCESS_COUNT"
    
    if ($FAILURE_COUNT -gt 0) {
        write_log_warning "Failed: $FAILURE_COUNT"
    }
    else {
        write_log_info "Failed: $FAILURE_COUNT"
    }
    
    write_log_info "=========================================="
    
    return @{
        success_count = $SUCCESS_COUNT
        failure_count = $FAILURE_COUNT
        total_count   = $TOTAL_COUNT
    }
}

# Export module functions
Export-ModuleMember -Function @(
    'ensure_chocolatey_installed',
    'install_package_winget',
    'install_package_choco',
    'install_package_pwsh',
    'install_package_vscode',
    'install_package',
    'install_packages'
)

