#!/bin/bash
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

# Target directory for the application files
INSTALL_DIR="$HOME/screenprofiler"

if [ ! -d "$INSTALL_DIR" ]; then
    echo "[INFO] Cloning repository into $INSTALL_DIR..."
    git clone https://github.com/Kakiharu/screenprofiler.git "$INSTALL_DIR"
else
    echo "[INFO] Repository already exists. Performing a 'Boss Mode' update..."
    cd "$INSTALL_DIR"
    # Force the local branch to match the remote exactly
    git fetch origin
    git reset --hard origin/main
fi

cd "$INSTALL_DIR" || exit 1

# ============================================================================
# 2. Permissions
# ============================================================================

echo "[INFO] Setting executable permissions on scripts..."
# Ensure all core logic and helper scripts are runnable
chmod +x screenprofilercmd.sh save_profile.sh load_profile.sh screenprofiler.py

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
# 5. Finalize
# ============================================================================

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  Screen Profiler installed successfully!"
echo "═══════════════════════════════════════════════════════════"
echo "Usage:"
echo "  • Run 'screenprofilercmd help' for command line options."
echo "  • Run 'screenprofilercmd tray' to launch the UI."
echo ""
