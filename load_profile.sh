#!/bin/bash
###################### Functions ######################
# Function to extract values from JSON
extract_value() {
    echo "$profile" | jq -r "$1"
}

# Function to map orientation values
map_orientation() {
    case $1 in
        1) echo "normal" ;;
        2) echo "left" ;;
        3) echo "inverted" ;;
        4) echo "right" ;;
        *) echo "normal" ;; # Default to normal if the value is not recognized
    esac
}

# Determine the script's directory
script_dir="$(dirname "$(realpath "$0")")"
profiles_dir="$script_dir/profiles"

# Check if the filename is provided as an argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 filename"
    exit 1
fi

filename="$1"
profile_path="$profiles_dir/$filename"

# Check if the file exists
if [ ! -f "$profile_path" ]; then
    echo "File not found: $profile_path"
    exit 1
fi

# Read the JSON file
profile=$(cat "$profile_path")

echo "Applying screen profile from $profile_path"
primary_monitor=$(extract_value '.primaryMonitor')

############## Konsave Integration ####################
# Saves widgets and panel/KDE settings.

# Set the variable to enable or disable Konsave
konsave_enable=true
konsave_integration=$(extract_value '.konsaveintegration')

# Check if Konsave is enabled in the JSON config
if [ "$konsave_integration" = 1 ]; then
    konsave -a "$filename"
    nohup plasmashell --replace &
    echo "konsave -a $filename executed successfully"
else
    echo "Konsave integration is disabled"
fi

# Extract display outputs from JSON
outputs=$(echo "$profile" | jq -c '.outputs[]')

# First, enable necessary outputs
for output in $outputs; do
    name=$(echo "$output" | jq -r '.name')
    enabled=$(echo "$output" | jq -r '.enabled')

    if [ "$enabled" == "true" ]; then
        mode=$(echo "$output" | jq -r '.currentModeId')
        scale=$(echo "$output" | jq -r '.scale')
        rotation=$(map_orientation "$(echo "$output" | jq -r '.rotation')")
        pos_x=$(echo "$output" | jq -r '.pos.x')
        pos_y=$(echo "$output" | jq -r '.pos.y')

        echo "Enabling output $name with mode $mode, scale $scale, rotation $rotation, position $pos_x,$pos_y"
        kscreen-doctor output."$name".enable output."$name".mode."$mode" output."$name".scale."$scale" output."$name".rotation."$rotation" output."$name".position."$pos_x","$pos_y"
        
        if [ "$name" == "$primary_monitor" ]; then
            primary_output="output.$name.primary"
            echo "Marking $name as primary output"
        fi
    fi
done

# Then, disable unnecessary outputs
for output in $outputs; do
    name=$(echo "$output" | jq -r '.name')
    enabled=$(echo "$output" | jq -r '.enabled')

    if [ "$enabled" != "true" ]; then
        echo "Disabling output $name"
        kscreen-doctor output."$name".disable
    fi
done

# Apply primary output setting if it exists
if [ ! -z "$primary_output" ]; then
    echo "Applying primary output setting for $primary_output"
    kscreen-doctor "$primary_output"
fi

echo "Screen profile applied successfully"
