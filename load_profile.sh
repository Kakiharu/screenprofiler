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

# Apply monitor layout
outputs=$(echo "$profile" | jq -c '.outputs[]')
for output in $outputs; do
    name=$(echo "$output" | jq -r '.name')
    enabled=$(echo "$output" | jq -r '.enabled')
    if [ "$enabled" == "true" ]; then
        mode=$(echo "$output" | jq -r '.currentModeId')
        scale=$(echo "$output" | jq -r '.scale')
        rotation=$(map_orientation "$(echo "$output" | jq -r '.rotation')")
        pos_x=$(echo "$output" | jq -r '.pos.x')
        pos_y=$(echo "$output" | jq -r '.pos.y')
        kscreen-doctor output."$name".enable output."$name".mode."$mode" \
                       output."$name".scale."$scale" output."$name".rotation."$rotation" \
                       output."$name".position."$pos_x","$pos_y"
        if [ "$name" == "$primary_monitor" ]; then
            primary_output="output.$name.primary"
        fi
    else
        kscreen-doctor output."$name".disable
    fi
done

if [ ! -z "$primary_output" ]; then
    kscreen-doctor "$primary_output"
fi

echo "Profile $filename applied successfully"
