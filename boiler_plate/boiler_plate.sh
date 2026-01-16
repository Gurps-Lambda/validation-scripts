#!/bin/bash

# Script Name: 
# Description: Boilerplate code for creating testing and validation scripts 
# Author: Gurpreet Singh 


# =================
# Colors & Styles
# =================

NC=$'\033[0m'
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
BLUE=$'\033[0;34m'

# =================
# Safety Flags
# =================

set -euo pipefail

# =================
# Helper Functions
# =================

# Functions to print color coded information to the terminal 

function error()
{
    echo -e "${RED}[ERROR] $1${NC}"
}

function success()
{
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

function warn()
{
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

function info()
{
    echo -e "${BLUE}[INFO] $1${NC}"
}

# =================
# Preliminary Checks
# =================

# Checking is script is being run as root
# Comment out if users do not require root priviledges

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}This script must be run as root${NC}"
    echo -e "Example: ${YELLOW} sudo $0${NC}"
    exit 1
fi

# =================
# Dependancy Check
# =================

# If any specific packages are required to run, check/install here

