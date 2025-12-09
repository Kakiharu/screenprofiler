#!/bin/bash
#
# load_profile.sh - Restore a saved display profile
#
# Usage: load_profile.sh <profile_name>
#

source "$(dirname "$(realpath "$0")")/common.sh"

# ============================================================================
# Variables
# ============================================================================

profile_name="$1"
profile_path="$profiles_dir/$profile_name/display.json"
meta_path="$profiles_dir/$profile_name/meta.json"

# ============================================================================
# Validation
# ============================================================================

if [ ! -f "$profile_path" ]; then
    print_error "Profile not found: $profile_name"
    exit 1
fi

print_header "═══════════════════════════════════════════════════════════"
print_header "Loading Profile: $profile_name"
print_header "═══════════════════════════════════════════════════════════"
echo

# ============================================================================
# Load Profile Data
# ============================================================================

profile=$(cat "$profile_path")

# Read primary monitor from metadata
primary_monitor=""
if [ -f "$meta_path" ]; then
    primary_monitor=$(jq -r '.primaryMonitor' "$meta_path")
fi

# ============================================================================
# Restore KDE Configuration Files
# ============================================================================

print_info "Restoring KDE configuration files..."

# Define KDE config files to restore
declare -A kde_files=(
    ["plasma-org.kde.plasma.desktop-appletsrc"]="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
    ["kwinrc"]="$HOME/.config/kwinrc"
    ["kdeglobals"]="$HOME/.config/kdeglobals"
    ["plasmarc"]="$HOME/.config/plasmarc"
    ["kscreenlockerrc"]="$HOME/.config/kscreenlockerrc"
)

# Copy each saved KDE config file if it exists in the profile
restored_count=0
for config_name in "${!kde_files[@]}"; do
    source_file="$profiles_dir/$profile_name/$config_name"
    dest_file="${kde_files[$config_name]}"

    if [ -f "$source_file" ]; then
        cp "$source_file" "$dest_file"
        print_success "Restored $config_name"
        ((restored_count++))
    fi
done

if [ "$restored_count" -eq 0 ]; then
    print_info "No KDE config files to restore"
fi
echo

# Restart Plasma to apply KDE config changes
restart_plasma

# ============================================================================
# Prepare Display Configuration
# ============================================================================

# Get currently connected outputs
current_outputs=$(kscreen-console json | sed -n '/^{/,$p' | jq -r '.outputs[].name')

# Build hash map of outputs defined in the profile
declare -A profile_outputs
outputs=$(echo "$profile" | jq -c '.outputs[]')
for output in $outputs; do
    output_name=$(echo "$output" | jq -r '.name')
    profile_outputs["$output_name"]=1
done

# ============================================================================
# Build Display Configuration Command
# ============================================================================

# Initialize kscreen-doctor command array
cmd=(kscreen-doctor)
primary_arg=""
enabled_count=0

# Configure each output defined in the profile
for output in $outputs; do
    # Extract output properties
    name=$(echo "$output" | jq -r '.name')
    enabled=$(echo "$output" | jq -r '.enabled')

    if [ "$enabled" == "true" ]; then
        ((enabled_count++))

        # Get display settings
        mode=$(echo "$output" | jq -r '.currentModeId')
        scale=$(echo "$output" | jq -r '.scale')
        rotation=$(map_orientation "$(echo "$output" | jq -r '.rotation')")
        pos_x=$(echo "$output" | jq -r '.pos.x')
        pos_y=$(echo "$output" | jq -r '.pos.y')

        # Add configuration commands for this output
        cmd+=(
            "output.$name.enable"
            "output.$name.mode.$mode"
            "output.$name.scale.$scale"
            "output.$name.rotation.$rotation"
            "output.$name.position.$pos_x,$pos_y"
        )

        # Mark as primary if this is the primary monitor
        if [ "$name" == "$primary_monitor" ]; then
            primary_arg="output.$name.primary"
        fi
    else
        # Disable this output
        cmd+=("output.$name.disable")
    fi
done

# Disable any currently connected outputs not in the profile
for current_output in $current_outputs; do
    if [ -z "${profile_outputs[$current_output]}" ]; then
        print_warning "Disabling extra output not in profile: $current_output"
        cmd+=("output.$current_output.disable")
    fi
done

# ============================================================================
# Safety Check
# ============================================================================

# Never apply a configuration with all outputs disabled
if [ "$enabled_count" -eq 0 ]; then
    print_error "No enabled outputs in profile"
    print_error "Refusing to apply an all-off state"
    exit 1
fi

# ============================================================================
# Apply Configuration
# ============================================================================

print_info "Applying display configuration..."
echo

# Add primary monitor designation if present
if [ -n "$primary_arg" ]; then
    cmd+=("$primary_arg")
fi

# Display the command that will be executed
print_command "Executing kscreen-doctor command:"
printf "${COLOR_COMMAND}"
printf 'kscreen-doctor'
for arg in "${cmd[@]:1}"; do
    printf ' %q' "$arg"
done
printf "${COLOR_RESET}\n"
echo

# Execute the configuration command atomically
"${cmd[@]}"

echo
print_success "Profile '$profile_name' applied successfully"
print_header "═══════════════════════════════════════════════════════════"
