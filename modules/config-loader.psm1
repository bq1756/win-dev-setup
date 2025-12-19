<#
.SYNOPSIS
    Configuration file loader for win-dev-setup tool.
    Handles parsing and validation of YAML configuration files.

.DESCRIPTION
    This module loads YAML configuration files and validates their structure.
    It uses the PowerShell-Yaml module for YAML parsing.
    
    Configuration files define packages to install, their versions, and package managers.
    
.NOTES
    Author: win-dev-setup
    Date: 2025-12-19
    
    Requires: powershell-yaml module
#>

# Import logger module for logging functionality
Import-Module (Join-Path $PSScriptRoot "logger.psm1") -Force

<#
.SYNOPSIS
    Ensures PowerShell-Yaml module is installed.

.DESCRIPTION
    Checks if powershell-yaml module is available and installs it if missing.
    This is required for YAML file parsing.

.PARAMETER interactive
    If specified, allows prompts during module installation.

.EXAMPLE
    Install-YamlModule
#>
function Install-YamlModule {
    [CmdletBinding()]
    param(
        [switch]$interactive
    )
    
    # Check if powershell-yaml module is already installed
    if (Get-Module -ListAvailable -Name powershell-yaml) {
        Import-Module powershell-yaml -ErrorAction Stop
        return
    }
    
    Write-LogInfo "PowerShell-Yaml module not found. Installing..."
    
    try {
        # Ensure NuGet provider is installed (required for Install-Module)
        $nugetProvider = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
        if (-not $nugetProvider) {
            Write-LogInfo "Installing NuGet package provider..."
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser -Confirm:$false | Out-Null
        }
        
        if ($interactive) {
            Install-Module -Name powershell-yaml -Scope CurrentUser -ErrorAction Stop
        } else {
            Install-Module -Name powershell-yaml -Scope CurrentUser -Force -AllowClobber -SkipPublisherCheck -ErrorAction Stop
        }
        Import-Module powershell-yaml -ErrorAction Stop
        Write-LogSuccess "PowerShell-Yaml module installed successfully"
    }
    catch {
        Write-LogError "Failed to install powershell-yaml module: $_"
        throw
    }
}

<#
.SYNOPSIS
    Loads a YAML configuration file.

.DESCRIPTION
    Reads a YAML file and parses it into a PowerShell object.
    Validates the basic structure of the configuration.

.PARAMETER config_path
    Full path to the YAML configuration file.

.RETURNS
    Parsed configuration object containing package definitions.

.EXAMPLE
    $config = Load-YamlConfig -config_path "C:\configs\foundation.yaml"
#>
function Load-YamlConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$config_path,
        
        [switch]$interactive
    )
    
    Write-LogInfo "Loading configuration file: $config_path"
    
    # Ensure YAML module is available
    Install-YamlModule -interactive:$interactive
    
    # Check if file exists
    if (-not (Test-Path -Path $config_path)) {
        Write-LogError "Configuration file not found: $config_path"
        throw "Configuration file not found: $config_path"
    }
    
    try {
        # Read and parse YAML file
        $YAML_CONTENT = Get-Content -Path $config_path -Raw -ErrorAction Stop
        
        if (-not $YAML_CONTENT) {
            throw "Configuration file is empty: $config_path"
        }
        
        $CONFIG = ConvertFrom-Yaml -Yaml $YAML_CONTENT -ErrorAction Stop
        
        # Validate basic structure
        if (-not $CONFIG) {
            throw "Configuration file is empty or invalid"
        }
        
        if (-not $CONFIG.packages) {
            throw "Configuration file missing 'packages' section"
        }
        
        Write-LogSuccess "Configuration loaded successfully: $($CONFIG.packages.Count) packages found"
        
        return $CONFIG
    }
    catch {
        Write-LogError "Failed to load configuration file: $_"
        throw
    }
}

<#
.SYNOPSIS
    Validates a package configuration entry.

.DESCRIPTION
    Checks that a package entry has all required fields and valid values.
    Required fields: name, install, pkgmgr
    Optional fields: version, description

.PARAMETER package
    Package configuration object to validate.

.RETURNS
    $true if valid, $false otherwise.

.EXAMPLE
    $is_valid = Test-PackageConfig -package $pkg
#>
function Test-PackageConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$package
    )
    
    # Check required fields
    $REQUIRED_FIELDS = @('name', 'install', 'pkgmgr')
    
    foreach ($FIELD in $REQUIRED_FIELDS) {
        if (-not $package.PSObject.Properties.Name.Contains($FIELD)) {
            Write-LogWarning "Package configuration missing required field '$FIELD': $($package | ConvertTo-Json -Compress)"
            return $false
        }
    }
    
    # Validate package manager value
    $VALID_PKGMGRS = @('winget', 'choco', 'pwsh', 'vscode', 'apt')
    if ($package.pkgmgr -notin $VALID_PKGMGRS) {
        Write-LogWarning "Invalid package manager '$($package.pkgmgr)' for package '$($package.name)'. Valid options: $($VALID_PKGMGRS -join ', ')"
        return $false
    }
    
    # Validate install field is boolean
    if ($package.install -isnot [bool]) {
        Write-LogWarning "Package '$($package.name)' has invalid 'install' value. Must be true or false."
        return $false
    }
    
    return $true
}

<#
.SYNOPSIS
    Filters packages based on installation flag.

.DESCRIPTION
    Returns only packages that are marked for installation (install: true).
    Also validates each package configuration.

.PARAMETER config
    Configuration object containing packages array.

.RETURNS
    Array of packages marked for installation.

.EXAMPLE
    $packages_to_install = Get-EnabledPackages -config $config
#>
function Get-EnabledPackages {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$config
    )
    
    $ENABLED_PACKAGES = @()
    
    foreach ($PACKAGE in $config.packages) {
        # Validate package configuration
        if (-not (Test-PackageConfig -package $PACKAGE)) {
            Write-LogWarning "Skipping invalid package configuration"
            continue
        }
        
        # Only include packages marked for installation
        if ($PACKAGE.install -eq $true) {
            $ENABLED_PACKAGES += $PACKAGE
        }
        else {
            Write-LogInfo "Package disabled in config: $($PACKAGE.name)"
        }
    }
    
    Write-LogInfo "Found $($ENABLED_PACKAGES.Count) enabled packages out of $($config.packages.Count) total"
    
    return $ENABLED_PACKAGES
}

<#
.SYNOPSIS
    Loads multiple configuration files from a directory.

.DESCRIPTION
    Scans a directory for YAML files and loads all valid configurations.
    Useful for loading all stack configurations at once.

.PARAMETER config_dir
    Directory path containing YAML configuration files.

.PARAMETER stack_names
    Optional array of stack names to load. If not specified, loads all YAML files.

.RETURNS
    Array of configuration objects.

.EXAMPLE
    $configs = load-configs-from-directory -config_dir "C:\configs\defaults"
    
.EXAMPLE
    $configs = load-configs-from-directory -config_dir "C:\configs\defaults" -stack_names @("foundation", "java")
#>
function Load-ConfigsFromDirectory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$config_dir,
        
        [Parameter(Mandatory = $false)]
        [string[]]$stack_names,
        
        [switch]$interactive
    )
    
    Write-LogInfo "Loading configurations from directory: $config_dir"
    
    # Check if directory exists
    if (-not (Test-Path -Path $config_dir)) {
        Write-LogError "Configuration directory not found: $config_dir"
        throw "Configuration directory not found: $config_dir"
    }
    
    # Get all YAML files in directory
    $YAML_FILES = Get-ChildItem -Path $config_dir -Filter "*.yaml" -File
    
    if ($YAML_FILES.Count -eq 0) {
        Write-LogWarning "No YAML files found in directory: $config_dir"
        return @()
    }
    
    $CONFIGS = @()
    
    foreach ($FILE in $YAML_FILES) {
        # If stack names specified, only load matching files
        if ($stack_names) {
            $FILE_BASE_NAME = [System.IO.Path]::GetFileNameWithoutExtension($FILE.Name)
            if ($FILE_BASE_NAME -notin $stack_names) {
                Write-LogInfo "Skipping config file (not in requested stacks): $($FILE.Name)"
                continue
            }
        }
        
        try {
            # Load configuration file
            $CONFIG = Load-YamlConfig -config_path $FILE.FullName -interactive:$interactive
            
            # Add metadata about source file
            $CONFIG | Add-Member -NotePropertyName "source_file" -NotePropertyValue $FILE.Name -Force
            
            $CONFIGS += $CONFIG
        }
        catch {
            Write-LogError "Failed to load configuration file '$($FILE.Name)': $_"
            # Continue with other files even if one fails
        }
    }
    
    Write-LogInfo "Successfully loaded $($CONFIGS.Count) configuration files"
    
    return $CONFIGS
}

# Export all functions
# All functions auto-exported

