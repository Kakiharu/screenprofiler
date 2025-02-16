#!/bin/bash
######################Functions######################
# Function to update save_profile.sh and load_profile.sh
update_konsave_scripts() {
  konsave_enable="$1"
  save_script="$script_dir/save_profile.sh"
  load_script="$script_dir/load_profile.sh"
  # Update save_profile.sh
  sed -i "s/konsave_enable=.*/konsave_enable=$konsave_enable/" "$save_script"
  # Update load_profile.sh
  sed -i "s/konsave_enable=.*/konsave_enable=$konsave_enable/" "$load_script"
}

# Function to display the help message
display_help() {
  echo "####################################"
  echo "Save/Load/Remove Profile"
  echo "    Usage: $0 {save|load|remove} [filename]"
  echo "List Profiles"
  echo "    Usage: $0 list"
  echo "Enable/Disable Konsave"
  echo "    Usage: $0 konsave {enable|disable}"
  echo "####################################"
}

# Store the directory where the script is located
script_dir="$(dirname "$(realpath "$0")")"
profiles_dir="$script_dir/profiles"



# Check if at least one argument is provided
if [ $# -lt 1 ]; then
  display_help
  exit 1
fi

command=$1
filename=$2

case $command in
  help|-help|--help)
    display_help
    exit 0
    ;;
  save)
    if [ -z "$filename" ]; then
      echo "Usage: $0 save filename"
      exit 1
    fi
    "$script_dir/save_profile.sh" "$profiles_dir" "$filename"
    ;;
  load)
    if [ -z "$filename" ]; then
      echo "Usage: $0 load filename"
      exit 1
    fi
    "$script_dir/load_profile.sh" "$profiles_dir" "$filename"
    ;;
  remove)
    if [ -z "$filename" ]; then
      echo "Usage: $0 remove filename"
      exit 1
    fi
    if [ ! -f "$profiles_dir/$filename" ]; then
      echo "Profile not found: $filename"
      exit 1
    fi
    rm "$profiles_dir/$filename"
    echo "Profile removed: $filename"
    ;;
  list)
    echo "Available profiles:"
    for file in "$profiles_dir"/*; do
      echo "$(basename "$file") "
    done
    echo
    ;;
  konsave)
    if [ -z "$filename" ]; then
      echo "Usage: $0 konsave {enable|disable}"
      exit 1
    fi
    if [ "$filename" = "enable" ]; then
      update_konsave_scripts "true"
      echo "Konsave has been enabled."
    elif [ "$filename" = "disable" ]; then
      update_konsave_scripts "false"
      echo "Konsave has been disabled."
    else
      echo "Invalid konsave command. Use 'enable' or 'disable'."
      exit 1
    fi
    ;;
  *)
    echo "Invalid command. Use 'help', 'save', 'load', 'remove', 'list', or 'konsave'."
    exit 1
    ;;
esac











