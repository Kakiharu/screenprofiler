#!/bin/bash
#
# common.sh - Shared helper functions and variables for Screen Profiler
#

# ============================================================================
# Version Information
# ============================================================================

SCREENPROFILER_VERSION="0.2.0"

# ============================================================================
# Color Definitions
# ============================================================================

# ANSI color codes for terminal output
COLOR_RESET='\033[0m'
COLOR_BOLD='\033[1m'

# Status colors
COLOR_SUCCESS='\033[0;32m'    # Green
COLOR_ERROR='\033[0;31m'      # Red
COLOR_WARNING='\033[0;33m'    # Yellow
COLOR_INFO='\033[0;36m'       # Cyan
COLOR_HEADER='\033[1;35m'     # Bold Magenta
COLOR_COMMAND='\033[1;34m'    # Bold Blue

# ============================================================================
# Output Functions
# ============================================================================

# Print a success message in green
print_success() {
    echo -e "${COLOR_SUCCESS}[OK]${COLOR_RESET} $*"
}

# Print an error message in red
print_error() {
    echo -e "${COLOR_ERROR}[ERROR]${COLOR_RESET} $*" >&2
}

# Print a warning message in yellow
print_warning() {
    echo -e "${COLOR_WARNING}[WARN]${COLOR_RESET} $*"
}

# Print an info message in cyan
print_info() {
    echo -e "${COLOR_INFO}[INFO]${COLOR_RESET} $*"
}

# Print a header in bold magenta
print_header() {
    echo -e "${COLOR_HEADER}$*${COLOR_RESET}"
}

# Print a header in bold magenta
print_blue() {
    echo -e "${COLOR_COMMAND}$*${COLOR_RESET}"
}

# Print a command being executed in bold blue
print_command() {
    echo -e "${COLOR_COMMAND}[CMD]${COLOR_RESET} $*"
}

# ============================================================================
# Directory Paths
# ============================================================================

# Get the directory where this script resides
script_dir="$(dirname "$(realpath "$0")")"

# Directory where profiles are stored
profiles_dir="$script_dir/profiles"

# ============================================================================
# Dependency Checking
# ============================================================================

# Check if all required dependencies are installed
check_dependencies() {
    local missing_deps=0

    # Check for jq (JSON processor)
    if ! command -v jq &> /dev/null; then
        print_error "jq is not installed"
        echo ""
        echo "jq is required for processing display configuration data."
        echo "Please install jq using your package manager:"
        echo ""
        echo "  Ubuntu/Debian:  sudo apt install jq"
        echo "  Arch/Manjaro:   sudo pacman -S jq"
        echo "  Fedora:         sudo dnf install jq"
        echo ""
        missing_deps=1
    fi

    # Exit if dependencies are missing
    if [ "$missing_deps" -eq 1 ]; then
        exit 1
    fi
}

# ============================================================================
# JSON Utilities
# ============================================================================

# Extract a value from JSON using jq
# Usage: extract_value <json_string> <jq_expression>
extract_value() {
    local json_string="$1"
    local jq_expression="$2"

    echo "$json_string" | jq -r "$jq_expression"
}

# ============================================================================
# Display Orientation Mapping
# ============================================================================

# Map numeric orientation codes to human-readable names
# Usage: map_orientation <orientation_code>
map_orientation() {
    local orientation_code="$1"

    case $orientation_code in
        1) echo "normal" ;;
        2) echo "left" ;;
        3) echo "inverted" ;;
        4) echo "right" ;;
        *) echo "normal" ;;  # Default to normal if unknown
    esac
}

# ============================================================================
# Plasma Desktop Management
# ============================================================================

# Restart the Plasma desktop shell
# This is necessary after restoring KDE configuration files
restart_plasma() {
    print_info "Restarting Plasma shell..."

    # Kill the current plasmashell process
    pkill plasmashell

    # Wait for it to fully terminate
    sleep 1

    # Start a new plasmashell instance in the background
    # Redirect output to nohup.out to avoid cluttering the terminal
    #nohup plasmashell --replace &>/dev/null &

    plasmashell --replace >/dev/null 2>&1 & disown


    print_success "Plasma shell restarted"
}
