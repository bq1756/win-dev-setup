# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-12-19

### Initial Release

#### Added
- **Core Functionality**
  - Main installation script (`install.ps1`) with modular stack selection
  - Bootstrap script (`scripts/bootstrap.ps1`) for initial setup
  - Comprehensive logging system with file and console output
  - YAML-based configuration system
  - Support for multiple package managers (winget, Chocolatey, PowerShell Gallery, VS Code extensions)
  
- **Modules**
  - `logger.psm1` - Logging with color-coded output and file logging
  - `config-loader.psm1` - YAML configuration parsing and validation
  - `validator.psm1` - System prerequisite validation
  - `package-manager.psm1` - Unified package installation interface
  
- **Pre-configured Stacks**
  - Foundation: VS Code, Git, PowerShell 7, Windows Terminal, utilities
  - Java: JDK 21, Maven, Gradle, IntelliJ IDEA Community
  - Python: Python 3.12, VS Code extensions, Jupyter support
  - .NET: .NET 8 SDK, C# Dev Kit, development tools
  - Docker: WSL, Docker Desktop, container development tools
  - DevOps: Azure CLI, Terraform, kubectl, Helm, GitHub CLI
  
- **Features**
  - Dry run mode (`-whatif`) to preview installations
  - Force reinstall mode (`-force_installs`)
  - Latest version override (`-latest_everything`)
  - Quiet mode (`-quiet`) for minimal console output
  - Custom configuration file support
  - Automatic fallback from winget to Chocolatey
  - WSL and Ubuntu support
  - Comprehensive error handling with graceful degradation
  
- **Documentation**
  - Comprehensive README with usage examples
  - Detailed requirements document
  - Manual test checklist
  - Custom configuration template
  - Developer contribution guidelines
  
#### Code Style
- All lowercase file and function names (no CamelCase)
- UPPER_CASE or underscore_separated variable names
- Extensive inline comments explaining flow and business logic
- Complete SYNOPSIS blocks for all functions

#### Technical Details
- Minimum requirement: Windows 10 build 19041+ or Windows 11
- PowerShell 5.1+ (PowerShell 7+ recommended)
- Execution policy validation and guidance
- Administrator privilege detection and handling
- Idempotent operation (safe to run multiple times)

### Package Managers Supported
- **winget** (Windows Package Manager) - Primary/default
- **Chocolatey** - Fallback and specialized packages
- **PowerShell Gallery** - PowerShell modules
- **VS Code Marketplace** - Editor extensions
- **apt** - Ubuntu/Debian (for WSL environments)

### Known Limitations
- WSL installation requires system restart
- Chocolatey installation requires administrator privileges
- VS Code extensions require VS Code to be installed first
- Some packages only available in specific package managers
- Network connectivity required for all installations

### Security
- Scripts check execution policy and provide remediation guidance
- No credentials stored or transmitted
- All packages installed from official sources
- Automatic HTTPS for downloads via package managers

## [Unreleased]

### Planned Features
- Automated rollback on critical failures
- Dependency resolution between packages
- Pre-flight disk space checks
- Automated testing framework (Pester)
- GUI configuration tool
- Package version conflict detection
- Export current environment to configuration file
- Backup and restore functionality

---

## Version History

- **1.0.0** (2025-12-19) - Initial release with core functionality
