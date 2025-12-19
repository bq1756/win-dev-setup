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

Import-Module (Join-Path $MODULES_DIR "logger.psm1") -Force
Import-Module (Join-Path $MODULES_DIR "validator.psm1") -Force
Import-Module (Join-Path $MODULES_DIR "config-loader.psm1") -Force
Import-Module (Join-Path $MODULES_DIR "package-manager.psm1") -Force

# Initialize logging system
initialize_logger -quiet:$quiet

write_log_info "=========================================="
write_log_info "Windows Development Environment Setup"
write_log_info "Version 1.0"
write_log_info "=========================================="

# Log execution parameters
write_log_info "Execution Mode: $(if ($WhatIfPreference) { 'DRY RUN (WhatIf)' } else { 'INSTALL' })"

if ($stacks) {
    write_log_info "Stacks requested: $($stacks -join ', ')"
}
if ($config_path) {
    write_log_info "Custom config: $config_path"
}
if ($force_installs) {
    write_log_info "Force installs: ENABLED"
}
if ($latest_everything) {
    write_log_info "Latest everything: ENABLED"
}

write_log_info "Log file: $(get_log_path)"
write_log_info ""

# Step 1: Run prerequisite validation
write_log_info "Step 1: Validating prerequisites..."

# Don't require admin for validation, but warn if not available
$VALIDATION_RESULT = invoke_prerequisite_validation -require_admin:$false

if (-not $VALIDATION_RESULT) {
    write_log_error "Prerequisite validation failed. Please fix the issues above and try again."
    exit 1
}

write_log_info ""

# Step 2: Determine what to install
write_log_info "Step 2: Loading configuration..."

# Configuration list to process
$CONFIGS_TO_LOAD = @()

if ($config_path) {
    # Custom config file specified
    if (-not (Test-Path $config_path)) {
        write_log_error "Custom configuration file not found: $config_path"
        exit 1
    }
    
    write_log_info "Loading custom configuration: $config_path"
    
    try {
        $CUSTOM_CONFIG = load_yaml_config -config_path $config_path
        $CONFIGS_TO_LOAD += $CUSTOM_CONFIG
    }
    catch {
        write_log_error "Failed to load custom configuration: $_"
        exit 1
    }
}
else {
    # Use default configs based on stack selection
    $DEFAULT_CONFIGS_DIR = Join-Path $SCRIPT_DIR "configs\defaults"
    
    if (-not (Test-Path $DEFAULT_CONFIGS_DIR)) {
        write_log_error "Default configurations directory not found: $DEFAULT_CONFIGS_DIR"
        write_log_info "Expected location: configs/defaults/"
        exit 1
    }
    
    # If no stacks specified, show available stacks and exit
    if (-not $stacks) {
        write_log_warning "No stacks specified. Please use -stacks parameter."
        write_log_info ""
        write_log_info "Available stacks:"
        write_log_info "  foundation - VS Code, Git, basic development tools"
        write_log_info "  java       - JDK, Maven, Gradle"
        write_log_info "  python     - Python, pip, common packages"
        write_log_info "  dotnet     - .NET SDK and tools"
        write_log_info "  docker     - WSL, Docker Desktop, container tools"
        write_log_info "  devops     - Azure CLI, Kubernetes, Terraform"
        write_log_info ""
        write_log_info "Example: .\install.ps1 -stacks foundation,python"
        exit 0
    }
    
    # Load configs for specified stacks
    try {
        $STACK_CONFIGS = load_configs_from_directory -config_dir $DEFAULT_CONFIGS_DIR -stack_names $stacks
        
        if ($STACK_CONFIGS.Count -eq 0) {
            write_log_error "No valid configurations loaded for specified stacks"
            exit 1
        }
        
        $CONFIGS_TO_LOAD = $STACK_CONFIGS
    }
    catch {
        write_log_error "Failed to load stack configurations: $_"
        exit 1
    }
}

write_log_info "Loaded $($CONFIGS_TO_LOAD.Count) configuration file(s)"
write_log_info ""

# Step 3: Collect all enabled packages
write_log_info "Step 3: Collecting packages to install..."

$ALL_PACKAGES = @()

foreach ($CONFIG in $CONFIGS_TO_LOAD) {
    $ENABLED = get_enabled_packages -config $CONFIG
    
    if ($ENABLED.Count -gt 0) {
        write_log_info "From $($CONFIG.source_file): $($ENABLED.Count) packages enabled"
        $ALL_PACKAGES += $ENABLED
    }
}

if ($ALL_PACKAGES.Count -eq 0) {
    write_log_warning "No packages enabled for installation. Check your configuration files."
    write_log_info "Make sure packages have 'install: true' in the YAML files."
    exit 0
}

write_log_info "Total packages to install: $($ALL_PACKAGES.Count)"
write_log_info ""

# Step 4: Install packages
write_log_info "Step 4: Installing packages..."
write_log_info ""

# Install all packages
$INSTALL_RESULT = install_packages `
    -packages $ALL_PACKAGES `
    -force:$force_installs `
    -whatif:$WhatIfPreference `
    -latest_everything:$latest_everything

write_log_info ""

# Step 5: Summary and next steps
write_log_info "=========================================="
write_log_info "Installation Summary"
write_log_info "=========================================="
write_log_info "Total packages processed: $($INSTALL_RESULT.total_count)"
write_log_success "Successfully installed: $($INSTALL_RESULT.success_count)"

if ($INSTALL_RESULT.failure_count -gt 0) {
    write_log_warning "Failed installations: $($INSTALL_RESULT.failure_count)"
    write_log_info "Check the log file for details: $(get_log_path)"
}
else {
    write_log_info "Failed installations: 0"
}

write_log_info ""

# Provide next steps guidance
if (-not $WhatIfPreference) {
    write_log_info "=========================================="
    write_log_info "Next Steps"
    write_log_info "=========================================="
    
    # Check if docker/WSL was in the stacks
    if ($stacks -contains "docker") {
        write_log_info "WSL/Docker Setup:"
        write_log_info "  1. WSL may require a system restart to complete installation"
        write_log_info "  2. After restart, configure Docker Desktop settings"
        write_log_info "  3. To install tools inside WSL Ubuntu, open WSL and run:"
        write_log_info "     cd /mnt/c/Users/$env:USERNAME/repos/win-dev-setup"
        write_log_info "     pwsh ./install.ps1 -stacks <your-stacks>"
        write_log_info ""
    }
    
    write_log_info "General:"
    write_log_info "  - You may need to restart your terminal or computer for all changes to take effect"
    write_log_info "  - Some tools may require additional configuration"
    write_log_info "  - Check tool documentation for post-install setup"
    write_log_info ""
    
    write_log_info "Log file saved to: $(get_log_path)"
    write_log_info ""
}

write_log_info "=========================================="
write_log_success "Script execution completed!"
write_log_info "=========================================="

# Exit with appropriate code
if ($INSTALL_RESULT.failure_count -gt 0 -and -not $WhatIfPreference) {
    exit 1
}
else {
    exit 0
}

