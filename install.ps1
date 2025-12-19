<#
.SYNOPSIS
    Main installation script for Windows development environment setup.
    
.DESCRIPTION
    This script automates the installation of development tools and environments
    on Windows systems. It supports multiple development stacks (foundation, java,
    python, dotnet, docker, devops) and uses YAML configuration files.
    
    The script supports multiple package managers:
    - winget (default/preferred)
    - Chocolatey (fallback)
    - PowerShell Gallery
    - VS Code extensions
    
    Features:
    - Modular stack selection via command-line parameters
    - Dry-run mode (-whatif) to preview changes
    - Force reinstall mode (-force_installs)
    - Latest version override (-latest_everything)
    - Comprehensive logging to file and console
    - Quiet mode for minimal output
    
.PARAMETER stacks
    Array of stack names to install. Valid options:
    - foundation: VS Code, Git, and basic development tools
    - java: JDK, Maven, Gradle
    - python: Python, pip, common packages
    - dotnet: .NET SDK and tools
    - docker: WSL, Docker Desktop, container tools
    - devops: Azure CLI, Kubernetes, Terraform, etc.
    
.PARAMETER config_path
    Optional path to a custom YAML configuration file.
    If not specified, uses default configs from configs/defaults/ directory.
    
.PARAMETER force_installs
    Forces reinstallation/update of packages even if already installed.
    
.PARAMETER latest_everything
    Overrides all version specifications and installs latest available versions.
    
.PARAMETER whatif
    Dry-run mode. Shows what would be installed without actually installing.
    
.PARAMETER quiet
    Suppresses console output (file logging continues).
    
.EXAMPLE
    .\install.ps1 -stacks foundation
    
    Installs the foundation development stack (VS Code, Git, etc.)
    
.EXAMPLE
    .\install.ps1 -stacks foundation,java,python -whatif
    
    Shows what would be installed for foundation, java, and python stacks.
    
.EXAMPLE
    .\install.ps1 -stacks dotnet -force_installs -latest_everything
    
    Forces reinstall of .NET stack with latest versions of all packages.
    
.EXAMPLE
    .\install.ps1 -config_path "C:\my-config\custom.yaml"
    
    Installs packages from a custom configuration file.
    
.NOTES
    Author: win-dev-setup
    Date: 2025-12-19
    Version: 1.0
    
    Requirements:
    - Windows 10 (build 19041+) or Windows 11
    - PowerShell 5.1 or later
    - Internet connection
    - Some operations require administrator privileges
    
.LINK
    https://github.com/yourusername/win-dev-setup
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("foundation", "java", "python", "dotnet", "docker", "devops")]
    [string[]]$stacks,
    
    [Parameter(Mandatory = $false)]
    [string]$config_path,
    
    [switch]$force_installs,
    [switch]$latest_everything,
    [switch]$quiet
)

# Script execution starts here
# Get script directory for relative path resolution
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

# Import all required modules
$MODULES_DIR = Join-Path $SCRIPT_DIR "modules"

Write-Host "Importing modules from: $MODULES_DIR" -ForegroundColor Cyan

try {
    Import-Module (Join-Path $MODULES_DIR "logger.psm1") -Force -ErrorAction Stop
    Write-Host "Loaded logger.psm1" -ForegroundColor Green
    
    Import-Module (Join-Path $MODULES_DIR "validator.psm1") -Force -ErrorAction Stop
    Write-Host "Loaded validator.psm1" -ForegroundColor Green
    
    Import-Module (Join-Path $MODULES_DIR "config-loader.psm1") -Force -ErrorAction Stop
    Write-Host "Loaded config-loader.psm1" -ForegroundColor Green
    
    Import-Module (Join-Path $MODULES_DIR "package-manager.psm1") -Force -ErrorAction Stop
    Write-Host "Loaded package-manager.psm1" -ForegroundColor Green
    
    # Debug: Check if functions are available
    $testFunc = Get-Command Initialize-Logger -ErrorAction SilentlyContinue
    if ($testFunc) {
        Write-Host "DEBUG: Initialize-Logger IS available" -ForegroundColor Yellow
    } else {
        Write-Host "DEBUG: Initialize-Logger NOT available" -ForegroundColor Red
        Write-Host "Available commands from logger:" -ForegroundColor Red
        Get-Command -Module logger | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Red }
    }
}
catch {
    Write-Host "ERROR: Failed to import modules: $_" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Initialize logging system
Initialize-Logger -quiet:$quiet

Write-LogInfo "=========================================="
Write-LogInfo "Windows Development Environment Setup"
Write-LogInfo "Version 1.0"
Write-LogInfo "=========================================="

# Log execution parameters
Write-LogInfo "Execution Mode: $(if ($WhatIfPreference) { 'DRY RUN (WhatIf)' } else { 'INSTALL' })"

if ($stacks) {
    Write-LogInfo "Stacks requested: $($stacks -join ', ')"
}
if ($config_path) {
    Write-LogInfo "Custom config: $config_path"
}
if ($force_installs) {
    Write-LogInfo "Force installs: ENABLED"
}
if ($latest_everything) {
    Write-LogInfo "Latest everything: ENABLED"
}

Write-LogInfo "Log file: $(Get-LogPath)"
Write-LogInfo ""

# Step 1: Run prerequisite validation
Write-LogInfo "Step 1: Validating prerequisites..."

# Don't require admin for validation, but warn if not available
$VALIDATION_RESULT = invoke_prerequisite_validation -require_admin:$false

if (-not $VALIDATION_RESULT) {
    Write-LogError "Prerequisite validation failed. Please fix the issues above and try again."
    exit 1
}

Write-LogInfo ""

# Step 2: Determine what to install
Write-LogInfo "Step 2: Loading configuration..."

# Configuration list to process
$CONFIGS_TO_LOAD = @()

if ($config_path) {
    # Custom config file specified
    if (-not (Test-Path $config_path)) {
        Write-LogError "Custom configuration file not found: $config_path"
        exit 1
    }
    
    Write-LogInfo "Loading custom configuration: $config_path"
    
    try {
        $CUSTOM_CONFIG = load_yaml_config -config_path $config_path
        $CONFIGS_TO_LOAD += $CUSTOM_CONFIG
    }
    catch {
        Write-LogError "Failed to load custom configuration: $_"
        exit 1
    }
}
else {
    # Use default configs based on stack selection
    $DEFAULT_CONFIGS_DIR = Join-Path $SCRIPT_DIR "configs\defaults"
    
    if (-not (Test-Path $DEFAULT_CONFIGS_DIR)) {
        Write-LogError "Default configurations directory not found: $DEFAULT_CONFIGS_DIR"
        Write-LogInfo "Expected location: configs/defaults/"
        exit 1
    }
    
    # If no stacks specified, show available stacks and exit
    if (-not $stacks) {
        Write-LogWarning "No stacks specified. Please use -stacks parameter."
        Write-LogInfo ""
        Write-LogInfo "Available stacks:"
        Write-LogInfo "  foundation - VS Code, Git, basic development tools"
        Write-LogInfo "  java       - JDK, Maven, Gradle"
        Write-LogInfo "  python     - Python, pip, common packages"
        Write-LogInfo "  dotnet     - .NET SDK and tools"
        Write-LogInfo "  docker     - WSL, Docker Desktop, container tools"
        Write-LogInfo "  devops     - Azure CLI, Kubernetes, Terraform"
        Write-LogInfo ""
        Write-LogInfo "Example: .\install.ps1 -stacks foundation,python"
        exit 0
    }
    
    # Load configs for specified stacks
    try {
        $STACK_CONFIGS = load_configs_from_directory -config_dir $DEFAULT_CONFIGS_DIR -stack_names $stacks
        
        if ($STACK_CONFIGS.Count -eq 0) {
            Write-LogError "No valid configurations loaded for specified stacks"
            exit 1
        }
        
        $CONFIGS_TO_LOAD = $STACK_CONFIGS
    }
    catch {
        Write-LogError "Failed to load stack configurations: $_"
        exit 1
    }
}

Write-LogInfo "Loaded $($CONFIGS_TO_LOAD.Count) configuration file(s)"
Write-LogInfo ""

# Step 3: Collect all enabled packages
Write-LogInfo "Step 3: Collecting packages to install..."

$ALL_PACKAGES = @()

foreach ($CONFIG in $CONFIGS_TO_LOAD) {
    $ENABLED = get_enabled_packages -config $CONFIG
    
    if ($ENABLED.Count -gt 0) {
        Write-LogInfo "From $($CONFIG.source_file): $($ENABLED.Count) packages enabled"
        $ALL_PACKAGES += $ENABLED
    }
}

if ($ALL_PACKAGES.Count -eq 0) {
    Write-LogWarning "No packages enabled for installation. Check your configuration files."
    Write-LogInfo "Make sure packages have 'install: true' in the YAML files."
    exit 0
}

Write-LogInfo "Total packages to install: $($ALL_PACKAGES.Count)"
Write-LogInfo ""

# Step 4: Install packages
Write-LogInfo "Step 4: Installing packages..."
Write-LogInfo ""

# Install all packages
$INSTALL_RESULT = install_packages `
    -packages $ALL_PACKAGES `
    -force:$force_installs `
    -whatif:$WhatIfPreference `
    -latest_everything:$latest_everything

Write-LogInfo ""

# Step 5: Summary and next steps
Write-LogInfo "=========================================="
Write-LogInfo "Installation Summary"
Write-LogInfo "=========================================="
Write-LogInfo "Total packages processed: $($INSTALL_RESULT.total_count)"
Write-LogSuccess "Successfully installed: $($INSTALL_RESULT.success_count)"

if ($INSTALL_RESULT.failure_count -gt 0) {
    Write-LogWarning "Failed installations: $($INSTALL_RESULT.failure_count)"
    Write-LogInfo "Check the log file for details: $(Get-LogPath)"
}
else {
    Write-LogInfo "Failed installations: 0"
}

Write-LogInfo ""

# Provide next steps guidance
if (-not $WhatIfPreference) {
    Write-LogInfo "=========================================="
    Write-LogInfo "Next Steps"
    Write-LogInfo "=========================================="
    
    # Check if docker/WSL was in the stacks
    if ($stacks -contains "docker") {
        Write-LogInfo "WSL/Docker Setup:"
        Write-LogInfo "  1. WSL may require a system restart to complete installation"
        Write-LogInfo "  2. After restart, configure Docker Desktop settings"
        Write-LogInfo "  3. To install tools inside WSL Ubuntu, open WSL and run:"
        Write-LogInfo "     cd /mnt/c/Users/$env:USERNAME/repos/win-dev-setup"
        Write-LogInfo "     pwsh ./install.ps1 -stacks <your-stacks>"
        Write-LogInfo ""
    }
    
    Write-LogInfo "General:"
    Write-LogInfo "  - You may need to restart your terminal or computer for all changes to take effect"
    Write-LogInfo "  - Some tools may require additional configuration"
    Write-LogInfo "  - Check tool documentation for post-install setup"
    Write-LogInfo ""
    
    Write-LogInfo "Log file saved to: $(Get-LogPath)"
    Write-LogInfo ""
}

Write-LogInfo "=========================================="
Write-LogSuccess "Script execution completed!"
Write-LogInfo "=========================================="

# Exit with appropriate code
if ($INSTALL_RESULT.failure_count -gt 0 -and -not $WhatIfPreference) {
    exit 1
}
else {
    exit 0
}


