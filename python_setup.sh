#!/bin/bash

# Function to check if Homebrew is installed
check_homebrew() {
    if ! command -v brew &> /dev/null
    then
        echo "Homebrew not found. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        echo "Homebrew is already installed."
    fi
}

# Function to install Python
install_python() {
    if ! command -v python3 &> /dev/null
    then
        echo "Python3 not found. Installing Python3..."
        brew install python
    else
        echo "Python3 is already installed."
    fi
}

# Function to upgrade pip
upgrade_pip() {
    echo "Upgrading pip..."
    python3 -m pip install --upgrade pip
}

# Function to install Python packages from requirements.txt
install_python_packages() {
    if [ -f "requirements.txt" ]; then
        echo "Installing Python packages from requirements.txt..."
        python3 -m pip install -r requirements.txt
    else
        echo "No requirements.txt file found. Please create one with your desired packages."
    fi
}

# Function to check or install virtualenv (optional)
install_virtualenv() {
    echo "Checking for virtualenv..."
    if ! python3 -m virtualenv --version &> /dev/null; then
        echo "virtualenv not found. Installing virtualenv..."
        python3 -m pip install virtualenv
    else
        echo "virtualenv is already installed."
    fi
}

# Function to set up virtual environment (optional)
setup_virtualenv() {
    echo "Setting up virtual environment..."
    if [ ! -d "venv" ]; then
        python3 -m virtualenv venv
        echo "Virtual environment created in 'venv' directory."
    else
        echo "Virtual environment already exists."
    fi
}

# Main setup process
echo "Starting Python environment setup..."

# Check for Homebrew and Python, install if missing
check_homebrew
install_python

# Upgrade pip
upgrade_pip

# Optionally install and set up virtual environment
install_virtualenv
setup_virtualenv

# Install Python packages from requirements.txt
install_python_packages

echo "Python setup complete!"
