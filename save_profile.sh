#!/bin/bash
source "$(dirname "$(realpath "$0")")/common.sh"

filename="$1"
save_kde="$2"

# Validate flag
if [ -z "$save_kde" ]; then
    save_kde=1
    echo "No flag provided. Defaulting to saving KDE configs."
    echo "These files control important parts of your desktop:"
    echo "  • plasma-org.kde.plasma.desktop-appletsrc → Panels, widgets, and their arrangement"
    echo "  • kwinrc → Window manager settings (tiling, borders, effects)"
    echo "  • kdeglobals → Global appearance (colors, fonts, styles)"
    echo "  • plasmarc → Plasma shell preferences (general behavior)"
    echo "  • kscreenlockerrc → Screen locker settings (lock screen behavior)"
    echo "Together, these files restore your desktop’s look, feel, and layout."
elif [ "$save_kde" != "0" ] && [ "$save_kde" != "1" ]; then
    echo "Invalid flag: $save_kde"
    echo "Usage: save_profile.sh <name> [0|1]"
    exit 1
fi

mkdir -p "$profiles_dir/$filename"

# Capture display config
current_config=$(kscreen-console json | sed -n '/^{/,$p')
primary_monitor=$(xrandr --query | grep "primary" | awk '{print $1}')

echo "$current_config" > "$profiles_dir/$filename/display.json"
echo "Saved display config to $profiles_dir/$filename/display.json"

# Save KDE configs if flag=1
if [ "$save_kde" == "1" ]; then
    declare -A kde_files=(
      ["plasma-org.kde.plasma.desktop-appletsrc"]="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
      ["kwinrc"]="$HOME/.config/kwinrc"
      ["kdeglobals"]="$HOME/.config/kdeglobals"
      ["plasmarc"]="$HOME/.config/plasmarc"
      ["kscreenlockerrc"]="$HOME/.config/kscreenlockerrc"
    )

    for name in "${!kde_files[@]}"; do
      src="${kde_files[$name]}"
      if [ -f "$src" ]; then
        cp "$src" "$profiles_dir/$filename/$name"
        echo "Saved $name"
      fi
    done
else
    echo "Skipped saving KDE configs (flag=0)"
fi

# Write metadata (save_kde + primary monitor)
echo "{ \"save_kde\": $save_kde, \"primaryMonitor\": \"$primary_monitor\" }" > "$profiles_dir/$filename/meta.json"
