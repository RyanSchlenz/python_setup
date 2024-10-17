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

First, clone this repository to your local machine:

```bash
git clone https://github.com/your-username/python-setup.git
cd python-setup

2. Make the script executable
Before running the setup script, ensure it has the proper permissions to be executed:

bash
chmod +x python_setup.sh
3. Run the script
Now run the script to set up Python, upgrade pip, and install your Python packages:

bash
./python_setup.sh
