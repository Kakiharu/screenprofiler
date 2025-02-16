#!/bin/bash

# Check if the profiles directory and filename are provided as arguments
if [ $# -lt 2 ]; then
  echo "Usage: $0 profiles_dir filename"
  exit 1
fi

profiles_dir="$1"
filename="$2"

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
# Saves widgets and panel/kde settings.

# Set the variable to enable or disable konsave
konsave_enable=true

# Check if konsave command exists and konsave_enable is true
if [ "$konsave_enable" = true ] && command -v konsave &> /dev/null; then
  # Run konsave command
  konsave -a "$filename"
  nohup plasmashell --replace &
  echo "konsave -a $filename executed successfully"
else
  echo "konsave command not found or konsave_enable is false"
fi


# Iterate through the outputs
outputs=$(echo "$profile" | jq -c '.outputs[]')
for output in $outputs; do
  name=$(echo "$output" | jq -r '.name')
  enabled=$(echo "$output" | jq -r '.enabled')
  mode=$(echo "$output" | jq -r '.currentModeId')
  scale=$(echo "$output" | jq -r '.scale')
  rotation=$(map_orientation $(echo "$output" | jq -r '.rotation'))
  pos_x=$(echo "$output" | jq -r '.pos.x')
  pos_y=$(echo "$output" | jq -r '.pos.y')
  vrrpolicy=$(echo "$output" | jq -r '.vrrPolicy')

  echo "Processing output $name"

  # Enable/disable the output
  if [ "$enabled" == "true" ]; then
    echo "Enabling output $name with mode $mode, scale $scale, rotation $rotation, position $pos_x,$pos_y"
    kscreen-doctor output."$name".enable output."$name".mode."$mode" output."$name".scale."$scale" output."$name".rotation."$rotation" output."$name".position."$pos_x","$pos_y"
    if [ "$name" == "$primary_monitor" ]; then
      primary_output="output.$name.primary"
      echo "Marking $name as primary output"
    fi
  else
    echo "Disabling output $name"
    kscreen-doctor output."$name".disable
  fi
done

# Apply primary output setting if it exists
if [ ! -z "$primary_output" ]; then
  echo "Applying primary output setting for $primary_output"
  kscreen-doctor $primary_output
fi

echo "Screen profile applied"





######################Functions######################
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
