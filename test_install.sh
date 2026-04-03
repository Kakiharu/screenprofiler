#!/bin/bash
#
# install_offline.sh - Offline installer for Screen Profiler
#
# Installs Screen Profiler from the folder it is currently in.
#

set -e

echo "═══════════════════════════════════════════════════════════"
echo "  Installing Screen Profiler (Offline Mode)"
echo "═══════════════════════════════════════════════════════════"

# ============================================================================
# 1. Source Directory (where this script lives)
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="$HOME/screenprofiler"

echo "[INFO] Source directory: $SCRIPT_DIR"
echo "[INFO] Install directory: $INSTALL_DIR"

# ============================================================================
# 2. Copy Files Into Place
# ============================================================================

if [ -d "$INSTALL_DIR" ]; then
    echo "[INFO] Existing installation found. Updating files..."
else
    echo "[INFO] Creating installation directory..."
    mkdir -p "$INSTALL_DIR"
fi

# Copy everything except .git and installer scripts
rsync -av --exclude='.git' --exclude='install.sh' --exclude='install_offline.sh' "$SCRIPT_DIR/" "$INSTALL_DIR/"

# ============================================================================
# 3. Permissions
# ============================================================================

echo "[INFO] Setting executable permissions..."
chmod +x "$INSTALL_DIR"/screenprofilercmd.sh \
         "$INSTALL_DIR"/save_profile.sh \
         "$INSTALL_DIR"/load_profile.sh \
         #"$INSTALL_DIR"/screenprofiler.py

# ============================================================================
# 4. Symlink Logic
# ============================================================================

if [ -w /usr/bin ] && [ "$(id -u)" -eq 0 ]; then
    target="/usr/bin"
    echo "[INFO] Installing system-wide symlink..."
else
    target="$HOME/.local/bin"
    echo "[INFO] Installing user-local symlink..."
    mkdir -p "$target"
fi

link_path="$target/screenprofilercmd"
new_file="$INSTALL_DIR/screenprofilercmd.sh"

echo "[INFO] Creating/updating symlink at $link_path"
ln -sf "$new_file" "$link_path"

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
