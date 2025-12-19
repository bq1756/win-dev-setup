# Development Environment Bootstrap - User Requirements

## Project Overview

A Windows development environment bootstrapping tool that automates the setup of development machines through PowerShell scripting and YAML-based configuration files.

## Design Decisions

### Code Style Guidelines
- **All code files and function names**: lowercase (e.g., `install.ps1`, `get-packages.ps1`)
- **Variable names**: Use `_` character and/or UPPER CASE (e.g., `$PACKAGE_NAME`, `$install_path`)
- **No CamelCase** in any code or file names

### Package Manager Strategy
- **Primary**: winget (Windows Package Manager) - default for all packages
- **Fallback**: Chocolatey - only when package is not available in winget
- **VS Code Extensions**: via `code` CLI
- **PowerShell Modules**: PowerShell Gallery

### Configuration Files
- **Format**: YAML (for readability and comments support)
- **Location**: `configs/` folder in repository
- **Structure**: Separate config files for each development stack

### Project Structure
```
win-dev-setup/
├── install.ps1                     # Main entry point with minimal bootstrap logic
├── modules/
│   ├── package-manager.psm1        # Package manager abstraction
│   ├── config-loader.psm1          # YAML config file parsing
│   ├── validator.psm1              # Prerequisite validation
│   └── logger.psm1                 # Logging utilities
├── configs/
│   ├── defaults/                   # Shipped configurations
│   │   ├── foundation.yaml
│   │   ├── java.yaml
│   │   ├── python.yaml
│   │   ├── dotnet.yaml
│   │   ├── docker.yaml
│   │   └── devops.yaml
│   └── examples/
│       └── custom-template.yaml
├── scripts/
│   └── bootstrap.ps1               # Standalone minimal bootstrap script
├── tests/
│   └── manual-test-checklist.md    # Manual testing checklist
├── LICENSE
├── README.md
├── REQUIREMENTS.md
└── CHANGELOG.md
```

---

## Functional Requirements

### FR1: Environment Validation
- As a user, I need the script to validate that I have the required tools installed before proceeding
- As a user, I need clear error messages if prerequisites aren't met
- As a developer, I want to minimize end user manual tasks such as installing prerequisites. If practical I prefer to bootstrap with default tools included with Windows and automatically install dependencies needed for this process to execute successfully.
- This script(s) or project is hosted in GitHub. The Windows machine needs Git installed to be able to pull down the project or an executable.

### FR2: Package Manager Bootstrap
- As a user, I must be able to configure and use multiple package managers. I want to use **winget as the default package manager**. I am open to Chocolatey for packages that are not available in winget yet.
- As a user, I should not need to manually install any package managers.
- As a user, I want to install VS Code extensions with this tool.
- **WSL Installation**: This script should support WSL installation as an optional component during initial bootstrap.
  - Auto-install latest LTS version of Ubuntu
  - After WSL is installed and functional, user logs into WSL Ubuntu and runs `install.ps1` to complete remaining installs in the Linux environment
  - For Ubuntu, prefer `apt` package manager
  - Bootstrap with bash is acceptable, but most of the process should run as pwsh in Ubuntu

### FR3: Modular Development Stack Installation
- As a user, I want to choose which development environments to install via command-line flags. I must be able to install multiple dev environment types on the same machine.
- As a user, I want the following environment options:
  - Foundation (VS Code, basic extensions)
  - Java development (JDK, build tools, IDE)
  - Python development (Python, package manager, IDE)
  - .NET development
  - Docker/container development (WSL, Docker Desktop, extensions)
  - Operations/DevOps (Kubernetes, azure cloud tools, security scanners)

### FR4: Custom Configuration Support
- As a user, I want to provide my own YAML file with personal tool preferences
- As a user, I want to install tools from multiple package managers (winget, Chocolatey, PowerShell Gallery, VS Code Marketplace)
- As a user, I want flexibility to choose versions of packages and software through configuration. I must be able to specify a specific version to be installed, e.g. 1.2.3. I must have a way to install the latest available. If the package manager supports wildcard versions, I should be able to use wildcards in my config.

### FR5: Installation Control
- As a user, I want to force reinstallation/updates of packages with a `-force_installs` flag
- As a user, I want to run the script quietly without verbose output using a `-quiet` flag
- As a user, I want to selectively enable/disable installations via YAML configuration
- As a user, I should be able to add a `-latest_everything` flag that overrides version configuration in all .yaml files and installs or upgrades the most recent version of each enabled package
- As a user, I want a `-whatif` (dry run) mode to see what would be installed without actually installing anything

### FR6: Post-Installation Guidance
- As a user, I need to be notified about manual installation steps that can't be automated
- As a user, I need links/instructions for manual installations (e.g., Azure VPN Client)

### FR7: Logging & Console Output
- As a user, I want comprehensive logging of all operations to a timestamped log file
- As a user, I want clear console output showing: package name, version, installation status, and progress
- Log files should be stored in `$env:TEMP\win-dev-setup-{timestamp}.log`
- Log should include: installed packages, versions, failures, warnings, and timestamps
- Console output should be color-coded for different status levels (info, warning, error, success)

### FR8: Bootstrap & Prerequisites
- As a user, I need a standalone `bootstrap.ps1` script that can initialize the environment
- The bootstrap script should be minimal, well-commented, and handle Git installation if missing
- The bootstrap script should validate execution policy and permissions before proceeding

---

## Non-Functional Requirements

### NFR1: Idempotency
- The script must be safe to run multiple times without breaking existing installations

### NFR2: Error Handling
- The script should gracefully handle installation failures
- The script should continue installing other packages if one fails

### NFR3: Performance
- The script should provide progress feedback during installations

### NFR4: Maintainability
- Configuration should be separated from logic (YAML config files vs PowerShell scripts)
- Adding new packages should only require config file modifications or additions
- YAML format preferred for config files for end user readability and ease of use

### NFR5: Admin Privileges & Execution Policy
- The script must detect if it needs elevation and provide clear guidance
- The script must validate PowerShell execution policy and guide users to fix issues
- Some operations should work without admin rights (VS Code extensions, pwsh modules for current user)
- The script must clearly indicate which operations require administrator privileges

### NFR6: Testing
- Manual test checklist provided for validation on fresh Windows 11 installations
- Test checklist should cover all development stacks and edge cases

---

## Known Issues/Gaps

### Critical Issues
- ❌ **Config format migration needed** - Convert existing JSON configs to YAML format
- ❌ **Package manager specification** - All configs must specify preferred package manager (winget preferred)

### Medium Priority Issues
- ⚠️ **WSL validation** - WSL check and installation logic needs implementation
- ⚠️ **Logging implementation** - Need comprehensive logging system

### Enhancement Opportunities
- 💡 **No rollback mechanism** - if installation fails, there's no cleanup (out of scope for v1)
- 💡 **Version reporting** - script should report what was installed/updated (covered by logging)

---

## Configuration File Structure

Each YAML configuration file should follow this schema:

```yaml
# Example configuration file
packages:
  - name: package-name          # Package identifier for the package manager
    install: true               # Enable/disable installation
    version: "1.2.3"           # Specific version, "latest", or null for latest
    pkgmgr: winget             # Package manager: winget, choco, pwsh, vscode, apt
    description: "Optional description for documentation"

  - name: another-package
    install: false
    version: latest
    pkgmgr: choco
```

### Supported Package Managers
- `winget` - Windows Package Manager (preferred/default)
- `choco` - Chocolatey package manager (fallback)
- `pwsh` - PowerShell Gallery modules
- `vscode` - VS Code extensions
- `apt` - Ubuntu/Debian package manager (WSL only)

---

## Future Enhancements (Out of Scope)

- Support for macOS (Linux/WSL supported in v1)
- GUI interface for selecting packages
- Automatic detection of existing tools and smart recommendations
- Backup/export and restore of environment configuration
- Dependency resolution between packages
- Pre-flight checks for disk space
- Network connectivity and proxy support
- Automated rollback on failure

---

## Command-Line Interface

### Main Script: `install.ps1`

```powershell
# Install foundation stack only
.\install.ps1 -stacks foundation

# Install multiple stacks
.\install.ps1 -stacks foundation,java,python,docker

# Dry run to see what would be installed
.\install.ps1 -stacks foundation -whatif

# Force reinstall/update all packages
.\install.ps1 -stacks dotnet -force_installs

# Install latest version of everything, ignoring version pins
.\install.ps1 -stacks foundation,devops -latest_everything

# Quiet mode with minimal output
.\install.ps1 -stacks python -quiet

# Use custom configuration file
.\install.ps1 -config_path "C:\my-configs\custom.yaml"
```

### Bootstrap Script: `scripts\bootstrap.ps1`

```powershell
# Minimal standalone script to get started
# Downloads and initializes the full installation environment
.\bootstrap.ps1
```
