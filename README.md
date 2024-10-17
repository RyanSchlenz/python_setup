# Python Environment Setup Script

This repository contains a simple Bash script and a `requirements.txt` file to help you quickly set up a Python environment on a new Mac. The script installs Python, upgrades `pip`, and installs any necessary Python packages from the `requirements.txt` file.

## Features

- Installs Homebrew (if not already installed)
- Installs Python 3 via Homebrew
- Upgrades `pip` to the latest version
- Installs Python packages listed in `requirements.txt`
- (Optional) Sets up a virtual environment with `virtualenv`

## Prerequisites

- macOS
- Internet connection

## Usage

### 1. Clone the repository

# Clone the repository
git clone https://github.com/your-username/python-setup.git

# Navigate into the directory
cd python-setup

# Make the Bash script executable
chmod +x python_setup.sh

# Run the Bash script to set up Python and install packages
./python_setup.sh

