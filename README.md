# Windows Development Environment Setup

Automated Windows development environment bootstrapping tool using PowerShell and YAML configuration files. Supports multiple development stacks including Foundation, Java, Python, .NET, Docker, and DevOps tools.

## Features

- 🚀 **Automated Installation**: Install complete development environments with a single command
- 📦 **Multiple Package Managers**: Supports winget (preferred), Chocolatey, PowerShell Gallery, VS Code extensions
- 🎯 **Modular Stacks**: Choose from pre-configured stacks or create custom configurations
- 🔄 **Idempotent**: Safe to run multiple times without breaking existing installations
- 📝 **Comprehensive Logging**: Detailed logs with color-coded console output
- 🧪 **Dry Run Mode**: Preview changes before installation with `-whatif`
- ⚡ **Force Install**: Update existing packages with `-force_installs`
- 🌐 **WSL Support**: Automated WSL setup with Ubuntu LTS

## Quick Start

### Option 1: Bootstrap from Scratch

If you're starting fresh and don't have Git installed:

```powershell
# Download the bootstrap script
# Run PowerShell as Administrator
.\scripts\bootstrap.ps1
```

The bootstrap script will:
1. Check execution policy
2. Install Git if missing
3. Help you clone this repository
4. Guide you through next steps

### Option 2: Clone and Install

If you already have Git:

```powershell
# Clone the repository
git clone <repository-url> C:\repos\win-dev-setup
cd C:\repos\win-dev-setup

# Install foundation stack (VS Code, Git, terminal tools)
.\install.ps1 -stacks foundation

# Install multiple stacks
.\install.ps1 -stacks foundation,python,docker
```

## Available Stacks

| Stack | Description | Key Tools |
|-------|-------------|-----------|
| **foundation** | Core development tools | VS Code, Git, PowerShell 7, Windows Terminal |
| **java** | Java development | JDK 21, Maven, Gradle, IntelliJ IDEA Community |
| **python** | Python development | Python 3.12, VS Code extensions, Jupyter |
| **dotnet** | .NET development | .NET 8 SDK, C# Dev Kit |
| **docker** | Container development | WSL, Docker Desktop, container tools |
| **devops** | Cloud & DevOps tools | Azure CLI, Terraform, kubectl, Helm |

## Usage Examples

### Basic Installation

```powershell
# Install foundation stack
.\install.ps1 -stacks foundation

# Install multiple stacks
.\install.ps1 -stacks foundation,java,python
```

### Advanced Options

```powershell
# Dry run - see what would be installed
.\install.ps1 -stacks foundation -whatif

# Force reinstall/update all packages
.\install.ps1 -stacks python -force_installs

# Install latest versions (ignore version pins)
.\install.ps1 -stacks foundation,devops -latest_everything

# Quiet mode (minimal console output)
.\install.ps1 -stacks dotnet -quiet

# Custom configuration file
.\install.ps1 -config_path "C:\my-configs\custom.yaml"
```

### View Available Options

```powershell
# Run without parameters to see help
.\install.ps1

# Get detailed help
Get-Help .\install.ps1 -Detailed
```

## Configuration Files

Configuration files are located in `configs/defaults/` and use YAML format:

```yaml
packages:
  - name: Git.Git              # Package identifier
    install: true              # Enable/disable
    version: latest            # Version or "latest"
    pkgmgr: winget            # Package manager
    description: "Version control system"
```

### Supported Package Managers

- **winget**: Windows Package Manager (preferred, default)
- **choco**: Chocolatey (automatic fallback when package not in winget)
- **pwsh**: PowerShell Gallery modules
- **vscode**: VS Code extensions
- **apt**: Ubuntu/Debian (for use inside WSL)

### Creating Custom Configurations

1. Copy the template:
   ```powershell
   Copy-Item configs\examples\custom-template.yaml my-custom-config.yaml
   ```

2. Edit `my-custom-config.yaml` to add your packages

3. Run with custom config:
   ```powershell
   .\install.ps1 -config_path .\my-custom-config.yaml
   ```

## WSL and Docker Setup

The Docker stack includes WSL installation. After installation:

1. **Restart your computer** if prompted by WSL installation

2. **Install Ubuntu** (latest LTS):
   ```powershell
   wsl --install -d Ubuntu
   ```

3. **Configure Docker Desktop**:
   - Open Docker Desktop
   - Go to Settings > General
   - Enable "Use the WSL 2 based engine"
   - Go to Settings > Resources > WSL Integration
   - Enable integration with Ubuntu

4. **Install tools inside WSL**:
   ```bash
   # Open WSL Ubuntu terminal
   cd /mnt/c/Users/<your-username>/repos/win-dev-setup
   
   # Install PowerShell in WSL (if not already installed)
   sudo apt update
   sudo apt install -y wget apt-transport-https software-properties-common
   
   # Download PowerShell package
   wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb
   sudo dpkg -i packages-microsoft-prod.deb
   sudo apt update
   sudo apt install -y powershell
   
   # Run install script in WSL
   pwsh ./install.ps1 -stacks <your-stacks>
   ```

## Prerequisites

### System Requirements
- **OS**: Windows 10 (build 19041+) or Windows 11
- **PowerShell**: 5.1 or later (PowerShell 7+ recommended)
- **Internet**: Active internet connection
- **Disk Space**: Varies by stack (minimum 5GB recommended)

### Permissions
- Most installations work without admin privileges
- Some packages require administrator rights:
  - Chocolatey installation
  - System-wide tool installations
  - WSL installation

### Execution Policy

The script checks execution policy automatically. If you encounter issues:

```powershell
# For current user (recommended)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or system-wide (requires admin)
Set-ExecutionPolicy RemoteSigned -Scope LocalMachine
```

## Logging

All operations are logged to a timestamped file in `$env:TEMP`:

```
C:\Users\<username>\AppData\Local\Temp\win-dev-setup-20251219-143022.log
```

The log file location is displayed at the start of execution and in the final summary.

### Log Levels

- **[INFO]**: General information (Cyan)
- **[SUCCESS]**: Successful operations (Green)
- **[WARNING]**: Non-critical issues (Yellow)
- **[ERROR]**: Critical failures (Red)
- **[PACKAGE]**: Package installation status (color-coded by status)

## Troubleshooting

### Common Issues

**1. Execution Policy Errors**
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**2. winget Not Found**
- winget comes pre-installed on Windows 11
- For Windows 10, install from: https://aka.ms/getwinget
- Script will automatically fall back to Chocolatey if winget unavailable

**3. Permission Denied**
- Run PowerShell as Administrator for system-level installations
- Or install to user scope when possible

**4. Package Installation Fails**
- Check the log file for detailed error messages
- Verify internet connectivity
- Try running with `-force_installs` flag
- Check if package name is correct for the package manager

**5. VS Code Extensions Not Installing**
- Ensure VS Code is installed first (included in foundation stack)
- Restart terminal after VS Code installation
- VS Code must be in PATH (automatic during installation)

### Getting Help

1. **Check the logs**: Review detailed error messages in log file
2. **Run with -whatif**: Preview what will be installed
3. **Test prerequisites**: Run `.\install.ps1` without parameters to check system readiness
4. **Manual installation**: If automated installation fails, install packages manually and update config to `install: false`

## Project Structure

```
win-dev-setup/
├── install.ps1                     # Main installation script
├── modules/                        # PowerShell modules
│   ├── logger.psm1                # Logging functionality
│   ├── config-loader.psm1         # YAML configuration parsing
│   ├── validator.psm1             # System validation checks
│   └── package-manager.psm1       # Package installation logic
├── configs/
│   ├── defaults/                  # Pre-configured stacks
│   │   ├── foundation.yaml
│   │   ├── java.yaml
│   │   ├── python.yaml
│   │   ├── dotnet.yaml
│   │   ├── docker.yaml
│   │   └── devops.yaml
│   └── examples/
│       └── custom-template.yaml   # Template for custom configs
├── scripts/
│   └── bootstrap.ps1              # Standalone bootstrap script
├── tests/
│   └── manual-test-checklist.md   # Manual testing guide
├── README.md                       # This file
└── REQUIREMENTS.md                 # Project requirements document
```

## For Developers

### Contributing

Contributions are welcome! To contribute:

1. **Fork the repository**
2. **Create a feature branch**
   ```powershell
   git checkout -b feature/my-new-feature
   ```
3. **Make your changes**
4. **Test thoroughly** (see Testing section below)
5. **Commit with clear messages**
   ```powershell
   git commit -m "Add feature: description"
   ```
6. **Push and create Pull Request**

### Code Style Guidelines

- **Naming conventions**:
  - All file names: lowercase with hyphens (e.g., `install.ps1`)
  - Functions: lowercase with hyphens (e.g., `write-log-info`)
  - Variables: UPPER_CASE or with underscores (e.g., `$PACKAGE_NAME`, `$install_path`)
  - No CamelCase

- **Comments**:
  - Document flow of script with inline comments
  - Explain complex business logic
  - Include SYNOPSIS blocks for all functions

- **Error handling**:
  - Use try/catch for operations that may fail
  - Log errors with meaningful messages
  - Continue processing when safe, fail fast when critical

### Module Development

Each module should:
- Be self-contained with clear responsibilities
- Export only necessary functions
- Include comprehensive documentation
- Import required dependencies

### Adding New Packages

To add packages to existing stacks:

1. **Edit the appropriate YAML file** in `configs/defaults/`
2. **Add package entry** with required fields:
   ```yaml
   - name: PackageIdentifier
     install: true
     version: latest
     pkgmgr: winget
     description: "Package description"
   ```
3. **Test the configuration**:
   ```powershell
   .\install.ps1 -stacks <stack-name> -whatif
   ```

### Creating New Stacks

1. **Create new YAML file** in `configs/defaults/`:
   ```powershell
   New-Item configs\defaults\mystack.yaml
   ```

2. **Add packages** following the template format

3. **Update README** to document the new stack

4. **Update install.ps1** ValidateSet for `-stacks` parameter

### Testing

#### Manual Testing

Use the manual test checklist:
```powershell
# See tests/manual-test-checklist.md
```

#### Test on Clean VM

Best practice is to test on a fresh Windows 11 installation:

1. **Create Windows 11 VM** (Hyper-V, VirtualBox, or Azure)
2. **Take snapshot** before testing
3. **Run bootstrap**:
   ```powershell
   .\scripts\bootstrap.ps1
   ```
4. **Run installation**:
   ```powershell
   .\install.ps1 -stacks foundation
   ```
5. **Verify installations** manually
6. **Check logs** for errors
7. **Test with different stack combinations**
8. **Restore snapshot** for clean state

#### Dry Run Testing

Always test with `-whatif` first:
```powershell
.\install.ps1 -stacks foundation,python,docker -whatif
```

### Debugging

Enable verbose logging:
```powershell
$VerbosePreference = 'Continue'
.\install.ps1 -stacks foundation -Verbose
```

Check module functions directly:
```powershell
Import-Module .\modules\logger.psm1 -Force
initialize-logger
write-log-info "Test message"
```

## Command-Line Reference

### install.ps1 Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `-stacks` | String[] | Stack names to install (foundation, java, python, dotnet, docker, devops) |
| `-config_path` | String | Path to custom YAML configuration file |
| `-force_installs` | Switch | Force reinstallation/update of packages |
| `-latest_everything` | Switch | Install latest versions (ignore version pins) |
| `-whatif` | Switch | Dry run mode - preview without installing |
| `-quiet` | Switch | Suppress console output (logging continues) |

### bootstrap.ps1 Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `-skip_git_install` | Switch | Skip automatic Git installation |
| `-skip_repo_clone` | Switch | Skip repository cloning prompt |

## License

See [LICENSE](LICENSE) file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and changes.

## Support

- **Issues**: Report bugs and feature requests via GitHub Issues
- **Discussions**: Ask questions in GitHub Discussions
- **Documentation**: See [REQUIREMENTS.md](REQUIREMENTS.md) for detailed requirements

---

**Note**: This tool is provided as-is. Always review what will be installed and test in a safe environment before running on production machines.
