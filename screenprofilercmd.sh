#!/bin/bash

script_dir="$(dirname "$(realpath "$0")")"
profiles_dir="$script_dir/profiles"

command=$1
filename=$2
flag=$3

case $command in
    save)
        [ -z "$filename" ] && echo "Usage: $0 save <name> [0|1]" && exit 1
        "$script_dir/save_profile.sh" "$filename" "$flag"
        ;;
    load)
        [ -z "$filename" ] && echo "Usage: $0 load <name>" && exit 1
        "$script_dir/load_profile.sh" "$filename"
        ;;
    remove)
        [ -z "$filename" ] && echo "Usage: $0 remove <name>" && exit 1
        rm -rf "$profiles_dir/$filename"
        echo "Profile $filename removed"
        ;;
    list)
        echo "Available profiles:"
        for dir in "$profiles_dir"/*; do
            [ -d "$dir" ] || continue
            echo "$(basename "$dir")"
        done | sort
        ;;
    tray)
        python3 "$script_dir/screenprofiler.py" &
        ;;
    uninstall)
        if [ -x "$script_dir/uninstall.sh" ]; then
            "$script_dir/uninstall.sh"
        else
            echo "Uninstall script not found at $script_dir/uninstall.sh"
        fi
        ;;
    ""|help|--help|-h)
        echo "Usage: $0 <command> [args]"
        echo "Commands:"
        echo "  save <name> [0|1]   Save profile (0=monitors only, 1=with KDE configs)"
        echo "  load <name>         Load profile"
        echo "  remove <name>       Delete profile"
        echo "  list                List profiles (alphabetical)"
        echo "  tray                Launch the Screen Profiler tray app"
        echo "  uninstall           Run the uninstall script"
        ;;
    *)
        echo "Invalid command: $command"
        echo "Run '$0 help' for usage."
        exit 1
        ;;
esac
