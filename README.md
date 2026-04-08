# Python Dev Environment Setup

Automated setup scripts for a complete Python development environment on **macOS** and **Windows**. Run one script on a fresh machine and get Git, Python (via pyenv), VS Code, dev tools, and a virtual environment with common packages -- ready to go.

## What Gets Installed

| Tool | macOS | Windows | Purpose |
|---|---|---|---|
| **Git** | Homebrew | winget | Version control |
| **Git Credential Manager** | Homebrew cask | Bundled with Git | HTTPS auth for GitHub |
| **pyenv** | Homebrew | -- | Python version management |
| **Python 3.12** | pyenv | winget | Python runtime |
| **pip** | upgraded | upgraded | Package installer |
| **pipx** | Homebrew | pip | Global CLI tool installer |
| **black** | pipx | pipx | Code formatter |
| **ruff** | pipx | pipx | Linter (replaces pylint/flake8) |
| **mypy** | pipx | pipx | Type checker |
| **VS Code** | Homebrew cask | winget | Code editor |
| **VS Code extensions** | CLI | CLI | Python, Pylance, Black, Ruff, mypy, EditorConfig |
| **Virtual environment** | `python -m venv` | `python -m venv` | Isolated package environment |

## Prerequisites

### macOS
- macOS 10.15 (Catalina) or later
- Internet connection
- Terminal access

### Windows
- Windows 10 (1709+) or Windows 11
- Internet connection
- PowerShell 5.1 or later
- [winget](https://github.com/microsoft/winget-cli) (pre-installed on Windows 11, available via App Installer on Windows 10)

## Usage

### macOS

```bash
# Clone the repository
git clone https://github.com/RyanSchlenz/python_setup.git
cd python_setup

# Make the script executable and run it
chmod +x setup_macos.sh
./setup_macos.sh
```

After the script completes, restart your terminal (or run `source ~/.zshrc`) so that pyenv is available in new shells.

### Windows

```powershell
# Clone the repository
git clone https://github.com/RyanSchlenz/python_setup.git
cd python_setup

# Allow script execution (one-time, if not already set)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Run the setup script
.\setup_windows.ps1
```

After the script completes, you may need to restart your terminal for all PATH changes to take effect.

## Activating the Virtual Environment

Both scripts create a `venv/` directory with all packages from `requirements.txt` and `requirements-dev.txt` pre-installed.

```bash
# macOS / Linux
source venv/bin/activate

# Windows (PowerShell)
.\venv\Scripts\Activate.ps1

# Windows (Command Prompt)
.\venv\Scripts\activate.bat
```

## File Structure

```
python_setup/
├── setup_macos.sh          # macOS setup script
├── setup_windows.ps1       # Windows setup script
├── requirements.txt        # Core Python packages
├── requirements-dev.txt    # Dev/quality tools (pytest, black, ruff, mypy)
├── .editorconfig           # Editor formatting rules
├── .gitignore              # Git ignore patterns
├── vscode/
│   └── extensions.json     # Recommended VS Code extensions
└── README.md               # This file
```

## Packages Installed

### Core (`requirements.txt`)

| Package | Purpose |
|---|---|
| `pandas` | Data analysis and manipulation |
| `numpy` | Numerical computing |
| `requests` | HTTP client for APIs |
| `python-dotenv` | Load environment variables from `.env` files |
| `python-dateutil` | Date/time utilities |
| `PyYAML` | YAML parsing |
| `openpyxl` | Excel file read/write |
| `SQLAlchemy` | SQL database toolkit |

### Dev Tools (`requirements-dev.txt`)

| Package | Purpose |
|---|---|
| `pytest` | Testing framework |
| `pytest-cov` | Test coverage reporting |
| `black` | Code formatter |
| `ruff` | Fast linter (replaces pylint, flake8, isort) |
| `mypy` | Static type checker |
| `pre-commit` | Git pre-commit hook framework |

## Customization

### Change Python version

Edit the version variable at the top of the setup script:

```bash
# setup_macos.sh
PYTHON_VERSION="3.13"
```

```powershell
# setup_windows.ps1
$PYTHON_VERSION = "3.13"
```

### Add project-specific packages

Add them to `requirements.txt` before running the setup script, or install them after setup:

```bash
source venv/bin/activate
pip install <package-name>
```

## Troubleshooting

### macOS: `pyenv: command not found` after install

Restart your terminal or run:

```bash
source ~/.zshrc
```

### macOS: Python build fails via pyenv

Install Xcode Command Line Tools:

```bash
xcode-select --install
```

### Windows: `winget` not found

Install "App Installer" from the Microsoft Store, or download the latest release from [winget-cli releases](https://github.com/microsoft/winget-cli/releases).

### Windows: PowerShell script execution is disabled

Run this once in an elevated PowerShell:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Windows: `python` not found after install

Ensure Python was added to PATH. You can re-run the Python installer from winget:

```powershell
winget install --id Python.Python.3.12 --exact
```

Or add Python manually to your PATH via System Environment Variables.

### VS Code extensions not installing

If `code` is not on your PATH:
- **macOS**: Open VS Code, press `Cmd+Shift+P`, type "Shell Command: Install 'code' command in PATH"
- **Windows**: Re-run the VS Code installer and check "Add to PATH"

## Re-running the Scripts

Both scripts are idempotent -- they check for existing installations before installing anything. It is safe to run them multiple times.
