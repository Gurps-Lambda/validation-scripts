#!/bin/bash

# Script Name: 
# Description: Boilerplate code for creating testing and validation scripts with automated structured log file generation
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
# Global Variables 
# =================

TOTAL_TESTS=0
PASSED=0
FAILED=0
WARNINGS=0
WIDTH=100
LOG_FILE=""
LOG_FILE_PATH=""

# Add all required packages to this list
PACKAGES=("ipmitool" "nvme-cli")

# =================
# Safety Flags
# =================

set -uo pipefail

# =================
# Helper Functions
# =================

# Functions to print color coded statuses to the terminal 

function error()
{
    echo -e "${RED}$1${NC}"
}

function success()
{
    echo -e "${GREEN}$1${NC}"
}

function warn()
{
    echo -e "${YELLOW}$1${NC}"
}

function info()
{
    echo -e "${BLUE}$1${NC}"
}

function footer_space()
{
    echo -e "\n\n"
}

# This function will generate the header and display to the console

function generate_header()
{
    TEST_NAME="HARDWARE VALIDATION"
    PADDING=$(( ($WIDTH - ${#TEST_NAME}) / 2 ))
    
    OS_RELEASE="/etc/os-release"
    source "$OS_RELEASE"

    KERNEL_VERSION=$(uname -r)
    HOSTNAME=$(hostname)
    BMC_FIRMWARE=$(ipmitool mc info 2>/dev/null | grep -i "Firmware Revision" | awk '{print $4}' || echo "N/A")
    BIOS_VERSION=$(dmidecode -s bios-version || echo "N/A")
    SERIAL_NUMBER=$(dmidecode -s system-serial-number || echo "N/A")
    START_TIME=$(date +"%m/%d/%y %H:%M:%S")

    printf '%*s\n' "$WIDTH" '' | tr ' ' '='
    printf "%${PADDING}s%s\n" "" "$TEST_NAME"
    printf '%*s\n' "$WIDTH" '' | tr ' ' '='
    printf "%-15s : %s\n" "OS" "$PRETTY_NAME (kernel $KERNEL_VERSION)"
    printf "%-15s : %s\n" "BMC FW" "$BMC_FIRMWARE"
    printf "%-15s : %s\n" "BIOS Version" "$BIOS_VERSION"
    printf "%-15s : %s\n" "Serial Number" "$SERIAL_NUMBER"
    printf "%-15s : %s\n" "Host" "$HOSTNAME"
    printf "%-15s : %s\n" "Start Time" "$START_TIME"
    printf '%*s\n' "$WIDTH" '' | tr ' ' '='
    footer_space
}

# This function will generate the test summary and display to the console

function generate_summary()
{    
    TEST_NAME="SUMMARY"
    PADDING=$(( ($WIDTH - ${#TEST_NAME}) / 2 ))
    
    RESULT=$([[ "$FAILED" -ne 0 ]] && echo "FAIL" || echo "PASS")
    END_TIME=$(date +"%m/%d/%y %H:%M:%S")

    printf '%*s\n' "$WIDTH" '' | tr ' ' '='
    printf "%${PADDING}s%s\n" "" "$TEST_NAME"
    printf '%*s\n' "$WIDTH" '' | tr ' ' '='
    printf "%-15s : %s\n" "Total Tests" "$TOTAL_TESTS"
    printf "%-15s : %s\n" "Passed" "$PASSED"
    printf "%-15s : %s\n" "Failed" "$FAILED"
    printf "%-15s : %s\n" "Result" "$RESULT"
    printf "%-15s : %s\n" "End Time" "$END_TIME"
    printf '%*s\n' "$WIDTH" '' | tr ' ' '='
}

# This function will color code the log entry 

function color_code_log_type()
{
    local TYPE="$1"
    case "$TYPE" in
        PASS) echo -e "${GREEN}${TYPE}${NC}" ;;
        FAIL) echo -e "${RED}${TYPE}${NC}" ;;
        WARN) echo -e "${YELLOW}${TYPE}${NC}" ;;
        INFO) echo -e "${BLUE}${TYPE}${NC}" ;;
    esac
}


# This function defines the structure of each log entry and increments variables related to test results
# Log Structure in comment below
# [TYPE] [TIMESTAMP] [MODULE] Message

function generate_log() 
{
    local TYPE=$1
    local COLORED_TYPE=$(color_code_log_type "$TYPE")
    local MODULE=$2
    local MSG=$3
    local TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")

    # This will keep track of PASS/FAIL for all tests
    case "$TYPE" in
    PASS) ((PASSED++)); ((TOTAL_TESTS++));;
    FAIL) ((FAILED++)); ((TOTAL_TESTS++));;
    WARN) ((WARNINGS++));;
    esac

    printf "[%s] [%s] [%s] %s\n" "$COLORED_TYPE" "$TIMESTAMP" "$MODULE" "$MSG"
}

function generate_log_env()
{
    # Generating directory for log file 
    LOG_DIR="/var/tmp/hw-validation"
    if [ ! -d "$LOG_DIR" ]; then
        generate_log "INFO" "env_check" "Creating log directory at: ${LOG_DIR}"
        mkdir -p "$LOG_DIR"
        chmod 755 "$LOG_DIR"
        generate_log "INFO" "env_check" "Log directory created: ${LOG_DIR}"
    else
        generate_log "INFO" "env_check" "Log directory: ${LOG_DIR}"
    fi

    # Generating log file
    TIMESTAMP=$(date +"%m-%d-%y_%H:%M:%S")
    SCRIPT_NAME=$(basename $0 .sh)
    declare -g LOG_FILE="${SCRIPT_NAME}_${TIMESTAMP}.log"
    declare -g LOG_FILE_PATH="${LOG_DIR}/${SCRIPT_NAME}_${TIMESTAMP}.log"
    touch "$LOG_FILE_PATH"
    if [[ -f "$LOG_FILE_PATH" ]]; then
        generate_log "INFO" "env_check" "Log file: ${LOG_FILE}"
    else
        generate_log "WARN" "env_check" "Log file was not created" 
    fi
    generate_log "PASS" "env_check" "Log file/directory exist"
}

function check_root()
{
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}This script must be run as root${NC}"
        echo -e "Example: ${YELLOW} sudo $0${NC}"
        exit 1
    fi
}

function install_dependencies()
{
    for PACKAGE in "${PACKAGES[@]}"; do 
        if ! dpkg -s "$PACKAGE" &>/dev/null; then
            generate_log "INFO" "env_check" "Installing ${PACKAGE}"
            if apt-get -y install "$PACKAGE" &>/dev/null; then
                generate_log "INFO" "env_check" "Package ${PACKAGE} has been installed"
            else
                generate_log "FAIL" "env_check" "Package ${PACKAGE} has not been installed, exiting..."
                break
            fi
        else
            generate_log "INFO" "env_check" "Package $PACKAGE is installed" 
        fi
    done
    generate_log "PASS" "env_check" "All packages have been installed"
}

# =================
# Environment Check
# =================
# This function will faciliate the environment check and print to the console
function env_check()
{
    # Display Information
    TEST_NAME="ENVIRONMENT CHECKS"
    PADDING=$(( ($WIDTH - ${#TEST_NAME}) / 2 ))

    printf '%*s\n' "$WIDTH" '' | tr ' ' '='
    printf "%${PADDING}s%s\n" "" "$TEST_NAME"
    printf '%*s\n' "$WIDTH" '' | tr ' ' '='

    # Dependency Check
    install_dependencies

    # Log Directory and File Creation
    generate_log_env 

    printf '%*s\n' "$WIDTH" '' | tr ' ' '=' 

    footer_space
}

# =================
# Main Execution
# =================

# 1. Check if the script is being run as root 
# 2. Check if all required packages are installed 
# 3. Generate log file and directory
# 4. Generate header with all required information and append to log file
# 5. Run all scripts and append information to log file
# 6. Generate summary with results and append to log file

check_root  
env_check
generate_header | tee -a "$LOG_FILE_PATH"
# echo "$ENV_CHECK" | tee -a "$LOG_FILE_PATH"
# run_validation_scripts
generate_summary | tee -a "$LOG_FILE_PATH"