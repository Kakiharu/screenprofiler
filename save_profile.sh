#!/bin/bash
#
# save_profile.sh - Save current display configuration as a profile
#
# Usage: save_profile.sh <profile_name> [0|1]
#   0 = Save display configuration only
#   1 = Save display configuration + KDE desktop settings (default)
#

source "$(dirname "$(realpath "$0")")/common.sh"

# ============================================================================
# Variables
# ============================================================================

profile_name="$1"
save_kde_flag="$2"

# ============================================================================
# Validate Save Flag
# ============================================================================

if [ -z "$save_kde_flag" ]; then
    # Default to saving KDE configs
    save_kde_flag=1

    echo "No flag provided. Defaulting to saving KDE configs."
    echo ""
    echo "These files control important parts of your desktop:"
    echo "  • plasma-org.kde.plasma.desktop-appletsrc → Panels, widgets, and their arrangement"
    echo "  • kwinrc → Window manager settings (tiling, borders, effects)"
    echo "  • kdeglobals → Global appearance (colors, fonts, styles)"
    echo "  • plasmarc → Plasma shell preferences (general behavior)"
    echo "  • kscreenlockerrc → Screen locker settings (lock screen behavior)"
    echo ""
    echo "Together, these files restore your desktop's look, feel, and layout."

elif [ "$save_kde_flag" != "0" ] && [ "$save_kde_flag" != "1" ]; then
    echo "ERROR: Invalid flag: $save_kde_flag"
    echo "Usage: save_profile.sh <name> [0|1]"
    echo "  0 = Save display configuration only"
    echo "  1 = Save display + KDE desktop settings"
    exit 1
fi

# ============================================================================
# Create Profile Directory
# ============================================================================

profile_dir="$profiles_dir/$profile_name"
mkdir -p "$profile_dir"

# ============================================================================
# Save Display Configuration
# ============================================================================

print_info "Capturing current display configuration..."

# Capture current display configuration from KScreen
current_config=$(kscreen-console json | sed -n '/^{/,$p')

# Identify the primary monitor
primary_monitor=$(xrandr --query | grep "primary" | awk '{print $1}')

# Save display configuration to JSON file
echo "$current_config" > "$profile_dir/display.json"
print_success "Saved display config to display.json"
echo

# ============================================================================
# Save KDE Configuration Files (Optional)
# ============================================================================

if [ "$save_kde_flag" == "1" ]; then
    print_info "Saving KDE desktop configuration files..."

    # Define KDE config files to save
    declare -A kde_files=(
        ["plasma-org.kde.plasma.desktop-appletsrc"]="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
        ["kwinrc"]="$HOME/.config/kwinrc"
        ["kdeglobals"]="$HOME/.config/kdeglobals"
        ["plasmarc"]="$HOME/.config/plasmarc"
        ["kscreenlockerrc"]="$HOME/.config/kscreenlockerrc"
    )

    # Copy each KDE config file if it exists
    saved_count=0
    for config_name in "${!kde_files[@]}"; do
        source_file="${kde_files[$config_name]}"

        if [ -f "$source_file" ]; then
            cp "$source_file" "$profile_dir/$config_name"
            print_success "Saved $config_name"
            ((saved_count++))
        fi
    done

    if [ "$saved_count" -eq 0 ]; then
        print_warning "No KDE config files found to save"
    fi
else
    print_info "Skipping KDE configs (flag=0)"
fi
echo

# ============================================================================
# Save Profile Metadata
# ============================================================================

print_info "Saving profile metadata..."

# Create metadata file with save flag and primary monitor info
metadata_content="{ \"save_kde\": $save_kde_flag, \"primaryMonitor\": \"$primary_monitor\" }"
echo "$metadata_content" > "$profile_dir/meta.json"
print_success "Saved metadata"

echo ""
print_success "Profile '$profile_name' saved successfully!"
print_header "═══════════════════════════════════════════════════════════"
