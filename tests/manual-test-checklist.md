# Manual Test Checklist for win-dev-setup

This checklist provides a comprehensive testing guide for the Windows development environment setup tool. Use this on a fresh Windows 11 VM to ensure all functionality works correctly.

## Test Environment Setup

### Prerequisites
- [ ] Fresh Windows 11 installation (or Windows 10 build 19041+)
- [ ] VM snapshot taken before testing (to restore for clean runs)
- [ ] Internet connection active
- [ ] At least 20GB free disk space

## Phase 1: Bootstrap Testing

### Test 1.1: Bootstrap Script - Clean Install
**Objective**: Verify bootstrap.ps1 works on a system without Git

- [ ] Start with fresh VM (no Git installed)
- [ ] Open PowerShell (do NOT use admin)
- [ ] Run: `.\scripts\bootstrap.ps1`
- [ ] Verify execution policy check passes or provides guidance
- [ ] Verify admin privilege check shows warning (if not admin)
- [ ] Verify Git gets installed via winget
- [ ] Verify Git command becomes available

**Expected Results**:
- Clear, color-coded console output
- Git successfully installed
- No errors or exceptions
- Helpful next steps displayed

### Test 1.2: Bootstrap Script - With Git Already Installed
**Objective**: Verify idempotent behavior

- [ ] Run: `.\scripts\bootstrap.ps1` again
- [ ] Verify script detects Git is already installed
- [ ] Verify no duplicate installation attempted
- [ ] Verify script completes without errors

**Expected Results**:
- Script recognizes Git is present
- Skips installation
- No errors

### Test 1.3: Bootstrap Script - Execution Policy Restricted
**Objective**: Test execution policy handling

- [ ] Set restrictive policy: `Set-ExecutionPolicy Restricted -Scope CurrentUser`
- [ ] Try to run: `.\scripts\bootstrap.ps1`
- [ ] Verify clear error message
- [ ] Verify guidance provided to fix policy

**Expected Results**:
- Script fails gracefully
- Provides specific fix command
- No cryptic errors

**Cleanup**: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`

## Phase 2: Prerequisite Validation Testing

### Test 2.1: Prerequisite Validation - Normal User
**Objective**: Test validation without admin privileges

- [ ] Open PowerShell as normal user
- [ ] Run: `.\install.ps1` (no parameters)
- [ ] Verify Windows version check passes
- [ ] Verify execution policy check passes
- [ ] Verify admin check shows warning (not error)
- [ ] Verify winget availability check

**Expected Results**:
- All validations run
- Warnings (not errors) for non-admin
- Available stacks displayed
- Instructions shown for next steps

### Test 2.2: Prerequisite Validation - Administrator
**Objective**: Test validation with admin privileges

- [ ] Open PowerShell as Administrator
- [ ] Run: `.\install.ps1` (no parameters)
- [ ] Verify admin privilege check shows success

**Expected Results**:
- Admin privileges detected
- All validations pass
- No warnings about permissions

## Phase 3: Installation Testing - Foundation Stack

### Test 3.1: Dry Run Mode
**Objective**: Verify -whatif parameter works correctly

- [ ] Run: `.\install.ps1 -stacks foundation -whatif`
- [ ] Verify no actual installations occur
- [ ] Verify all packages are listed with [WHATIF] markers
- [ ] Verify log file is created
- [ ] Check log file contains dry run information

**Expected Results**:
- No packages installed
- Clear preview of what would be installed
- Log file created
- No system changes

### Test 3.2: Foundation Stack - Full Install
**Objective**: Install foundation development stack

- [ ] Run: `.\install.ps1 -stacks foundation`
- [ ] Monitor console output for package status
- [ ] Verify color-coded output (cyan, green, yellow, red)
- [ ] Wait for completion
- [ ] Check final summary

**Expected Results**:
- Git installed (or already installed)
- VS Code installed
- Windows Terminal installed
- PowerShell 7 installed
- VS Code extensions installed
- Log file created with detailed information
- Success count matches expected package count
- Zero failures

**Post-Install Verification**:
- [ ] Run: `git --version`
- [ ] Run: `code --version`
- [ ] Open Windows Terminal from Start menu
- [ ] Open PowerShell 7 (`pwsh`)
- [ ] Launch VS Code, check extensions are installed

### Test 3.3: Foundation Stack - Idempotent Re-run
**Objective**: Verify safe to run multiple times

- [ ] Run: `.\install.ps1 -stacks foundation` again
- [ ] Verify packages detected as already installed
- [ ] Verify no errors occur
- [ ] Verify quick completion (packages skipped)

**Expected Results**:
- Packages detected as installed
- "Already Installed" status shown
- No actual installations attempted
- No errors

### Test 3.4: Foundation Stack - Force Reinstall
**Objective**: Test -force_installs parameter

- [ ] Run: `.\install.ps1 -stacks foundation -force_installs`
- [ ] Verify packages get reinstalled/updated
- [ ] Monitor for any errors

**Expected Results**:
- Packages reinstalled
- Updates applied if available
- Completes successfully

## Phase 4: Installation Testing - Other Stacks

### Test 4.1: Java Stack
- [ ] Run: `.\install.ps1 -stacks java -whatif` (preview)
- [ ] Run: `.\install.ps1 -stacks java`
- [ ] Verify JDK installed: `java --version`
- [ ] Verify Maven installed: `mvn --version`
- [ ] Verify Gradle installed: `gradle --version`
- [ ] Verify IntelliJ IDEA Community installed
- [ ] Open VS Code and verify Java extensions installed

### Test 4.2: Python Stack
- [ ] Run: `.\install.ps1 -stacks python`
- [ ] Verify Python installed: `python --version`
- [ ] Verify pip works: `pip --version`
- [ ] Open VS Code and verify Python extensions installed
- [ ] Test Jupyter support in VS Code

### Test 4.3: .NET Stack
- [ ] Run: `.\install.ps1 -stacks dotnet`
- [ ] Verify .NET SDK installed: `dotnet --version`
- [ ] Run: `dotnet --list-sdks`
- [ ] Open VS Code and verify C# extensions installed

### Test 4.4: Docker Stack
**Note**: This may require system restart

- [ ] Run: `.\install.ps1 -stacks docker`
- [ ] Verify WSL installed: `wsl --status`
- [ ] Restart computer if prompted
- [ ] Verify Docker Desktop installed and running
- [ ] Open VS Code and verify Docker extensions installed

**Post-Restart**:
- [ ] Install Ubuntu: `wsl --install -d Ubuntu`
- [ ] Configure Ubuntu
- [ ] Verify Docker Desktop integrates with WSL
- [ ] Test: `docker --version`

### Test 4.5: DevOps Stack
- [ ] Run: `.\install.ps1 -stacks devops`
- [ ] Verify Azure CLI: `az --version`
- [ ] Verify Terraform: `terraform --version`
- [ ] Verify kubectl: `kubectl version --client`
- [ ] Verify Helm: `helm version`
- [ ] Verify GitHub CLI: `gh --version`
- [ ] Check PowerShell modules: `Get-Module -ListAvailable Az`

### Test 4.6: Multiple Stacks
- [ ] Run: `.\install.ps1 -stacks foundation,python,java`
- [ ] Verify all packages from all stacks installed
- [ ] Check for conflicts or errors
- [ ] Verify total package count correct

## Phase 5: Advanced Features Testing

### Test 5.1: Custom Configuration File
- [ ] Copy: `configs\examples\custom-template.yaml` to `test-custom.yaml`
- [ ] Edit `test-custom.yaml` with a few packages
- [ ] Run: `.\install.ps1 -config_path .\test-custom.yaml`
- [ ] Verify only specified packages installed

**Expected Results**:
- Custom config loaded
- Only enabled packages installed
- Disabled packages skipped

### Test 5.2: Latest Everything Mode
- [ ] Run: `.\install.ps1 -stacks foundation -latest_everything`
- [ ] Verify version specifications ignored
- [ ] Verify latest versions installed

### Test 5.3: Quiet Mode
- [ ] Run: `.\install.ps1 -stacks foundation -quiet`
- [ ] Verify minimal console output
- [ ] Verify log file still created
- [ ] Check log file has full details

**Expected Results**:
- Console shows minimal output
- Errors still displayed
- Log file complete

### Test 5.4: Package Manager Fallback
- [ ] Temporarily disable winget (rename winget.exe)
- [ ] Run: `.\install.ps1 -stacks foundation`
- [ ] Verify fallback to Chocolatey attempted
- [ ] Restore winget

**Expected Results**:
- Winget failure detected
- Automatic fallback to Chocolatey
- Warning messages logged

## Phase 6: Error Handling Testing

### Test 6.1: Invalid Stack Name
- [ ] Run: `.\install.ps1 -stacks invalidstack`
- [ ] Verify clear error message
- [ ] Verify available stacks listed

### Test 6.2: Missing Configuration File
- [ ] Delete a config file (e.g., `configs\defaults\foundation.yaml`)
- [ ] Run: `.\install.ps1 -stacks foundation`
- [ ] Verify clear error message
- [ ] Restore config file

### Test 6.3: Malformed YAML
- [ ] Edit `configs\defaults\foundation.yaml` to introduce syntax error
- [ ] Run: `.\install.ps1 -stacks foundation`
- [ ] Verify error caught and logged
- [ ] Fix YAML file

### Test 6.4: Network Failure Simulation
- [ ] Disable network connection
- [ ] Run: `.\install.ps1 -stacks foundation`
- [ ] Verify graceful failure
- [ ] Verify error messages helpful
- [ ] Re-enable network

### Test 6.5: Package Installation Failure
- [ ] Edit config to include non-existent package
- [ ] Run installation
- [ ] Verify script continues with other packages
- [ ] Verify failure logged
- [ ] Verify summary shows failure count

## Phase 7: Logging and Output Testing

### Test 7.1: Log File Creation
- [ ] Run any installation
- [ ] Verify log file created in `$env:TEMP`
- [ ] Check filename format: `win-dev-setup-YYYYMMDD-HHMMSS.log`
- [ ] Verify log file path displayed at start

### Test 7.2: Log File Content
- [ ] Open log file
- [ ] Verify timestamps on all entries
- [ ] Verify all log levels present (INFO, SUCCESS, WARNING, ERROR)
- [ ] Verify package installation details logged
- [ ] Verify start and end timestamps

### Test 7.3: Console Output Colors
- [ ] Run installation and observe console colors
- [ ] Verify INFO messages are cyan
- [ ] Verify SUCCESS messages are green
- [ ] Verify WARNING messages are yellow
- [ ] Verify ERROR messages are red

## Phase 8: WSL Integration Testing

### Test 8.1: WSL Installation via Docker Stack
- [ ] Fresh VM
- [ ] Run: `.\install.ps1 -stacks docker`
- [ ] Verify WSL installed
- [ ] Restart if needed
- [ ] Run: `wsl --install -d Ubuntu`
- [ ] Complete Ubuntu setup

### Test 8.2: PowerShell in WSL
- [ ] Open WSL Ubuntu terminal
- [ ] Install PowerShell in WSL (follow README instructions)
- [ ] Verify `pwsh` command works in WSL

### Test 8.3: Run install.ps1 in WSL
- [ ] In WSL, navigate to repo: `cd /mnt/c/Users/<user>/repos/win-dev-setup`
- [ ] Run: `pwsh ./install.ps1 -stacks foundation`
- [ ] Note: Some packages may not be applicable in WSL

## Phase 9: Module Testing

### Test 9.1: Logger Module
```powershell
Import-Module .\modules\logger.psm1 -Force
initialize-logger
write-log-info "Test info"
write-log-success "Test success"
write-log-warning "Test warning"
write-log-error "Test error"
write-log-package "test-pkg" "1.0.0" "Installing" "winget"
```
- [ ] Verify all functions work
- [ ] Verify colors display correctly
- [ ] Verify log file created

### Test 9.2: Config Loader Module
```powershell
Import-Module .\modules\config-loader.psm1 -Force
$config = load-yaml-config -config_path ".\configs\defaults\foundation.yaml"
$enabled = get-enabled-packages -config $config
```
- [ ] Verify YAML parsed correctly
- [ ] Verify packages loaded
- [ ] Verify validation works

### Test 9.3: Validator Module
```powershell
Import-Module .\modules\validator.psm1 -Force
test-is-admin
test-execution-policy
test-windows-version
test-winget-available
invoke-prerequisite-validation
```
- [ ] Verify all validation functions work
- [ ] Verify appropriate messages displayed

### Test 9.4: Package Manager Module
```powershell
Import-Module .\modules\package-manager.psm1 -Force
$pkg = @{ name = "7zip.7zip"; version = "latest"; pkgmgr = "winget" }
install-package -package $pkg -whatif
```
- [ ] Verify whatif mode works
- [ ] Test actual installation if desired

## Phase 10: Performance and Stress Testing

### Test 10.1: Large Installation
- [ ] Run: `.\install.ps1 -stacks foundation,java,python,dotnet,devops`
- [ ] Monitor installation time
- [ ] Verify no timeouts
- [ ] Verify no memory issues

**Record Results**:
- Total time: ______ minutes
- Total packages: ______
- Success count: ______
- Failure count: ______

### Test 10.2: Repeated Execution
- [ ] Run install script 3 times in succession
- [ ] Verify consistent behavior
- [ ] Verify no degradation
- [ ] Check for resource leaks

## Test Summary Template

```
Test Date: ______________
Tester: ______________
Windows Version: ______________
PowerShell Version: ______________

Phase 1 - Bootstrap: [ PASS / FAIL ]
Phase 2 - Prerequisites: [ PASS / FAIL ]
Phase 3 - Foundation Stack: [ PASS / FAIL ]
Phase 4 - Other Stacks: [ PASS / FAIL ]
Phase 5 - Advanced Features: [ PASS / FAIL ]
Phase 6 - Error Handling: [ PASS / FAIL ]
Phase 7 - Logging: [ PASS / FAIL ]
Phase 8 - WSL Integration: [ PASS / FAIL ]
Phase 9 - Module Testing: [ PASS / FAIL ]
Phase 10 - Performance: [ PASS / FAIL ]

Overall Result: [ PASS / FAIL ]

Issues Found:
1. ___________________________________
2. ___________________________________
3. ___________________________________

Notes:
_______________________________________
_______________________________________
```

## Known Limitations and Expected Behavior

- WSL installation may require system restart
- Some installations require admin privileges (script warns user)
- First-time Chocolatey installation requires admin
- VS Code extensions require VS Code to be installed first
- Network failures cause graceful degradation (some packages fail, others continue)
- Package names must exactly match package manager identifiers

## Regression Testing Checklist

When making code changes, re-run these critical tests:

- [ ] Bootstrap on clean VM
- [ ] Foundation stack installation
- [ ] Custom config file
- [ ] -whatif dry run mode
- [ ] Error handling (invalid stack name)
- [ ] Logging output verification
- [ ] Idempotent re-run

## Test Environment Cleanup

After testing:
- [ ] Review all log files for unexpected errors
- [ ] Document any issues found
- [ ] Restore VM to clean snapshot if needed
- [ ] Archive test results and logs
