#!/bin/bash
# Re-exec with CRLF stripped if piped from curl
if [ -p /dev/stdin ]; then
    tmp=$(mktemp)
    cat > "$tmp"
    sed -i 's/\r//' "$tmp"
    bash "$tmp"
    rm -f "$tmp"
    exit
fi
#
# install.sh - Installation script for Screen Profiler
#
# This script clones/updates the repository, sets permissions,
# and creates a symlink in the user's path for easy access.
#

set -e

echo "═══════════════════════════════════════════════════════════"
echo "  Installing Screen Profiler"
echo "═══════════════════════════════════════════════════════════"

# ============================================================================
# 1. Repository Management
# ============================================================================

INSTALL_DIR="$HOME/screenprofiler"

if [ ! -d "$INSTALL_DIR" ]; then
    echo "[INFO] Cloning repository into $INSTALL_DIR..."
    git clone https://github.com/Kakiharu/screenprofiler.git "$INSTALL_DIR"
else
    # Check if it is actually a git repository
    if [ -d "$INSTALL_DIR/.git" ]; then
        echo "[INFO] Repository exists. Performing a 'Boss Mode' update..."
        cd "$INSTALL_DIR"
        git fetch origin
        git reset --hard origin/main
    else
        echo "[WARN] $INSTALL_DIR exists but is not a git repo. Reinstalling..."
        # Move profiles to a temp spot so we don't lose them!
        if [ -d "$INSTALL_DIR/profiles" ]; then
            mv "$INSTALL_DIR/profiles" "$HOME/screenprofiler_profiles_backup"
        fi

        rm -rf "$INSTALL_DIR"
        git clone https://github.com/Kakiharu/screenprofiler.git "$INSTALL_DIR"

        # Restore profiles if they were backed up
        if [ -d "$HOME/screenprofiler_profiles_backup" ]; then
            mv "$HOME/screenprofiler_profiles_backup" "$INSTALL_DIR/profiles"
            echo "[OK] Restored your existing profiles."
        fi
    fi
fi

cd "$INSTALL_DIR" || exit 1

# ============================================================================
# 2. Permissions
# ============================================================================

echo "[INFO] Setting executable permissions on scripts..."
# Ensure all core logic and helper scripts are runnable
#chmod +x screenprofilercmd.sh save_profile.sh load_profile.sh screenprofiler.py

# ============================================================================
# 3. Path Selection
# ============================================================================

# Determine where to place the 'screenprofilercmd' shortcut.
# If running as root and /usr/bin is writable, install system-wide.
if [ -w /usr/bin ] && [ "$(id -u)" -eq 0 ]; then
    target="/usr/bin"
    echo "[INFO] Target: System-wide directory ($target)"
else
    # Otherwise, install to the user's local bin (standard for most distros)
    target="$HOME/.local/bin"
    echo "[INFO] Target: User local directory ($target)"
    mkdir -p "$target"
fi

# ============================================================================
# 4. Symlink Logic (The Shortcut)
# ============================================================================

link_path="$target/screenprofilercmd"
new_file="$INSTALL_DIR/screenprofilercmd.sh"

if [ -L "$link_path" ]; then
    # Check if the existing shortcut points to something that still exists
    current_target=$(readlink -f "$link_path")

    if [ -f "$current_target" ]; then
        # Compare modification times so we don't overwrite if unnecessary
        current_mtime=$(stat -c %Y "$current_target")
        new_mtime=$(stat -c %Y "$new_file")

        if [ "$new_mtime" -gt "$current_mtime" ]; then
            echo "[UPDATE] Newer version detected. Refreshing symlink..."
            ln -sf "$new_file" "$link_path"
        else
            echo "[OK] Existing symlink is already up to date."
        fi
    else
        echo "[FIX] Broken symlink detected. Recreating..."
        ln -sf "$new_file" "$link_path"
    fi
else
    echo "[NEW] Creating 'screenprofilercmd' symlink..."
    ln -sf "$new_file" "$link_path"
fi

# ============================================================================
# 5. Plasma Applet Installation / Update (Silent Mode)
# ============================================================================

APPLET_ID="org.kde.screenprofiler"
APPLET_SRC="$INSTALL_DIR/org.kde.screenprofiler"
INSTALLED_PATH="$HOME/.local/share/plasma/plasmoids/$APPLET_ID"

if [ -d "$APPLET_SRC" ] && command -v kpackagetool6 &> /dev/null; then
    echo "[INFO] Syncing Plasma Applet..."

    # Get version from the newly downloaded files
    NEW_VERSION=$(grep '"Version":' "$APPLET_SRC/metadata.json" | cut -d'"' -f4)

    if [ -d "$INSTALLED_PATH" ]; then
        # Applet exists, check version
        CURRENT_VERSION=$(grep '"Version":' "$INSTALLED_PATH/metadata.json" | cut -d'"' -f4)

        if [ "$NEW_VERSION" != "$CURRENT_VERSION" ]; then
            echo "[UPDATE] Version change detected ($CURRENT_VERSION -> $NEW_VERSION). Force refreshing..."

            # Remove (ignore errors if already gone), Reinstall, and Kick Plasma
            kpackagetool6 --type Plasma/Applet --remove "$APPLET_ID" || true
            kpackagetool6 --type Plasma/Applet --install "$APPLET_SRC"

            if [ -f "$INSTALL_DIR/common.sh" ]; then
                source "$INSTALL_DIR/common.sh"
                restart_plasma
            fi
            echo "[SUCCESS] Applet updated to v$NEW_VERSION"
        else
            echo "[OK] Plasma Applet is already up to date (v$CURRENT_VERSION)."
        fi
    else
        # Not installed at all - Install silently
        echo "[NEW] Applet not found. Performing fresh installation..."
        kpackagetool6 --type Plasma/Applet --install "$APPLET_SRC"

        if [ -f "$INSTALL_DIR/common.sh" ]; then
            source "$INSTALL_DIR/common.sh"
            restart_plasma
        fi

        echo "[SUCCESS] Applet installed. Add it to your taskbar via 'Edit Mode'."
    fi
fi
# ============================================================================
# 6. Finalize
# ============================================================================

echo "═══════════════════════════════════════════════════════════"
echo "  Screen Profiler installed successfully!"
echo "═══════════════════════════════════════════════════════════"
echo "Usage:"
echo "  • Run 'screenprofilercmd list' to see your profiles."
echo "  • Applet installed."
echo "  --> To use: Right-click Taskbar > Edit Mode > Add Widgets > Search 'Screen Profiler'"
