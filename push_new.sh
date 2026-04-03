#!/bin/bash
#
# push_new.sh - Interactive version bump, patchnotes updater, and git push helper
#
# Versioning scheme:
#   MAJOR (X.0.0) — Large overhaul, breaking changes, or first official release
#   MINOR (0.X.0) — New features, new commands, new UI sections
#   PATCH (0.0.X) — Bug fixes, small tweaks, minor changes
#

set -e

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
COMMON="$SCRIPT_DIR/common.sh"
METADATA="$SCRIPT_DIR/org.kde.screenprofiler/metadata.json"
PATCHNOTES="$SCRIPT_DIR/patchnotes.txt"

# ============================================================================
# Files & directories to ignore when creating the release zip
# ============================================================================
IGNORE_LIST=(
    ".git"
    "#versions"
    "#oldfiles"
    "profiles"
    ".cache"
    "*.log"
    "*.tmp"
    "push_new.sh"
    "reload.sh"
)

# ============================================================================
# Colors
# ============================================================================
RESET='\033[0m'
BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
MAGENTA='\033[1;35m'

# ============================================================================
# Read current version
# ============================================================================
CURRENT_VERSION=$(grep SCREENPROFILER_VERSION= "$COMMON" | cut -d= -f2 | tr -d '"')

if [ -z "$CURRENT_VERSION" ]; then
    echo -e "${RED}ERROR:${RESET} Could not read version from common.sh"
    exit 1
fi

IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

echo ""
echo -e "${MAGENTA}════════════════════════════════════════${RESET}"
echo -e "${MAGENTA}       Screen Profiler — New Release    ${RESET}"
echo -e "${MAGENTA}════════════════════════════════════════${RESET}"
echo ""
echo -e "Current version: ${BOLD}$CURRENT_VERSION${RESET}"
echo ""

# ============================================================================
# Choose bump type
# ============================================================================
echo -e "${CYAN}What type of release is this?${RESET}"
echo "  1) Patch  (0.0.X) — Bug fixes, minor tweaks"
echo "  2) Minor  (0.X.0) — New features or content additions"
echo "  3) Major  (X.0.0) — Large update or breaking changes"
echo ""
read -rp "Choice [1/2/3]: " BUMP_TYPE

case $BUMP_TYPE in
    1)
        PATCH=$((PATCH + 1))
        TYPE_LABEL="Patch"
        ;;
    2)
        MINOR=$((MINOR + 1))
        PATCH=0
        TYPE_LABEL="Minor"
        ;;
    3)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        TYPE_LABEL="Major"
        ;;
    *)
        echo -e "${RED}Invalid choice. Aborting.${RESET}"
        exit 1
        ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"

echo ""
echo -e "New version: ${GREEN}${BOLD}$NEW_VERSION${RESET} (${TYPE_LABEL})"
echo ""

# ============================================================================
# Release title and description
# ============================================================================
read -rp "Release title (e.g. 'Plasmoid UI overhaul'): " RELEASE_TITLE

if [ -z "$RELEASE_TITLE" ]; then
    echo -e "${RED}Title cannot be empty. Aborting.${RESET}"
    exit 1
fi

echo ""
echo -e "${CYAN}Enter release notes.${RESET} Describe what changed (one item per line)."
echo -e "Press ${BOLD}Enter twice${RESET} when done:"
echo ""

NOTES=""
BLANK_COUNT=0
while true; do
    read -r LINE
    if [ -z "$LINE" ]; then
        BLANK_COUNT=$((BLANK_COUNT + 1))
        if [ "$BLANK_COUNT" -ge 1 ]; then
            break
        fi
    else
        BLANK_COUNT=0
        NOTES="$NOTES\n- $LINE"
    fi
done

if [ -z "$NOTES" ]; then
    echo -e "${YELLOW}No notes entered — continuing with empty notes.${RESET}"
fi

# ============================================================================
# Preview
# ============================================================================
DATE=$(date +%Y-%m-%d)

echo ""
echo -e "${MAGENTA}════════════════════════════════════════${RESET}"
echo -e "${BOLD}Preview:${RESET}"
echo ""
echo -e "## [$NEW_VERSION] - $DATE — \"$RELEASE_TITLE\""
echo -e "Type: $TYPE_LABEL"
echo -e "$NOTES"
echo ""
echo -e "${MAGENTA}════════════════════════════════════════${RESET}"
echo ""
read -rp "Confirm and apply? [y/N]: " CONFIRM

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

# ============================================================================
# Update common.sh
# ============================================================================
sed -i "s/SCREENPROFILER_VERSION=\".*\"/SCREENPROFILER_VERSION=\"$NEW_VERSION\"/" "$COMMON"
echo -e "${GREEN}[OK]${RESET} Updated common.sh → $NEW_VERSION"

# ============================================================================
# Update metadata.json (if it exists)
# ============================================================================
if [ -f "$METADATA" ]; then
    sed -i "s/\"Version\": \".*\"/\"Version\": \"$NEW_VERSION\"/" "$METADATA"
    echo -e "${GREEN}[OK]${RESET} Updated metadata.json → $NEW_VERSION"
else
    echo -e "${YELLOW}[WARN]${RESET} metadata.json not found at $METADATA — skipping"
fi

# ============================================================================
# Update patchnotes.txt
# ============================================================================
ENTRY="## [$NEW_VERSION] - $DATE — \"$RELEASE_TITLE\"\nType: $TYPE_LABEL"
if [ -n "$NOTES" ]; then
    ENTRY="$ENTRY$NOTES"
fi
ENTRY="$ENTRY\n"

if [ -f "$PATCHNOTES" ]; then
    EXISTING=$(cat "$PATCHNOTES")
    printf "%b\n%s" "$ENTRY" "$EXISTING" > "$PATCHNOTES"
else
    printf "# Screen Profiler — Patch Notes\n\n%b\n" "$ENTRY" > "$PATCHNOTES"
fi
echo -e "${GREEN}[OK]${RESET} Updated patchnotes.txt"

# ============================================================================
# Create versioned zip archive in #versions/
# ============================================================================
VERSIONS_DIR="$SCRIPT_DIR/#versions"
mkdir -p "$VERSIONS_DIR"

SAFE_TITLE=$(echo "$RELEASE_TITLE" | tr ' ' '_' | tr -cd '[:alnum:]_-')
ZIP_NAME="$NEW_VERSION.$SAFE_TITLE.zip"
ZIP_PATH="$VERSIONS_DIR/$ZIP_NAME"

echo ""
echo -e "Creating archive: ${CYAN}$ZIP_NAME${RESET}"

# Build rsync exclude parameters
RSYNC_EXCLUDES=()
for item in "${IGNORE_LIST[@]}"; do
    RSYNC_EXCLUDES+=( "--exclude=$item" )
done

# Optional: show ignore list
# echo -e "${CYAN}Ignoring:${RESET}"
# printf '  - %s\n' "${IGNORE_LIST[@]}"

TMP_DIR=$(mktemp -d)
FOLDER="$(basename "$SCRIPT_DIR")"
TMP_COPY="$TMP_DIR/$FOLDER"

rsync -a \
    "${RSYNC_EXCLUDES[@]}" \
    "$SCRIPT_DIR/" "$TMP_COPY/"

cd "$TMP_DIR"
ark --batch --add-to "$ZIP_PATH" "$FOLDER" > /dev/null 2>&1

rm -rf "$TMP_DIR"

if [ -f "$ZIP_PATH" ]; then
    echo -e "${GREEN}[OK]${RESET} Archived → #versions/$ZIP_NAME"
else
    echo -e "${RED}[ERROR]${RESET} Archive failed — is ark installed?"
fi

echo ""
echo -e "${MAGENTA}════════════════════════════════════════${RESET}"
echo -e "${BOLD}Suggested git commit message:${RESET}"
echo ""
echo -e "${CYAN}  v$NEW_VERSION — $RELEASE_TITLE${RESET}"
echo ""
echo -e "${BOLD}Suggested git tag:${RESET}"
echo ""
echo -e "${CYAN}  v$NEW_VERSION${RESET}"
echo ""
echo -e "${MAGENTA}════════════════════════════════════════${RESET}"
echo ""
echo -e "Run when ready:"
echo -e "  ${BOLD}git add -A${RESET}"
echo -e "  ${BOLD}git commit -m \"v$NEW_VERSION — $RELEASE_TITLE\"${RESET}"
echo -e "  ${BOLD}git tag v$NEW_VERSION${RESET}"
echo -e "  ${BOLD}git push && git push --tags${RESET}"
echo ""
