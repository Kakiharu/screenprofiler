#!/bin/bash
source "$(dirname "$(realpath "$0")")/common.sh"

filename="$1"
profile_path="$profiles_dir/$filename/display.json"
meta_path="$profiles_dir/$filename/meta.json"

if [ ! -f "$profile_path" ]; then
    echo "Profile not found: $filename"
    exit 1
fi

profile=$(cat "$profile_path")

# Read primary monitor from meta.json
primary_monitor=""
if [ -f "$meta_path" ]; then
    primary_monitor=$(jq -r '.primaryMonitor' "$meta_path")
fi

# Restore KDE configs if present
declare -A kde_files=(
  ["plasma-org.kde.plasma.desktop-appletsrc"]="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
  ["kwinrc"]="$HOME/.config/kwinrc"
  ["kdeglobals"]="$HOME/.config/kdeglobals"
  ["plasmarc"]="$HOME/.config/plasmarc"
  ["kscreenlockerrc"]="$HOME/.config/kscreenlockerrc"
)

for name in "${!kde_files[@]}"; do
  src="$profiles_dir/$filename/$name"
  dest="${kde_files[$name]}"
  if [ -f "$src" ]; then
    cp "$src" "$dest"
    echo "Restored $name"
  fi
done

restart_plasma

# Get list of currently connected outputs
current_outputs=$(kscreen-console json | sed -n '/^{/,$p' | jq -r '.outputs[].name')

# Build a hash of outputs that exist in the profile
declare -A profile_outputs
outputs=$(echo "$profile" | jq -c '.outputs[]')
for output in $outputs; do
    name=$(echo "$output" | jq -r '.name')
    profile_outputs["$name"]=1
done

# Build a single atomic kscreen-doctor call
cmd=(kscreen-doctor)
primary_arg=""
enabled_count=0

# Configure outputs that are in the profile
for output in $outputs; do
    name=$(echo "$output" | jq -r '.name')
    enabled=$(echo "$output" | jq -r '.enabled')

    if [ "$enabled" == "true" ]; then
        ((enabled_count++))
        mode=$(echo "$output" | jq -r '.currentModeId')
        scale=$(echo "$output" | jq -r '.scale')
        rotation=$(map_orientation "$(echo "$output" | jq -r '.rotation')")
        pos_x=$(echo "$output" | jq -r '.pos.x')
        pos_y=$(echo "$output" | jq -r '.pos.y')

        cmd+=(
            "output.$name.enable"
            "output.$name.mode.$mode"
            "output.$name.scale.$scale"
            "output.$name.rotation.$rotation"
            "output.$name.position.$pos_x,$pos_y"
        )

        if [ "$name" == "$primary_monitor" ]; then
            primary_arg="output.$name.primary"
        fi
    else
        cmd+=("output.$name.disable")
    fi
done

# Disable any currently connected outputs that aren't in the profile
for current_output in $current_outputs; do
    if [ -z "${profile_outputs[$current_output]}" ]; then
        echo "Disabling extra output not in profile: $current_output"
        cmd+=("output.$current_output.disable")
    fi
done

# Guard: never apply an all-off state
if [ "$enabled_count" -eq 0 ]; then
    echo "No enabled outputs in profile; refusing to apply an all-off state."
    exit 1
fi

# Add primary if present
if [ -n "$primary_arg" ]; then
    cmd+=("$primary_arg")
fi

# Debug: print the exact command before running
printf 'kscreen-doctor'
for a in "${cmd[@]:1}"; do printf ' %q' "$a"; done
printf '\n'

# Execute once, atomically
"${cmd[@]}"

echo "Profile $filename applied successfully"
