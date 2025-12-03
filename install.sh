#!/bin/bash
set -e

echo "Installing Screen Profiler..."

# Clone repo into ~/screenprofiler if not already present
if [ ! -d "$HOME/screenprofiler" ]; then
    git clone https://github.com/Kakiharu/screenprofiler.git "$HOME/screenprofiler"
else
    else
    echo "Repo already exists at ~/screenprofiler"
    cd "$HOME/screenprofiler"
    echo "Forcing update from remote..."
    git fetch origin
    git reset --hard origin/main
fi

fi
cd "$HOME/screenprofiler" || exit 1

# Make scripts executable
chmod +x screenprofilercmd.sh save_profile.sh load_profile.sh screenprofiler.py

# Decide install target
if [ -w /usr/bin ] && [ "$(id -u)" -eq 0 ]; then
    target="/usr/bin"
    echo "Installing system-wide to $target"
else
    target="$HOME/.local/bin"
    echo "Installing to user directory $target"
    mkdir -p "$target"
fi

# Path to symlink
link_path="$target/screenprofilercmd"
new_file="$HOME/screenprofiler/screenprofilercmd.sh"

# If symlink already exists, check modification times
if [ -L "$link_path" ]; then
    current_target=$(readlink -f "$link_path")
    if [ -f "$current_target" ]; then
        current_mtime=$(stat -c %Y "$current_target")
        new_mtime=$(stat -c %Y "$new_file")
        if [ "$new_mtime" -gt "$current_mtime" ]; then
            echo "Newer version detected, replacing symlink."
            ln -sf "$new_file" "$link_path"
        else
            echo "Existing symlink is up to date."
        fi
    else
        echo "Existing symlink target missing, recreating."
        ln -sf "$new_file" "$link_path"
    fi
else
    echo "Creating new symlink."
    ln -sf "$new_file" "$link_path"
fi

echo "Screen Profiler installed!"
echo "Run 'screenprofilercmd help' for usage instructions."
echo "Run 'screenprofilercmd tray' to launch the system tray app."
