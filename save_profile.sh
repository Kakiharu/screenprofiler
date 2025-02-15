#!/bin/bash

# Check if the profiles directory and filename are provided as arguments
if [ $# -lt 2 ]; then
  echo "Usage: $0 profiles_dir filename"
  exit 1
fi

profiles_dir="$1"
filename="$2"

# Create the profiles directory if it doesn't exist
mkdir -p "$profiles_dir"

# Fetch the current display configuration
current_config=$(kscreen-console json)

# Fetch the primary monitor using xrandr
primary_monitor=$(xrandr --query | grep "primary" | awk '{print $1}')

# Add primary monitor information to the JSON
current_config=$(echo "$current_config" | jq --arg pm "$primary_monitor" '. + {primaryMonitor: $pm}')

# Save the configuration to the specified file in the profiles directory
echo "$current_config" > "$profiles_dir/$filename"

echo "Screen profile saved to $profiles_dir/$filename"
