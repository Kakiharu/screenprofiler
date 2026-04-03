#!/bin/bash
#
# screenprofilercmd.sh - Main command-line interface for Screen Profiler
#
# Usage: screenprofilercmd <command> [arguments]
#

# ============================================================================
# Setup
# ============================================================================

# Get the directory where this script resides
script_dir="$(dirname "$(realpath "$0")")"

# Directory where profiles are stored
profiles_dir="$script_dir/profiles"

# Load common functions and variables (including version number)
if [ -f "$script_dir/common.sh" ]; then
    source "$script_dir/common.sh"
else
    SCREENPROFILER_VERSION="unknown"
fi

# ============================================================================
# Parse Command-Line Arguments
# ============================================================================

command="$1"
profile_name="$2"
flag="$3"

# ============================================================================
# Dependency Check
# ============================================================================

# Check dependencies for all commands except help and version
case $command in
    ""|help|--help|-h|version|-v|--version)
        # Don't check dependencies for informational commands
        ;;
    *)
        check_dependencies
        ;;
esac

# ============================================================================
# Command Execution
# ============================================================================

case $command in
    # ------------------------------------------------------------------------
    # Save Profile
    # ------------------------------------------------------------------------
    save)
        if [ -z "$profile_name" ]; then
            print_error "Profile name required"
            exit 1
        fi

        # Pass the name ($2), the KDE flag ($3), and the GUI flag ($4)
        "$script_dir/save_profile.sh" "$profile_name" "$flag" "$4"
        ;;

    # ------------------------------------------------------------------------
    # Load Profile
    # ------------------------------------------------------------------------
    load)
        if [ -z "$profile_name" ]; then
            print_error "Profile name required"
            echo "Usage: $0 load <profile_name>"
            exit 1
        fi

        "$script_dir/load_profile.sh" "$profile_name"
        ;;

    # ------------------------------------------------------------------------
    # Remove Profile
    # ------------------------------------------------------------------------
    remove)
        if [ -z "$profile_name" ]; then
            print_error "Profile name required"
            echo "Usage: $0 remove <profile_name>"
            exit 1
        fi

        # Delete the profile directory
        if [ -d "$profiles_dir/$profile_name" ]; then
            rm -rf "$profiles_dir/$profile_name"
            print_success "Profile '$profile_name' removed successfully"
        else
            print_error "Profile '$profile_name' not found"
            exit 1
        fi
        ;;

    # ------------------------------------------------------------------------
    # List Profiles
    # ------------------------------------------------------------------------
    list)
        print_header "Available Profiles"
        print_header "════════════════════════════════════════"
        echo ""

        # Check if profiles directory exists
        if [ ! -d "$profiles_dir" ]; then
            print_warning "No profiles directory found"
            exit 0
        fi

        # Collect and sort profile names
        profiles=$(for profile_dir in "$profiles_dir"/*; do
            [ -d "$profile_dir" ] || continue
            basename "$profile_dir"
        done | sort)

        if [ -n "$profiles" ]; then
            echo "$profiles" | sed 's/^/  • /'
        else
            print_info "No profiles saved yet"
        fi
        echo
        ;;


    # ------------------------------------------------------------------------
    # Update Screen Profiler
    # ------------------------------------------------------------------------
    update)
        update_script="$script_dir/install.sh"

        if [ -x "$update_script" ]; then
            print_info "Starting update via install.sh..."
            # Execute the installer
            bash "$update_script"
        else
            print_error "Update script (install.sh) not found or not executable at $update_script"
            exit 1
        fi
        ;;
    # ------------------------------------------------------------------------
    # Launch Tray Application / Manage Applet
    # ------------------------------------------------------------------------
    tray)
        APPLET_ID="org.kde.screenprofiler"
        APPLET_ROOT="$script_dir/org.kde.screenprofiler"

        # 1. Check if installed
        if ! kpackagetool6 --type Plasma/Applet --list | grep -q "$APPLET_ID"; then
            print_warning "Plasma Applet is not installed."
            read -p "Would you like to install the Screen Profiler tray widget? (y/n): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                kpackagetool6 --type Plasma/Applet --install "$APPLET_ROOT"
                print_success "Applet installed."
                echo -e "\n${COLOR_INFO}HOW TO ADD TO TASKBAR:${COLOR_RESET}"
                echo "1. Right-click your Taskbar > Enter 'Edit Mode'."
                echo "2. Click 'Add Widgets'."
                echo "3. Search for 'Screen Profiler' and drag it to your tray."
                restart_plasma
            fi
        else
            # 2. Handle Updates/Uninstalls
            INSTALLED_METADATA="$HOME/.local/share/plasma/plasmoids/$APPLET_ID/metadata.json"
            LOCAL_METADATA="$APPLET_ROOT/metadata.json"

            if [ -f "$LOCAL_METADATA" ] && [ -f "$INSTALLED_METADATA" ]; then
                LOCAL_VERSION=$(grep '"Version":' "$LOCAL_METADATA" | cut -d'"' -f4)
                INSTALLED_VERSION=$(grep '"Version":' "$INSTALLED_METADATA" | cut -d'"' -f4)

                if [ "$INSTALLED_VERSION" != "$LOCAL_VERSION" ]; then
                    print_warning "Version mismatch: Installed ($INSTALLED_VERSION) vs Local ($LOCAL_VERSION)"
                    read -p "Would you like to (u)pdate or (r)emove the applet? (u/r/cancel): " choice
                    case "$choice" in
                        [Uu]*)
                            kpackagetool6 --type Plasma/Applet --remove "$APPLET_ID"
                            kpackagetool6 --type Plasma/Applet --install "$APPLET_ROOT"
                            print_success "Applet updated to $LOCAL_VERSION"
                            restart_plasma
                            ;;
                        [Rr]*)
                            kpackagetool6 --type Plasma/Applet --remove "$APPLET_ID"
                            print_success "Applet removed."
                            restart_plasma
                            exit 0
                            ;;
                    esac
                else
                    print_success "Applet (v$INSTALLED_VERSION) is already up to date."
                    read -p "Would you like to uninstall it? (y/n): " confirm
                    if [[ "$confirm" =~ ^[Yy]$ ]]; then
                        kpackagetool6 --type Plasma/Applet --remove "$APPLET_ID"
                        print_success "Applet removed."
                        restart_plasma
                        exit 0
                    fi
                fi
            fi
        fi
        ;;

    # ------------------------------------------------------------------------
    # Uninstall
    # ------------------------------------------------------------------------
    uninstall)
        uninstall_script="$script_dir/uninstall.sh"

        if [ -x "$uninstall_script" ]; then
            "$uninstall_script"
        else
            print_error "Uninstall script not found at $uninstall_script"
            exit 1
        fi
        ;;

    # ------------------------------------------------------------------------
    # Version Information
    # ------------------------------------------------------------------------
    version|-v|--version)
        print_header "════════════════════════════════════════"
        echo -e "\033[0;32mScreen Profiler version $SCREENPROFILER_VERSION\033[0m"

        echo ""
        print_header "Donations welcome: \033[0;32mhttps://linktr.ee/kakiharu\033"
        print_header "════════════════════════════════════════"

        ;;

    # ------------------------------------------------------------------------
    # Help / Usage Information
    # ------------------------------------------------------------------------
    ""|help|--help|-h)
        print_header "════════════════════════════════════════"
        echo -e "\033[0;32mScreen Profiler version $SCREENPROFILER_VERSION\033[0m"
        echo ""
        print_header "Easily save and restore display configurations on KDE Plasma"
        echo ""
        print_header "Usage: $0 <command> [arguments]"
        echo ""
        print_blue "Commands:"
        print_blue "  save <name> [0|1]   Save current display configuration as a profile"
        print_blue "                      0 = monitors only, 1 = with KDE configs (default)"
        echo ""
        print_blue "  load <name>         Restore a saved profile"
        echo ""
        print_blue "  remove <name>       Delete a saved profile"
        echo ""
        print_blue "  list                List all saved profiles (alphabetically)"
        echo ""
        print_blue "  tray                Manage the system tray application"
        echo ""
        print_blue "  uninstall           Remove Screen Profiler from your system"
        echo ""
        print_blue "  update              Pull latest version and refresh applet/symlinks"
        echo ""
        print_blue "  version             Display version information"
        echo ""
        print_header "Examples:"
        print_header "  $0 save worksetup 1     # Save monitors + desktop settings"
        print_header "  $0 save gaming 0        # Save monitors only"
        print_header "  $0 load worksetup       # Restore worksetup profile"
        print_header "  $0 list                 # Show all profiles"
        echo ""
        print_header "Donations welcome: \033[0;32mhttps://linktr.ee/kakiharu\033"
        print_header "════════════════════════════════════════"

        ;;

    # ------------------------------------------------------------------------
    # Invalid Command
    # ------------------------------------------------------------------------
    *)
        print_error "Invalid command: $command"
        echo ""
        echo "Run '$0 help' for usage information"
        exit 1
        ;;
esac
