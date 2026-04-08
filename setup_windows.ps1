# =============================================================================
# Windows Python Development Environment Setup
# =============================================================================
# This script sets up a complete Python development environment on Windows.
# It is idempotent -- safe to run multiple times.
#
# What it installs:
#   - Git (version control) + HTTPS credential manager
#   - Python 3.12 (via winget or python.org)
#   - pipx (for globally-installed CLI tools)
#   - Dev tools: black, ruff, mypy (via pipx)
#   - VS Code (editor) + Python extensions
#   - A Python virtual environment with common packages
#
# Usage:
#   Open PowerShell as Administrator, then run:
#     Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
#     .\setup_windows.ps1
# =============================================================================

$ErrorActionPreference = "Stop"

$PYTHON_VERSION = "3.12"
$VENV_DIR = "venv"

# -----------------------------------------------------------------------------
# Helper functions
# -----------------------------------------------------------------------------
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] " -ForegroundColor Blue -NoNewline
    Write-Host $Message
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] " -ForegroundColor Green -NoNewline
    Write-Host $Message
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] " -ForegroundColor Yellow -NoNewline
    Write-Host $Message
}

function Write-Err {
    param([string]$Message)
    Write-Host "[ERROR] " -ForegroundColor Red -NoNewline
    Write-Host $Message
}

function Test-CommandExists {
    param([string]$Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

function Refresh-PathEnv {
    # Reload PATH from the registry so newly installed tools are visible
    $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machinePath;$userPath"
}

# -----------------------------------------------------------------------------
# 1. winget (Windows Package Manager)
# -----------------------------------------------------------------------------
function Install-Winget {
    if (Test-CommandExists "winget") {
        Write-Success "winget is already available."
    }
    else {
        Write-Err "winget is not available on this system."
        Write-Err "winget is included with Windows 10 (1709+) and Windows 11."
        Write-Err "Install it from the Microsoft Store (App Installer) or:"
        Write-Err "  https://github.com/microsoft/winget-cli/releases"
        exit 1
    }
}

# -----------------------------------------------------------------------------
# 2. Git
# -----------------------------------------------------------------------------
function Install-Git {
    if (Test-CommandExists "git") {
        $gitVer = git --version
        Write-Success "Git is already installed ($gitVer)."
    }
    else {
        Write-Info "Installing Git..."
        winget install --id Git.Git --exact --accept-source-agreements --accept-package-agreements
        Refresh-PathEnv
        Write-Success "Git installed."
    }
}

function Configure-Git {
    $currentName = git config --global user.name 2>$null
    $currentEmail = git config --global user.email 2>$null

    if ([string]::IsNullOrWhiteSpace($currentName)) {
        $gitName = Read-Host "Enter your Git name (e.g., John Doe)"
        git config --global user.name "$gitName"
        Write-Success "Git name set to: $gitName"
    }
    else {
        Write-Success "Git name already configured: $currentName"
    }

    if ([string]::IsNullOrWhiteSpace($currentEmail)) {
        $gitEmail = Read-Host "Enter your Git email"
        git config --global user.email "$gitEmail"
        Write-Success "Git email set to: $gitEmail"
    }
    else {
        Write-Success "Git email already configured: $currentEmail"
    }

    # Set useful defaults
    git config --global init.defaultBranch main
    git config --global pull.rebase false
    git config --global core.autocrlf true

    # Git Credential Manager is bundled with Git for Windows
    git config --global credential.helper manager

    Write-Success "Git configured (HTTPS with Credential Manager)."
}

# -----------------------------------------------------------------------------
# 3. Python
# -----------------------------------------------------------------------------
function Install-Python {
    # Check if a suitable Python version is already installed
    $pythonCmd = $null

    if (Test-CommandExists "python") {
        $pyVer = python --version 2>&1
        if ($pyVer -match "$PYTHON_VERSION") {
            Write-Success "Python is already installed ($pyVer)."
            $pythonCmd = "python"
        }
    }

    if ($null -eq $pythonCmd -and (Test-CommandExists "python3")) {
        $pyVer = python3 --version 2>&1
        if ($pyVer -match "$PYTHON_VERSION") {
            Write-Success "Python is already installed ($pyVer)."
            $pythonCmd = "python3"
        }
    }

    if ($null -eq $pythonCmd) {
        Write-Info "Installing Python ${PYTHON_VERSION}..."
        winget install --id Python.Python.${PYTHON_VERSION} --exact --accept-source-agreements --accept-package-agreements
        Refresh-PathEnv
        Write-Success "Python ${PYTHON_VERSION} installed."
    }

    # Verify Python is accessible
    Refresh-PathEnv
    if (Test-CommandExists "python") {
        $pyVer = python --version 2>&1
        Write-Success "Python available: $pyVer"
    }
    elseif (Test-CommandExists "python3") {
        $pyVer = python3 --version 2>&1
        Write-Success "Python available: $pyVer"
    }
    else {
        Write-Err "Python is not on PATH. You may need to restart your terminal."
        Write-Err "Check 'Add Python to PATH' in your Python installation settings."
    }
}

function Get-PythonCommand {
    # Return the correct python command (python vs python3)
    if (Test-CommandExists "python") {
        return "python"
    }
    elseif (Test-CommandExists "python3") {
        return "python3"
    }
    else {
        Write-Err "Python not found on PATH."
        exit 1
    }
}

# -----------------------------------------------------------------------------
# 4. pip + pipx
# -----------------------------------------------------------------------------
function Upgrade-Pip {
    $py = Get-PythonCommand
    Write-Info "Upgrading pip..."
    & $py -m pip install --upgrade pip --quiet 2>$null
    $pipVer = & $py -m pip --version
    Write-Success "pip upgraded ($pipVer)."
}

function Install-Pipx {
    if (Test-CommandExists "pipx") {
        Write-Success "pipx is already installed."
    }
    else {
        $py = Get-PythonCommand
        Write-Info "Installing pipx..."
        & $py -m pip install --user pipx --quiet
        & $py -m pipx ensurepath
        Refresh-PathEnv
        Write-Success "pipx installed."
    }
}

# -----------------------------------------------------------------------------
# 5. Dev tools (installed globally via pipx)
# -----------------------------------------------------------------------------
function Install-DevTools {
    Write-Info "Installing dev tools via pipx..."

    $tools = @("black", "ruff", "mypy")

    foreach ($tool in $tools) {
        $pipxList = pipx list 2>$null
        if ($pipxList -match "package $tool") {
            Write-Success "$tool is already installed via pipx."
        }
        else {
            Write-Info "Installing $tool..."
            pipx install $tool 2>$null
            Write-Success "$tool installed."
        }
    }
}

# -----------------------------------------------------------------------------
# 6. VS Code
# -----------------------------------------------------------------------------
function Install-VSCode {
    if (Test-CommandExists "code") {
        Write-Success "VS Code is already installed."
    }
    else {
        Write-Info "Installing Visual Studio Code..."
        winget install --id Microsoft.VisualStudioCode --exact --accept-source-agreements --accept-package-agreements
        Refresh-PathEnv
        Write-Success "VS Code installed."
    }
}

function Install-VSCodeExtensions {
    if (-not (Test-CommandExists "code")) {
        Write-Warn "VS Code CLI not found. Skipping extension installation."
        Write-Warn "Restart your terminal, then run this script again to install extensions."
        return
    }

    Write-Info "Installing VS Code extensions..."

    $extensions = @(
        "ms-python.python",
        "ms-python.vscode-pylance",
        "ms-python.black-formatter",
        "charliermarsh.ruff",
        "ms-python.mypy-type-checker",
        "EditorConfig.EditorConfig"
    )

    $installed = code --list-extensions 2>$null

    foreach ($ext in $extensions) {
        if ($installed -match ($ext -replace '\.', '\.')) {
            Write-Success "Extension $ext is already installed."
        }
        else {
            Write-Info "Installing extension: $ext"
            code --install-extension $ext --force 2>$null
        }
    }

    Write-Success "VS Code extensions installed."
}

# -----------------------------------------------------------------------------
# 7. Virtual environment + packages
# -----------------------------------------------------------------------------
function Setup-VirtualEnv {
    $scriptDir = Split-Path -Parent $MyInvocation.ScriptName
    if ([string]::IsNullOrWhiteSpace($scriptDir)) {
        $scriptDir = $PSScriptRoot
    }
    if ([string]::IsNullOrWhiteSpace($scriptDir)) {
        $scriptDir = Get-Location
    }

    $venvPath = Join-Path $scriptDir $VENV_DIR
    $py = Get-PythonCommand

    if (Test-Path $venvPath) {
        Write-Success "Virtual environment already exists at $venvPath"
    }
    else {
        Write-Info "Creating virtual environment..."
        & $py -m venv $venvPath
        Write-Success "Virtual environment created at $venvPath"
    }

    # Activate the virtual environment
    $activateScript = Join-Path $venvPath "Scripts\Activate.ps1"
    if (Test-Path $activateScript) {
        Write-Info "Activating virtual environment..."
        & $activateScript
    }
    else {
        Write-Warn "Could not find activation script. Continuing without activation."
    }

    # Upgrade pip inside venv
    Write-Info "Upgrading pip inside virtual environment..."
    & $py -m pip install --upgrade pip --quiet 2>$null

    # Install requirements
    $reqFile = Join-Path $scriptDir "requirements.txt"
    if (Test-Path $reqFile) {
        Write-Info "Installing packages from requirements.txt..."
        & $py -m pip install -r $reqFile --quiet
        Write-Success "Packages installed from requirements.txt."
    }
    else {
        Write-Warn "No requirements.txt found. Skipping package installation."
    }

    # Install dev requirements
    $reqDevFile = Join-Path $scriptDir "requirements-dev.txt"
    if (Test-Path $reqDevFile) {
        Write-Info "Installing dev packages from requirements-dev.txt..."
        & $py -m pip install -r $reqDevFile --quiet
        Write-Success "Dev packages installed from requirements-dev.txt."
    }
}

# =============================================================================
# Main
# =============================================================================
function Main {
    Write-Host ""
    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host "  Windows Python Dev Environment Setup" -ForegroundColor Cyan
    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host ""

    Install-Winget
    Write-Host ""

    Install-Git
    Configure-Git
    Write-Host ""

    Install-Python
    Write-Host ""

    Upgrade-Pip
    Install-Pipx
    Write-Host ""

    Install-DevTools
    Write-Host ""

    Install-VSCode
    Install-VSCodeExtensions
    Write-Host ""

    Setup-VirtualEnv
    Write-Host ""

    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host "  Setup complete!" -ForegroundColor Green
    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host ""

    $py = Get-PythonCommand
    $pyVer = & $py --version 2>&1
    $gitVer = git --version 2>&1

    Write-Host "  Python:  $pyVer"
    Write-Host "  Git:     $gitVer"
    Write-Host ""
    Write-Host "  To activate the virtual environment:"
    Write-Host "    .\venv\Scripts\Activate.ps1"
    Write-Host ""
    Write-Host "  NOTE: You may need to restart your terminal"
    Write-Host "  for all PATH changes to take effect."
    Write-Host ""
}

Main
