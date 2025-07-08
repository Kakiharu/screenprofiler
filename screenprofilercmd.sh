#!/bin/bash
# Store the directory where the script is located
script_dir="$(dirname "$(realpath "$0")")"
profiles_dir="$script_dir/profiles"

# Function to display the help message
display_help() {
    echo "####################################################################################################"
    echo "# Save/Load/Remove Profile"
    echo "#     Usage: $0 {save|load|remove} [profilename] [konsave enabled (0 or 1)]"
    echo "#       Example: $0 save example 1"
    echo "#       Example: $0 load example"
    echo "# List Profiles"
    echo "#     Usage: $0 list"
	echo "#"
    echo "# Konsave  - Saves kde widgets and settings."
    echo "####################################################################################################"
}

# Check if at least one argument is provided
if [ $# -lt 1 ]; then
    display_help
    exit 1
fi

command=$1
filename=$2
konsave_arg=$3

case $command in
    help|-help|--help)
        display_help
        exit 0
        ;;
    #Save
    save)
        if [ -z "$filename" ]; then
            echo "Usage: $0 save filename [konsave_state (0 or 1)]"
            exit 1
        fi
        "$script_dir/save_profile.sh" "$filename" "$konsave_arg"
        ;;
		
    #Load
    load)
        if [ -z "$filename" ]; then
            echo "Usage: $0 load filename"
            exit 1
        fi
        "$script_dir/load_profile.sh" "$filename"
        ;;
		
	#Remove 
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
	#List
    list)
        echo "Available profiles:"
        for file in "$profiles_dir"/*; do
            echo "$(basename "$file") "
        done
        echo
        ;;
    *)
        echo "Invalid command. Use 'help', 'save', 'load', 'remove', 'list'."
        exit 1
        ;;
esac