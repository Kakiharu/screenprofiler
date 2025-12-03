#!/bin/bash
set -e

echo "Uninstalling Screen Profiler..."

install_path=$(command -v screenprofilercmd || true)

if [ -z "$install_path" ]; then
    echo "No screenprofilercmd found in PATH."
    exit 0
fi

if [ -L "$install_path" ]; then
    rm "$install_path"
    echo "Removed symlink at $install_path"
else
    echo "Found screenprofilercmd at $install_path, but it is not a symlink."
    echo "Not removing to avoid deleting a real file."
fi

echo "Screen Profiler uninstalled."

