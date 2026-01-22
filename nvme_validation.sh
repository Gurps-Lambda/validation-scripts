#!/bin/bash

# Script Name: nvme_validation.sh 
# Description: This script is responsible for testing and validation all nvme drives and logging data in a structured format
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
WIDTH=120
LOG_FILE=""
LOG_FILE_PATH=""
LOG_DIR=""

# Add all required packages to this list
PACKAGES=("ipmitool" "nvme-cli")

# ==================
# Safety Flags
# ==================

set -uo pipefail

# ==================
# Helper Functions
# ==================

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
    echo -e "\n"
}

# This function will generate the header and display to the console

function generate_header()
{
    TEST_NAME="NVMe Drive Validation"
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
    # footer_space
}

# This function will generate the test summary and display to the console

function generate_summary()
{    
    TEST_NAME="SUMMARY"
    PADDING=$(( ($WIDTH - ${#TEST_NAME}) / 2 ))
    
    RESULT=$([[ "$FAILED" -ne 0 ]] && echo "FAIL" || echo "PASS")
    END_TIME=$(date +"%m/%d/%y %H:%M:%S")

    # printf '%*s\n' "$WIDTH" '' | tr ' ' '='
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

function generate_divider()
{
    echo
    printf '%*s\n' "$WIDTH" '' | tr ' ' '-' 
    echo
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
    declare -g LOG_DIR="/var/tmp/hw-validation"
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR"
        chmod 755 "$LOG_DIR"
    fi

    # Generating log file
    TIMESTAMP=$(date +"%m-%d-%y_%H:%M:%S")
    SCRIPT_NAME=$(basename $0 .sh)
    declare -g LOG_FILE="${SCRIPT_NAME}_${TIMESTAMP}.log"
    declare -g LOG_FILE_PATH="${LOG_DIR}/${SCRIPT_NAME}_${TIMESTAMP}.log"
    touch "$LOG_FILE_PATH"
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
    # Check for packages prior to header being generated, do dependency check afterwards
    for PACKAGE in "${PACKAGES[@]}"; do 
        if ! dpkg -s "$PACKAGE" &>/dev/null; then
            echo "Package ${PACKAGE} not installed"
            read -p "Dependencies missing, would you like to install now? [yes/no]: " choice
            # echo -e ": $PACKAGE"
            # if apt-get -y install "$PACKAGE" &>/dev/null; then
                # echo -e "Package ${PACKAGE} has been installed" 
                # generate_log "INFO" "env_check" "Package ${PACKAGE} has been installed"
            # else
            #     echo -e "Package ${PACKAGE} has not been installed, exiting...." 
            #     # generate_log "FAIL" "env_check" "Package ${PACKAGE} has not been installed, exiting..."
            #     return 1
            # fi
        # else
        #     echo -e "Package ${PACKAGE} is installed"
        #     # generate_log "INFO" "env_check" "Package $PACKAGE is installed" 
        fi
    done
    # generate_log "PASS" "env_check" "All packages have been installed"
}

# ==================
# Environment Checks
# ==================

function env_checks()
{
    # This function will take care of environment checks
    # 1. Verify log directory and file has been created
    # 2. All packages have been installed 

    if [[ -d "$LOG_DIR" ]]; then
        generate_log "INFO" "env_check" "Log directory: ${LOG_DIR}"
    fi
    if [[ -f "$LOG_FILE_PATH" ]]; then
        generate_log "INFO" "env_check" "Log file: ${LOG_FILE}"
    fi
    generate_log "PASS" "env_check" "Environment Validation Passed"
    generate_divider
}

# This function is responsible for checking links for the NVMe Drives
function link_checks()
{
    ALL_DRIVES=$(lsblk -dn -o NAME | grep "^nvme")
    NUM_DRIVES=$(wc -l <<< "$ALL_DRIVES")
    # echo "Value of NUM_DRIVES: $NUM_DRIVES"
    if [[ "$NUM_DRIVES" -eq 0 ]]; then
        generate_log "FAIL" "link_check" "No NVMe drives detected"
        return 1
    else
        generate_log "INFO" "link_check" "Drives Found: ${NUM_DRIVES}"
    fi
    for drive in $ALL_DRIVES; do
        DEV="/dev/$drive"
        MODEL=$(lsblk -dn -o MODEL "$DEV")
        SIZE=$(lsblk -dnr -o SIZE "$DEV")
        SERIAL=$(lsblk -dn -o SERIAL "$DEV")

        # PCI_ADDR=$(basename "$(readlink -f /sys/block/$drive/device/..)")
        # echo "Current PCI Address: ${PCI_ADDR}"
        # LINK_WIDTH=$(cat /sys/bus/pci/devices/$PCI_ADDR/current_link_width 2>/dev/null)
        # LINK_SPEED=$(cat /sys/bus/pci/devices/$PCI_ADDR/current_link_speed 2>/dev/null)
        # echo "Current Link Width: ${LINK_WIDTH}"
        # echo "Current Link Speed: ${LINK_SPEED}"


        generate_log "INFO" "link_check" "Device: /dev/$drive ($SIZE)"
        generate_log "INFO" "link_check" "Manufacturer: $MODEL"
        generate_log "INFO" "link_check" "Serial Number: $SERIAL"
        generate_divider
    done
}

function kernel_log_checks()
{
    generate_log "INFO" "kernel_log_check" "Scanning dmesg for errors"
}

function nvme_checks()
{
 :
}

# ==================
# Main Execution
# ==================

# 1. Check if the script is being run as root 
# 2. Check if all required packages are installed 
# 3. Generate log file and directory
# 4. Generate header with all required information and append to log file
# 5. Run all scripts and append information to log file
# 6. Generate summary with results and append to log file

check_root
# install_dependencies
generate_log_env

{
    generate_header
    env_checks
    link_checks
    generate_summary
} > >(tee -a "$LOG_FILE_PATH")
