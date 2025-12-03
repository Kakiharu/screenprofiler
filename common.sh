#!/bin/bash

# Shared helper functions and variables

# Version number for Screen Profiler
SCREENPROFILER_VERSION="0.1.0"

script_dir="$(dirname "$(realpath "$0")")"
profiles_dir="$script_dir/profiles"

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
