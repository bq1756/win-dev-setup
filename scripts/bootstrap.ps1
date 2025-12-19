<#
.SYNOPSIS
    Minimal bootstrap script for win-dev-setup.
    
.DESCRIPTION
    This is a lightweight, standalone script that prepares the system for the
    full installation process. It performs minimal initial setup:
    
    1. Checks execution policy and provides guidance
    2. Checks for Git and installs if missing (using winget)
    3. Optionally clones the win-dev-setup repository
    4. Provides next steps for running the full install.ps1
    
    This script is designed to be:
    - Standalone (minimal dependencies)
    - Well-commented for clarity
    - Safe to run multiple times (idempotent)
    
.PARAMETER skip_git_install
    If specified, skips automatic Git installation check.
    
.PARAMETER skip_repo_clone
    If specified, skips cloning the repository.
    
.EXAMPLE
    .\bootstrap.ps1
    
    Runs full bootstrap process: checks Git, installs if needed, prompts to clone repo.
    
.EXAMPLE
    .\bootstrap.ps1 -skip_repo_clone
    
    Checks/installs Git but doesn't clone the repository.
    
.NOTES
    Author: win-dev-setup
    Date: 2025-12-19
    Version: 1.0
    
    This script can be downloaded and run standalone to get started.
#>

[CmdletBinding()]
param(
    [switch]$skip_git_install,
    [switch]$skip_repo_clone
)

# ==============================================================================
# FUNCTION: Write colored console output
# ==============================================================================
function write-colored {
    param(
        [string]$message,
        [string]$color = "White"
    )
    Write-Host $message -ForegroundColor $color
}

# ==============================================================================
# FUNCTION: Check if running as administrator
# ==============================================================================
function test-admin {
    $CURRENT_PRINCIPAL = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $CURRENT_PRINCIPAL.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ==============================================================================
# FUNCTION: Check if a command exists
# ==============================================================================
function test-command {
    param([string]$command_name)
    
    $CMD = Get-Command $command_name -ErrorAction SilentlyContinue
    return ($null -ne $CMD)
}

# ==============================================================================
# MAIN SCRIPT EXECUTION
# ==============================================================================

Clear-Host

write-colored "=========================================" "Cyan"
write-colored "Windows Dev Setup - Bootstrap" "Cyan"
write-colored "=========================================" "Cyan"
Write-Host ""

# ------------------------------------------------------------------------------
# Step 1: Check execution policy
# ------------------------------------------------------------------------------
write-colored "[Step 1] Checking PowerShell execution policy..." "Cyan"

$EXEC_POLICY = Get-ExecutionPolicy
write-colored "Current execution policy: $EXEC_POLICY" "White"

# Acceptable policies for running scripts
$ACCEPTABLE_POLICIES = @('Unrestricted', 'RemoteSigned', 'Bypass', 'Undefined')

if ($EXEC_POLICY -notin $ACCEPTABLE_POLICIES) {
    # Execution policy is too restrictive
    write-colored "ERROR: Execution policy is too restrictive!" "Red"
    write-colored "" "White"
    write-colored "To fix this, run PowerShell as Administrator and execute:" "Yellow"
    write-colored "    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser" "Yellow"
    write-colored "" "White"
    write-colored "Or for system-wide (requires admin):" "Yellow"
    write-colored "    Set-ExecutionPolicy RemoteSigned -Scope LocalMachine" "Yellow"
    Write-Host ""
    exit 1
}
else {
    write-colored "Execution policy is acceptable for script execution." "Green"
}

Write-Host ""

# ------------------------------------------------------------------------------
# Step 2: Check administrator privileges
# ------------------------------------------------------------------------------
write-colored "[Step 2] Checking administrator privileges..." "Cyan"

if (test-admin) {
    write-colored "Running with administrator privileges." "Green"
}
else {
    write-colored "WARNING: Not running with administrator privileges." "Yellow"
    write-colored "Some installations may require admin rights. Consider re-running as Administrator." "Yellow"
}

Write-Host ""

# ------------------------------------------------------------------------------
# Step 3: Check for Git (required to clone repository)
# ------------------------------------------------------------------------------
write-colored "[Step 3] Checking for Git installation..." "Cyan"

$GIT_INSTALLED = test-command "git"

if ($GIT_INSTALLED) {
    # Git is already installed
    $GIT_VERSION = & git --version 2>&1
    write-colored "Git is already installed: $GIT_VERSION" "Green"
}
else {
    # Git is not installed
    write-colored "Git is not installed." "Yellow"
    
    if ($skip_git_install) {
        write-colored "Skipping Git installation (skip_git_install flag specified)." "Yellow"
    }
    else {
        # Prompt user to install Git
        write-colored "" "White"
        write-colored "Git is required to clone the win-dev-setup repository." "White"
        
        # Check if winget is available (preferred method)
        $WINGET_AVAILABLE = test-command "winget"
        
        if ($WINGET_AVAILABLE) {
            write-colored "Installing Git using winget..." "Cyan"
            
            try {
                # Install Git using winget
                # --source winget: Use winget source explicitly (avoids msstore certificate errors)
                # --silent: No UI, --accept-package-agreements: auto-accept licenses
                & winget install --id Git.Git --source winget --silent --accept-package-agreements --accept-source-agreements
                
                # Check if winget command succeeded
                # Note: winget may show warnings but still succeed (exit code 0 or -1978335189 for "already installed")
                if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq -1978335189) {
                    write-colored "Git installation completed via winget." "Green"
                    
                    # Refresh environment PATH to pick up git command
                    # Note: May require opening a new terminal session
                    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
                    
                    # Verify installation
                    if (test-command "git") {
                        $GIT_VERSION = & git --version 2>&1
                        write-colored "Git command is available: $GIT_VERSION" "Green"
                        $GIT_INSTALLED = $true
                    }
                    else {
                        write-colored "WARNING: Git installed but not immediately available in PATH." "Yellow"
                        write-colored "You may need to open a new PowerShell window for Git to be available." "Yellow"
                        write-colored "Continuing with repository clone step (will skip if git not in PATH)..." "Yellow"
                        # Set flag to true anyway since installation succeeded
                        $GIT_INSTALLED = $true
                    }
                }
                else {
                    write-colored "WARNING: winget install command returned exit code: $LASTEXITCODE" "Yellow"
                    write-colored "Please verify Git installation manually or install from: https://git-scm.com/downloads" "Yellow"
                }
            }
            catch {
                write-colored "ERROR: Failed to install Git: $_" "Red"
                write-colored "Please install Git manually from: https://git-scm.com/downloads" "Yellow"
            }
        }
        else {
            # winget not available - provide manual instructions
            write-colored "winget (Windows Package Manager) is not available." "Yellow"
            write-colored "" "White"
            write-colored "Please install Git manually from: https://git-scm.com/downloads" "Yellow"
            write-colored "After installing Git, re-run this bootstrap script." "Yellow"
            Write-Host ""
            exit 1
        }
    }
}

Write-Host ""

# ------------------------------------------------------------------------------
# Step 4: Repository cloning (optional)
# ------------------------------------------------------------------------------
write-colored "[Step 4] Repository setup..." "Cyan"

if ($skip_repo_clone) {
    write-colored "Skipping repository clone (skip_repo_clone flag specified)." "Yellow"
}
elseif (-not $GIT_INSTALLED) {
    write-colored "Cannot clone repository without Git. Install Git first." "Yellow"
}
else {
    # Git is available, offer to clone repository
    write-colored "" "White"
    write-colored "If you haven't already, you can clone the win-dev-setup repository." "White"
    write-colored "" "White"
    
    # Prompt user for repository URL
    $REPO_URL = Read-Host "Enter repository URL (or press Enter to skip)"
    
    if ($REPO_URL) {
        # Ask for destination directory
        $DEFAULT_PATH = Join-Path $HOME "repos\win-dev-setup"
        write-colored "Default clone location: $DEFAULT_PATH" "White"
        $CLONE_PATH = Read-Host "Enter clone path (or press Enter for default)"
        
        if (-not $CLONE_PATH) {
            $CLONE_PATH = $DEFAULT_PATH
        }
        
        # Create parent directory if it doesn't exist
        $PARENT_DIR = Split-Path -Parent $CLONE_PATH
        if (-not (Test-Path $PARENT_DIR)) {
            write-colored "Creating directory: $PARENT_DIR" "Cyan"
            New-Item -ItemType Directory -Path $PARENT_DIR -Force | Out-Null
        }
        
        # Clone repository
        write-colored "Cloning repository to: $CLONE_PATH" "Cyan"
        
        try {
            & git clone $REPO_URL $CLONE_PATH
            
            if ($LASTEXITCODE -eq 0) {
                write-colored "Repository cloned successfully!" "Green"
                write-colored "" "White"
                write-colored "Next steps:" "Cyan"
                write-colored "  1. cd $CLONE_PATH" "White"
                write-colored "  2. .\install.ps1 -stacks foundation" "White"
            }
            else {
                write-colored "ERROR: Failed to clone repository." "Red"
            }
        }
        catch {
            write-colored "ERROR: Failed to clone repository: $_" "Red"
        }
    }
    else {
        write-colored "Skipping repository clone." "Yellow"
    }
}

Write-Host ""

# ==============================================================================
# Summary and next steps
# ==============================================================================
write-colored "=========================================" "Cyan"
write-colored "Bootstrap Complete!" "Cyan"
write-colored "=========================================" "Cyan"
Write-Host ""

if ($GIT_INSTALLED) {
    write-colored "Next Steps:" "Cyan"
    write-colored "  1. Navigate to the win-dev-setup directory" "White"
    write-colored "  2. Review the README.md for usage instructions" "White"
    write-colored "  3. Run: .\install.ps1 -stacks <stack-names>" "White"
    write-colored "" "White"
    write-colored "Example stacks: foundation, java, python, dotnet, docker, devops" "White"
}
else {
    write-colored "Please install Git and then run this bootstrap script again." "Yellow"
}

Write-Host ""
write-colored "For help, run: .\install.ps1 (without parameters)" "White"
Write-Host ""
