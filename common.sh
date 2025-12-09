#!/bin/bash

# Shared helper functions and variables

# Version number for Screen Profiler
SCREENPROFILER_VERSION="0.1.1"

script_dir="$(dirname "$(realpath "$0")")"
profiles_dir="$script_dir/profiles"

# Check for required dependencies
check_dependencies() {
    if ! command -v jq &> /dev/null; then
        echo "Error: jq is not installed."
        echo
        echo "Please install jq:"
        echo "  Ubuntu/Debian: sudo apt install jq"
        echo "  Arch/Manjaro:  sudo pacman -S jq"
        echo "  Fedora:        sudo dnf install jq"
        exit 1
    fi
}

extract_value() {
    echo "$1" | jq -r "$2"
}

map_orientation() {
    case $1 in
        1) echo "normal" ;;
        2) echo "left" ;;
        3) echo "inverted" ;;
        4) echo "right" ;;
        *) echo "normal" ;;
    esac
}

restart_plasma() {
    pkill plasmashell
    sleep 1
    nohup plasmashell --replace &
}
