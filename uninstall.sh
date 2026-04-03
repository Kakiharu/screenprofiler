#!/bin/bash
# uninstall.sh - Removes Screen Profiler but preserves user profiles.

set -e

# Load common functions if available for styling/restarting plasma
script_dir="$(dirname "$(realpath "$0")")"
if [ -f "$script_dir/common.sh" ]; then
    source "$script_dir/common.sh"
fi

echo "═══════════════════════════════════════════════════════════"
echo "  Uninstalling Screen Profiler"
echo "═══════════════════════════════════════════════════════════"

# 1. Remove the Plasma Applet
APPLET_ID="org.kde.screenprofiler"
if command -v kpackagetool6 &> /dev/null; then
    if kpackagetool6 --type Plasma/Applet --list | grep -q "$APPLET_ID"; then
        echo "[INFO] Removing Plasma Applet..."
        kpackagetool6 --type Plasma/Applet --remove "$APPLET_ID"

        # Restart plasma to clear the ghost icon from the tray
        if command -v restart_plasma &> /dev/null; then
            restart_plasma
        fi
    fi
fi

# 2. Remove the Symlink
install_path=$(command -v screenprofilercmd || true)
if [ -n "$install_path" ] && [ -L "$install_path" ]; then
    rm "$install_path"
    echo "[OK] Removed symlink at $install_path"
fi

# 3. Clean up application files (PRESERVING PROFILES)
INSTALL_DIR="$HOME/screenprofiler"
if [ -d "$INSTALL_DIR" ]; then
    echo "[INFO] Cleaning up application files in $INSTALL_DIR..."

    # Delete everything EXCEPT the profiles folder and the folder itself
    # This finds all items in the dir, excludes 'profiles', and removes them
    find "$INSTALL_DIR" -maxdepth 1 ! -name "profiles" ! -name "screenprofiler" -exec rm -rf {} +

    echo "[OK] Application files removed. Your 'profiles' folder has been kept."
fi

echo "═══════════════════════════════════════════════════════════"
echo "  Uninstallation Complete."
echo "═══════════════════════════════════════════════════════════"
