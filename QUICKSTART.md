# Quick Start Guide

## For First-Time Users

### Step 1: Get Started
```powershell
# Option A: If you don't have Git
.\scripts\bootstrap.ps1

# Option B: If you have Git
git clone <repo-url> C:\repos\win-dev-setup
cd C:\repos\win-dev-setup
```

### Step 2: Choose Your Stack
```powershell
# See what's available
.\install.ps1

# Install foundation (recommended first step)
.\install.ps1 -stacks foundation
```

### Step 3: Add More Tools
```powershell
# Add development stacks as needed
.\install.ps1 -stacks java,python
```

## Common Commands

```powershell
# Dry run (preview without installing)
.\install.ps1 -stacks foundation -whatif

# Force update all packages
.\install.ps1 -stacks foundation -force_installs

# Install latest versions (ignore pins)
.\install.ps1 -stacks devops -latest_everything

# Quiet mode
.\install.ps1 -stacks python -quiet

# Custom configuration
.\install.ps1 -config_path .\my-config.yaml
```

## Stacks Available

- **foundation** - Start here! Git, VS Code, terminal
- **java** - JDK, Maven, Gradle, IntelliJ
- **python** - Python 3.12, Jupyter, VS Code extensions
- **dotnet** - .NET 8 SDK, C# tools
- **docker** - WSL, Docker Desktop, container tools
- **devops** - Azure CLI, Terraform, kubectl

## Troubleshooting

**Execution Policy Error?**
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Need Admin Rights?**
- Right-click PowerShell, "Run as Administrator"

**Check Logs**
- Located in: `$env:TEMP\win-dev-setup-*.log`

## Need Help?

- Run `.\install.ps1` (no parameters) for guidance
- See [README.md](README.md) for full documentation
- Check [tests/manual-test-checklist.md](tests/manual-test-checklist.md) for testing guide
