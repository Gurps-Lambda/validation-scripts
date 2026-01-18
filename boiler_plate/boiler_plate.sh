#!/bin/bash

# Script Name: 
# Description: Boilerplate code for creating testing and validation scripts with automated log file generation
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

# Functions to print color coded statuses to the terminal 

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

# This function will generate the log file header 

function generate_header()
{
    WIDTH=80
    TEST_NAME="Hardware Validation"
    PADDING=$(( ($WIDTH - ${#TEST_NAME}) / 2 ))

    KERNEL_VERSION=$(uname -r)
    HOSTNAME=$(hostname)
    BMC_FIRMWARE=$(ipmitool mc info 2>/dev/null | grep -i "Firmware Revision" | awk '{print $4}' || echo "N/A")
    BIOS_VERSION=$(dmidecode -s bios-version 2>/dev/null || echo "N/A")
    SERIAL_NUMBER=$(dmidecode -s system-serial-number 2>/dev/null || echo "N/A")
    START_TIME=$(date +"%m/%d/%y %H:%M:%S")

    echo "================================================================================"
    printf "%${PADDING}s%s\n" "" "$TEST_NAME"
    echo "================================================================================"
    printf "%-15s : %s\n" "OS" "$PRETTY_NAME (kernel $KERNEL_VERSION)"
    printf "%-15s : %s\n" "BMC FW" "$BMC_FIRMWARE"
    printf "%-15s : %s\n" "BIOS Version" "$BIOS_VERSION"
    printf "%-15s : %s\n" "Serial Number" "$SERIAL_NUMBER"
    printf "%-15s : %s\n" "Host" "$HOSTNAME"
    printf "%-15s : %s\n" "Start Time" "$START_TIME"
    echo "================================================================================"
}

function generate_summary()
{
    WIDTH=80
    TEST_NAME="SUMMARY"
    PADDING=$(( ($WIDTH - ${#TEST_NAME}) / 2 ))
    

    TOTAL_TESTS="0"
    PASSED="0"
    FAILED="0"
    WARNINGS="0"
    RESULT=$([[ "$FAILED" -gt 0 ]] && echo "FAIL" || echo "PASS")
    END_TIME=$(date +"%m/%d/%y %H:%M:%S")

    
    printf "%${PADDING}s\n" "$TEST_NAME"
    echo "================================================================================"
    printf "%-15s : %s\n" "Total Tests" "$TOTAL_TESTS"
    printf "%-15s : %s\n" "Passed" "$PASSED"
    printf "%-15s : %s\n" "Failed" "$FAILED"
    printf "%-15s : %s\n" "Result" "$RESULT"
    printf "%-15s : %s\n" "End Time" "$END_TIME"
    echo "================================================================================" 
}

# =================
# Environment Setup
# =================

# /etc/-os-release holds information about OS i.e. version, name etc
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
else
    warn "/etc/os-release not found, is this OS Ubuntu?"
fi

# Absolute Path for Log File
LOG_FILE="/var/log/nameOfLogFile.log"
TMP_DIR="/tmp/name_of_log$(date +%m%d%y)"

# =================
# Preliminary Checks
# =================

# Checks is script is being run as root
# Comment out if users do not require root priviledges

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}This script must be run as root${NC}"
    echo -e "Example: ${YELLOW} sudo $0${NC}"
    exit 1
fi

# =================
# Dependency Check
# =================

# If any specific packages are required to run, check/install here
function install_dependencies()
{
    PACKAGES=()
    for PACKAGE in "${PACKAGES[@]}"; do 
        if ! dpkg -s "$PACKAGE" &>/dev/null; then
            apt-get -y install "$PACKAGE"
            success "Package $PACKAGE has been installed"
        else
            info "Package $PACKAGE is already installed" 
        fi
    done
}


# =================
# Main
# =================

# install_dependencies
generate_header
# run_tests
generate_summary