#!/bin/bash

# Set strict mode for better error handling
set -euo pipefail

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Function to check and install a command
check_and_install() {
    command_name="$1"
    install_command="$2"
    error_message="$3"
    
    if ! command -v "$command_name" &> /dev/null; then
        echo -e "${RED}Error: $error_message${NC}" >&2
        if [[ -n "$install_command" ]]; then
            echo -e "${YELLOW}Attempting to install $command_name...${NC}"
            eval "$install_command"
            if ! command -v "$command_name" &> /dev/null; then
                echo -e "${RED}Failed to install $command_name.${NC}" >&2
                exit 1
            fi
            echo -e "${GREEN}$command_name installed successfully.${NC}"
        else
            exit 1
        fi
    fi
}

# Check and install pyenv
check_and_install "pyenv" "" "pyenv is not installed."

# Check and install the Python version from .python-version
if [[ -f ".python-version" ]]; then
    python_version=$(cat .python-version)
    if ! pyenv versions --bare | grep -q "^$python_version$"; then
        echo -e "${YELLOW}Installing Python version $python_version using pyenv...${NC}"
        pyenv install "$python_version"
        if [[ $? -ne 0 ]]; then
            echo -e "${RED}Failed to install Python version $python_version.${NC}" >&2
            exit 1
        fi
        echo -e "${GREEN}Python version $python_version installed successfully.${NC}"
    else
        echo -e "${GREEN}Python version $python_version is already installed.${NC}"
    fi
    pyenv local "$python_version"
else
    echo -e "${YELLOW}No .python-version file found, checking for default python version.${NC}"
    if [[ $(pyenv version-name) == *"no version set"* ]]; then
        echo -e "${RED}No python version set, please set a python version using pyenv local <version>.${NC}"
        exit 1
    fi
fi

# Check and install python3
check_and_install "python3" "" "python3 is not installed."

# Create and activate virtual environment
if [[ ! -d ".venv" ]]; then
    echo -e "${YELLOW}Creating virtual environment...${NC}"
    python3 -m venv .venv
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Failed to create virtual environment.${NC}" >&2
        exit 1
    fi
    echo -e "${GREEN}Virtual environment created.${NC}"
else
    echo -e "${GREEN}Virtual environment already exists.${NC}"
fi

echo -e "${YELLOW}Activating virtual environment...${NC}"
source .venv/bin/activate

# Install Python dependencies
if [[ -f "requirements.txt" ]]; then
    echo -e "${YELLOW}Installing Python dependencies from requirements.txt...${NC}"
    .venv/bin/pip3 install --upgrade pip
    .venv/bin/pip3 install -r requirements.txt
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Failed to install Python dependencies.${NC}" >&2
        exit 1
    fi
    echo -e "${GREEN}Python dependencies installed successfully.${NC}"
else
    echo -e "${YELLOW}No requirements.txt file found.${NC}"
fi

echo -e "${GREEN}API setup complete.${NC}"