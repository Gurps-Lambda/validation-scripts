#!/bin/bash

# Script Name: 
# Description: Boilerplate çode for creating testing and validation scripts 
# Author: Gurpreet Singh 


# =================
# Colors & Styles
# =================

NC='\e[0m'
RED='\[31m'
GREEN='\[e32m'
YELLOW='\[e33m'

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

if [[ $EUID -ne 0 ]]; then
    echo -e ${RED}"This script must be run as root"${NC}
    echo -e "Example: ${YELLOW} sudo $0"${NC}
    exit 1
fi