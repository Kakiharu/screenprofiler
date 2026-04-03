#!/bin/bash
#
# save_profile.sh - Save current display configuration as a profile
#
# Usage: save_profile.sh <profile_name> [0|1] [gui_mode]
#   0 = Save display configuration only
#   1 = Save display configuration + KDE desktop settings (default)
#

source "$(dirname "$(realpath "$0")")/common.sh"

# ============================================================================
# Variables
# ============================================================================
profile_name="$1"
save_kde_flag="$2"
gui_mode="$3"

profile_dir="$profiles_dir/$profile_name"
meta_file="$profile_dir/meta.json"

# ============================================================================
# Validate / Auto-Detect Logic
# ============================================================================

# 1. Check if this is a GUI-based overwrite of an existing profile
if [ "$gui_mode" == "1" ] && [ -f "$meta_file" ]; then
    save_kde_flag=$(grep '"save_kde":' "$meta_file" | sed 's/[^0-1]//g')
    print_info "GUI Overwrite detected. Respecting original 'save_kde'=$save_kde_flag"

# 2. Otherwise, use the explicit flag provided ($2)
elif [ -n "$save_kde_flag" ]; then
    print_info "Using explicit flag: $save_kde_flag"

# 3. Fallback: If no flag was provided at all (e.g. 'save tester'), default to 1
else
    save_kde_flag=1
    print_info "No flag provided. Defaulting to 1"
fi

# ============================================================================
# Create Profile Directory
# ============================================================================

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
echo "$metadata_content" > "$meta_file"
print_success "Saved metadata"

echo ""
print_success "Profile '$profile_name' saved successfully!"
print_header "═══════════════════════════════════════════════════════════"
