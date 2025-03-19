#!/bin/bash

# Define the default KDE integration state if not provided (1 for enabled, 0 for disabled)
default_kde_integration_state=1

# Check the number of arguments
if [ $# -eq 1 ]; then
  filename="$1"
  kde_integration_value="$default_kde_integration_state"
  echo "Using default KDE integration state: $kde_integration_value"
elif [ $# -eq 2 ]; then
  filename="$1"
  integration_state="$2"
  # Validate integration state
  if [[ "$integration_state" -eq 0 || "$integration_state" -eq 1 ]]; then
    kde_integration_value="$integration_state"
  else
    echo "Invalid integration state provided: $integration_state. Use 0 or 1."
    exit 1
  fi
else
  echo "Usage: $0 filename [kde_integration_state (0 or 1)]"
  exit 1
fi

# Determine the script's directory
script_dir="$(dirname "$(realpath "$0")")"
profiles_dir="$script_dir/profiles"

# Create the profiles directory if it doesn't exist
mkdir -p "$profiles_dir"

# Fetch the current display configuration
current_config=$(kscreen-console json)

# Fetch the primary monitor using xrandr
primary_monitor=$(xrandr --query | grep "primary" | awk '{print $1}')

# Add primary monitor information to the JSON
current_config=$(echo "$current_config" | jq --arg pm "$primary_monitor" '. + {primaryMonitor: $pm}')

# Add KDE integration status to the JSON
current_config=$(echo "$current_config" | jq --arg ki "$kde_integration_value" '. + {kde_integration: ($ki | tonumber)}')

# Save the display configuration to the specified file in the profiles directory
echo "$current_config" > "$profiles_dir/$filename"

echo "Screen profile saved to $profiles_dir/$filename with KDE integration state: $kde_integration_value"

############## KDE Panel and Widget Configuration Saving ##############
if [ "$kde_integration_value" -eq 1 ]; then
  kde_profiles_dir="$script_dir/profiles/kde"
  mkdir -p "$kde_profiles_dir"
  
  # The Plasma configuration file (which contains panel and widget settings)
  kde_plasma_config="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
  
  if [ -f "$kde_plasma_config" ]; then
    cp "$kde_plasma_config" "$kde_profiles_dir/$filename"
    echo "Plasma panel and widget configuration saved to $kde_profiles_dir/$filename"
  else
    echo "Plasma configuration file not found at $kde_plasma_config."
  fi
else
  echo "KDE configuration saving is disabled for this profile."
fi
