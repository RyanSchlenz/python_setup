#!/bin/bash

# =============================================================================
# macOS Python Development Environment Setup
# =============================================================================
# This script sets up a complete Python development environment on macOS.
# It is idempotent -- safe to run multiple times.
#
# What it installs:
#   - Homebrew (package manager)
#   - Git (version control) + HTTPS credential manager
#   - pyenv (Python version manager)
#   - Python 3.12 (via pyenv)
#   - pipx (for globally-installed CLI tools)
#   - Dev tools: black, ruff, mypy (via pipx)
#   - VS Code (editor) + Python extensions
#   - A Python virtual environment with common packages
# =============================================================================

set -e

PYTHON_VERSION="3.12"
VENV_DIR="venv"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# -----------------------------------------------------------------------------
# 1. Homebrew
# -----------------------------------------------------------------------------
install_homebrew() {
    if command -v brew &> /dev/null; then
        success "Homebrew is already installed."
    else
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add Homebrew to PATH for Apple Silicon Macs
        if [[ -f /opt/homebrew/bin/brew ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi

        success "Homebrew installed."
    fi

    info "Updating Homebrew..."
    brew update
}

# -----------------------------------------------------------------------------
# 2. Git
# -----------------------------------------------------------------------------
install_git() {
    if command -v git &> /dev/null; then
        success "Git is already installed ($(git --version))."
    else
        info "Installing Git..."
        brew install git
        success "Git installed."
    fi
}

configure_git() {
    local current_name
    local current_email
    current_name=$(git config --global user.name 2>/dev/null || echo "")
    current_email=$(git config --global user.email 2>/dev/null || echo "")

    if [[ -z "$current_name" ]]; then
        echo ""
        read -rp "Enter your Git name (e.g., John Doe): " git_name
        git config --global user.name "$git_name"
        success "Git name set to: $git_name"
    else
        success "Git name already configured: $current_name"
    fi

    if [[ -z "$current_email" ]]; then
        read -rp "Enter your Git email: " git_email
        git config --global user.email "$git_email"
        success "Git email set to: $git_email"
    else
        success "Git email already configured: $current_email"
    fi

    # Set default branch to main
    git config --global init.defaultBranch main

    # Enable credential manager for HTTPS
    if command -v git-credential-manager &> /dev/null; then
        success "Git Credential Manager is already installed."
    else
        info "Installing Git Credential Manager for HTTPS auth..."
        brew install --cask git-credential-manager
        success "Git Credential Manager installed."
    fi

    # Set useful defaults
    git config --global pull.rebase false
    git config --global core.autocrlf input

    success "Git configured."
}

# -----------------------------------------------------------------------------
# 3. pyenv + Python
# -----------------------------------------------------------------------------
install_pyenv() {
    if command -v pyenv &> /dev/null; then
        success "pyenv is already installed."
    else
        info "Installing pyenv..."
        brew install pyenv
        success "pyenv installed."
    fi

    # Ensure pyenv is initialized in the current shell
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"

    # Add pyenv to shell profile if not already there
    local shell_profile=""
    if [[ -f "$HOME/.zshrc" ]]; then
        shell_profile="$HOME/.zshrc"
    elif [[ -f "$HOME/.bash_profile" ]]; then
        shell_profile="$HOME/.bash_profile"
    elif [[ -f "$HOME/.bashrc" ]]; then
        shell_profile="$HOME/.bashrc"
    else
        shell_profile="$HOME/.zshrc"
        touch "$shell_profile"
    fi

    if ! grep -q 'pyenv init' "$shell_profile" 2>/dev/null; then
        info "Adding pyenv to $shell_profile..."
        echo '' >> "$shell_profile"
        echo '# pyenv configuration' >> "$shell_profile"
        echo 'export PYENV_ROOT="$HOME/.pyenv"' >> "$shell_profile"
        echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> "$shell_profile"
        echo 'eval "$(pyenv init -)"' >> "$shell_profile"
        success "pyenv added to $shell_profile"
    else
        success "pyenv already configured in $shell_profile"
    fi
}

install_python() {
    # Install build dependencies for pyenv
    brew install openssl readline sqlite3 xz zlib tcl-tk 2>/dev/null || true

    # Find the latest patch version of the target Python
    local latest_version
    latest_version=$(pyenv install --list | tr -d ' ' | grep "^${PYTHON_VERSION}\." | grep -v '[a-zA-Z]' | tail -1)

    if [[ -z "$latest_version" ]]; then
        error "Could not find Python ${PYTHON_VERSION}.x in pyenv. Falling back to exact version."
        latest_version="${PYTHON_VERSION}.0"
    fi

    if pyenv versions --bare | grep -q "^${latest_version}$"; then
        success "Python ${latest_version} is already installed via pyenv."
    else
        info "Installing Python ${latest_version} via pyenv (this may take a few minutes)..."
        pyenv install "$latest_version"
        success "Python ${latest_version} installed."
    fi

    pyenv global "$latest_version"
    success "Python ${latest_version} set as global default."
}

# -----------------------------------------------------------------------------
# 4. pip + pipx
# -----------------------------------------------------------------------------
upgrade_pip() {
    info "Upgrading pip..."
    python3 -m pip install --upgrade pip --quiet
    success "pip upgraded to $(python3 -m pip --version | awk '{print $2}')."
}

install_pipx() {
    if command -v pipx &> /dev/null; then
        success "pipx is already installed."
    else
        info "Installing pipx..."
        brew install pipx
        pipx ensurepath
        success "pipx installed."
    fi
}

# -----------------------------------------------------------------------------
# 5. Dev tools (installed globally via pipx)
# -----------------------------------------------------------------------------
install_dev_tools() {
    info "Installing dev tools via pipx..."

    local tools=("black" "ruff" "mypy")

    for tool in "${tools[@]}"; do
        if pipx list 2>/dev/null | grep -q "package ${tool}"; then
            success "${tool} is already installed via pipx."
        else
            info "Installing ${tool}..."
            pipx install "$tool"
            success "${tool} installed."
        fi
    done
}

# -----------------------------------------------------------------------------
# 6. VS Code
# -----------------------------------------------------------------------------
install_vscode() {
    if command -v code &> /dev/null; then
        success "VS Code is already installed."
    else
        info "Installing Visual Studio Code..."
        brew install --cask visual-studio-code
        success "VS Code installed."
    fi
}

install_vscode_extensions() {
    if ! command -v code &> /dev/null; then
        warn "VS Code CLI not found. Skipping extension installation."
        warn "Install extensions manually after adding 'code' to PATH."
        return
    fi

    info "Installing VS Code extensions..."

    local extensions=(
        "ms-python.python"
        "ms-python.vscode-pylance"
        "ms-python.black-formatter"
        "charliermarsh.ruff"
        "ms-python.mypy-type-checker"
        "EditorConfig.EditorConfig"
    )

    for ext in "${extensions[@]}"; do
        if code --list-extensions 2>/dev/null | grep -qi "$(echo "$ext" | cut -d. -f2)"; then
            success "Extension ${ext} is already installed."
        else
            info "Installing extension: ${ext}"
            code --install-extension "$ext" --force 2>/dev/null || warn "Failed to install ${ext}"
        fi
    done

    success "VS Code extensions installed."
}

# -----------------------------------------------------------------------------
# 7. Virtual environment + packages
# -----------------------------------------------------------------------------
setup_virtualenv() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    if [[ -d "${script_dir}/${VENV_DIR}" ]]; then
        success "Virtual environment already exists at ${script_dir}/${VENV_DIR}"
    else
        info "Creating virtual environment..."
        python3 -m venv "${script_dir}/${VENV_DIR}"
        success "Virtual environment created at ${script_dir}/${VENV_DIR}"
    fi

    info "Activating virtual environment..."
    source "${script_dir}/${VENV_DIR}/bin/activate"

    info "Upgrading pip inside virtual environment..."
    pip install --upgrade pip --quiet

    if [[ -f "${script_dir}/requirements.txt" ]]; then
        info "Installing packages from requirements.txt..."
        pip install -r "${script_dir}/requirements.txt" --quiet
        success "Packages installed from requirements.txt."
    else
        warn "No requirements.txt found. Skipping package installation."
    fi

    if [[ -f "${script_dir}/requirements-dev.txt" ]]; then
        info "Installing dev packages from requirements-dev.txt..."
        pip install -r "${script_dir}/requirements-dev.txt" --quiet
        success "Dev packages installed from requirements-dev.txt."
    fi
}

# =============================================================================
# Main
# =============================================================================
main() {
    echo ""
    echo "=============================================="
    echo "  macOS Python Dev Environment Setup"
    echo "=============================================="
    echo ""

    install_homebrew
    echo ""

    install_git
    configure_git
    echo ""

    install_pyenv
    install_python
    echo ""

    upgrade_pip
    install_pipx
    echo ""

    install_dev_tools
    echo ""

    install_vscode
    install_vscode_extensions
    echo ""

    setup_virtualenv
    echo ""

    echo "=============================================="
    echo -e "  ${GREEN}Setup complete!${NC}"
    echo "=============================================="
    echo ""
    echo "  Python:  $(python3 --version)"
    echo "  pip:     $(python3 -m pip --version | awk '{print $2}')"
    echo "  Git:     $(git --version)"
    echo ""
    echo "  To activate the virtual environment:"
    echo "    source venv/bin/activate"
    echo ""
    echo "  NOTE: Restart your terminal or run"
    echo "    source ~/.zshrc"
    echo "  to ensure pyenv is available in new shells."
    echo ""
}

main "$@"
