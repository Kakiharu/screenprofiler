#!/bin/bash

# Define the default Konsave state if not provided (1 for enabled, 0 for disabled)
default_konsave_state=1

# Check the number of arguments
if [ $# -eq 1 ]; then
  filename="$1"
  konsave_integration_value="$default_konsave_state"
  echo "Using default Konsave state: $konsave_integration_value"
elif [ $# -eq 2 ]; then
  filename="$1"
  declare -i konsave_state="$2"
  # Validate Konsave state
  if [[ "$konsave_state" -eq 0 || "$konsave_state" -eq 1 ]]; then
    konsave_integration_value="$konsave_state"
  else
    echo "Invalid Konsave state provided: $konsave_state. Use 0 or 1."
    exit 1
  fi
else
  echo "Usage: $0 filename [konsave_state (0 or 1)]"
  exit 1
fi

# Determine the script's directory
script_dir="$(dirname "$(realpath "$0")")"
profiles_dir="$script_dir/profiles"

# Create the profiles directory if it doesn't exist
mkdir -p "$profiles_dir"

# Fetch the current display configuration
current_config=$(kscreen-console json | sed -n '/^{/,$p')

# Fetch the primary monitor using xrandr
primary_monitor=$(xrandr --query | grep "primary" | awk '{print $1}')

# Add primary monitor information to the JSON
current_config=$(echo "$current_config" | jq --arg pm "$primary_monitor" '. + {primaryMonitor: $pm}')

# Add Konsave integration status to the JSON
current_config=$(echo "$current_config" | jq --arg ki "$konsave_integration_value" '. + {konsaveintegration: ($ki | tonumber)}')

# Save the configuration to the specified file in the profiles directory
echo "$current_config" > "$profiles_dir/$filename"

echo "Screen profile saved to $profiles_dir/$filename with Konsave state: $konsave_integration_value"


############## Konsave Integration ####################
# Saves widgets and panel/kde settings.

# Check if konsave command exists and konsave_integration_value is 1
if [ "$konsave_integration_value" -eq 1 ] && command -v konsave &> /dev/null; then
  # Run konsave command
  konsave -s "$filename" -f
  echo "konsave -s $filename executed successfully"
else
  echo "Konsave integration is disabled for this profile or konsave command not found."
fi
